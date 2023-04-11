module suimelt::amm_pair {
    use suimelt::amm_implements::{Self,Global,Pool};
    use suimelt::linear_curve;
    use suimelt::exp_curve;
    use suimelt::xyk_curve;
    use sui::pay;
    use sui::coin::{Self,Coin};
    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,ID};
    use std::vector;
    use suimelt::err_code;
    use suimelt::amm_pair_event;
    use sui::transfer;


    const MIN_PRICE: u64=10000;

    public entry fun swap_token_nft_use_muti_coins<CoinType,Item: key+store>(
        global: &Global,
        pool: &mut Pool<CoinType,Item>,
        nft_ids: vector<ID>,
        max_expected_input: u64,
        muti_coins: vector<Coin<CoinType>>,
        ctx: &mut TxContext
    ){

        let paid = vector::pop_back(&mut muti_coins);
        pay::join_vec<CoinType>(&mut paid, muti_coins);
        assert!(coin::value(&paid)>=max_expected_input,err_code::err_input_amount_insufficient());
        swap_token_nft(global,pool,nft_ids,max_expected_input,&mut paid,ctx);
        transfer::public_transfer(paid, tx_context::sender(ctx))
    }




    //use token swap item
    public entry fun swap_token_nft<CoinType,Item: key+store>(
        global: &Global,
        pool: &mut Pool<CoinType,Item>,
        nft_ids: vector<ID>,
        max_expected_input: u64,
        coin_in: &mut Coin<CoinType>,
        ctx: &mut TxContext,
     ){
        //judge pool type
        let buy_nft_number=vector::length(&nft_ids);

        assert!(coin::value(coin_in)>=max_expected_input, err_code::err_input_token_insufficient());
        //assert!(buy_nft_number>=amm_implements::get_pool_nft_number(pool),err_code::err_pool_nft_insufficient());
        //pool_type==0 represent that there are only tokens in the pool
        assert!(amm_implements::get_pool_type(pool)!=0,err_code::err_pool_type());
        
        let (calc_protocol_fee, calc_input_amount)=calc_buyinfo_update_pool_params(
            global,
            pool,
            buy_nft_number,
            max_expected_input,
        );
        
        pull_token_input_and_pay_protocol_fee(
            global,
            pool,
            calc_input_amount,
            calc_protocol_fee,
            coin_in,
            ctx
        );
        amm_implements::withdraw_nft_and_transfer_receiver(
            pool,
            nft_ids,
            tx_context::sender(ctx),
            ctx
        );
        amm_pair_event::swap_token_nft_event(object::id(pool),nft_ids,max_expected_input,tx_context::sender(ctx));
        
     }


     public entry fun swap_token_nft_one<CoinType,Item: key+store>(
        global: &Global,
        pool: &mut Pool<CoinType,Item>,
        nft_id: ID,
        max_expected_input: u64,
        coin_in: &mut Coin<CoinType>,
        ctx: &mut TxContext,
     ){

        let (calc_protocol_fee, calc_input_amount)=calc_buyinfo_update_pool_params(
            global,
            pool,
            1,
            max_expected_input,
        );

         pull_token_input_and_pay_protocol_fee(
            global,
            pool,
            calc_input_amount,
            calc_protocol_fee,
            coin_in,
            ctx
        );
        
        amm_implements::withdraw_nft_and_transfer_one_receiver(
            pool,
            nft_id,
            tx_context::sender(ctx),
            ctx
        );
        
        
     }


    //use nft swap token
     public entry fun swap_nft_token<CoinType,Item:key+store>(
        global: &Global,
        pool: &mut Pool<CoinType,Item>,
        nftids: vector<Item>,
        minExpectedTokenOutput: u64,
        ctx: &mut TxContext
    ){
        let length=vector::length(&nftids);

        let global_receiver=amm_implements::get_global_receiver(global);

        assert!(amm_implements::get_pool_funds(pool)>=minExpectedTokenOutput,err_code::err_pool_token_insufficient());
    
        assert!(amm_implements::get_pool_type(pool)!=1,err_code::err_pool_type());

        let (calc_protocol_fee,output_amount)=calc_sellinfo_and_update_pool_params(
            global,
            pool,
            length,
            minExpectedTokenOutput,
        );
      
        let total_coins=amm_implements::swap_pool_funds(pool,calc_protocol_fee+output_amount,ctx);

        pay::split_and_transfer(&mut total_coins,output_amount,tx_context::sender(ctx),ctx);
        pay::split_and_transfer(&mut total_coins,calc_protocol_fee,global_receiver,ctx);
        
        let ids=amm_implements::add_muti_nft(pool,nftids);

        amm_pair_event::swap_nft_token_event(object::id(pool),ids,minExpectedTokenOutput,tx_context::sender(ctx));

        coin::destroy_zero(total_coins);

    }


    public fun calc_buyinfo_update_pool_params<CoinType,Item: key+store>(
        global: &Global,
        pool: &mut Pool<CoinType,Item>,
        item_num: u64,
        max_expected_token_input: u64,
    ):(u64, u64){
        
        let current_spot_price= amm_implements::get_pool_spot_price(pool);
        let current_delta=amm_implements::get_pool_delta(pool);
        let fee=amm_implements::get_pool_fee(pool);
        let protocol_fee=amm_implements::get_global_fee(global);
         
        
        let pool_algo_type=amm_implements::get_pool_algorithm_type(pool);

        let (new_spot_price,new_delta,input_amount,calc_protocol_fee)=if(pool_algo_type==0){
            linear_curve::get_buy_info(
                current_spot_price,
                current_delta,
                item_num,
                fee,
                protocol_fee
            )
        }else if (pool_algo_type==1){
            exp_curve::get_buy_info( current_spot_price,
                current_delta,
                item_num,
                fee,
                protocol_fee
            )
        }else {
            xyk_curve::get_buy_info(current_spot_price,
                current_delta,
                item_num,
                fee,
                protocol_fee
            )
        };
        assert!(input_amount<=max_expected_token_input, err_code::err_input_too_litter());
        if (current_spot_price!=new_spot_price || current_delta!=new_delta){
            amm_implements::setting_pool_spot_price(pool,new_spot_price);
            amm_implements::setting_pool_delta(pool,new_delta);
        };

        (calc_protocol_fee, input_amount)
    }

  

    public fun pull_token_input_and_pay_protocol_fee<CoinType,Item: key+store>(
      global: &Global,
      pool: &mut Pool<CoinType,Item>,
      input_amount: u64,
      protocol_fee: u64,
      coin_in: &mut Coin<CoinType>,
      ctx: &mut TxContext,
    ){
        assert!(coin::value(coin_in)>=input_amount,err_code::err_input_amount_insufficient());

        let global_receiver=amm_implements::get_global_receiver(global);

        let pool_coin=coin::split(coin_in,input_amount-protocol_fee,ctx);
        amm_implements::put_pool_funds(pool,pool_coin);
        pay::split_and_transfer(coin_in,protocol_fee,global_receiver,ctx);
    }

    
     public fun calc_sellinfo_and_update_pool_params<CoinType,Item:key+store>(
        global: &Global,
        pool: &mut Pool<CoinType,Item>,
        nft_number: u64,
        minExpectedTokenOutput: u64,
     ):(u64,u64){

        let current_spot_price= amm_implements::get_pool_spot_price(pool);
        let current_delta=amm_implements::get_pool_delta(pool);
        let fee=amm_implements::get_pool_fee(pool);
        let protocol_fee=amm_implements::get_global_fee(global);

        let pool_algo_type=amm_implements::get_pool_algorithm_type(pool);

        let (new_spot_price,new_delta,output_amount,calc_protocol_fee)=if (pool_algo_type==0){
            linear_curve::get_sell_info(
                current_spot_price,
                current_delta,
                nft_number,
                fee,
                protocol_fee
                )

        }else if(pool_algo_type==1){
            exp_curve::get_sell_info(
                current_spot_price,
                current_delta,
                nft_number,
                fee,
                protocol_fee
            )


        }else{
            xyk_curve::get_sell_info(
                current_spot_price,
                current_delta,
                nft_number,
                fee,
                protocol_fee
            )
        };
        assert!(output_amount>=minExpectedTokenOutput,err_code::err_pool_token_insufficient());
         if (current_spot_price!=new_spot_price || current_delta!=new_delta){
            amm_implements::setting_pool_spot_price(pool,new_spot_price);
            amm_implements::setting_pool_delta(pool,new_delta);
        };


        ( calc_protocol_fee,output_amount)

     }

}

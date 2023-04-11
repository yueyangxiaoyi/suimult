module suimelt::amm_implements {
    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,ID,UID};
    use sui::object_bag::{Self,ObjectBag};
    use sui::balance::{Self,Balance};
    use sui::coin::{Self,Coin};
    use sui::transfer;
    use std::string::{Self, String};
    use std::type_name::{get, into_string};
    use sui::vec_set;
    use std::vector;
    use suimelt::err_code;
    use sui::dynamic_object_field;
    friend suimelt::amm_pair;
    use suimelt::amm_implements_event;

    const MIN_START_PRICE: u64=10000;
    
    struct Global has key {
        id: UID,
        has_paused: bool,
        protocol_fee: u64,
        collection: ObjectBag,
        receiver: address,
    }  


    struct Collection<phantom Item: key+store> has key,store{
        id: UID,
        global_id: ID,
        pools: vec_set::VecSet<ID>,
    }


    struct Pool<phantom CoinType,phantom Item: key+store> has key,store{
        id: UID,
        collection_type: String,
        coin: Balance<CoinType>,
        coin_fee: u64,
        spot_price: u64,
        delta: u64,
        // 0 linear 1 exp 2 x*y
        algorithm_type: u8,
        receiver: address,

        //0. Coin 1.  NFT  2. Trade(Coin,NFT) 
        pool_type: u8,
    
    }

     fun init(ctx :&mut TxContext){

            let global=Global{
                id: object::new(ctx),
                has_paused: false,
                protocol_fee: 1,
                collection: object_bag::new(ctx),
                receiver: tx_context::sender(ctx),
            };
            //amm_implements_event::global_create_event(object::id(&global),tx_context::sender(ctx),1);
            transfer::share_object(global);
    }


    public(friend) fun register_collection<CoinType, Item: key+store>(
        global: &mut Global,
        ctx: &mut TxContext,
    ) {
        let lp_name = generate_collection_name<Item>();
        //contains_with_type
        let has_registered = object_bag::contains_with_type<String, Collection<Item>>(&global.collection, lp_name);
        assert!(!has_registered, err_code::err_collection_already_register());

        let new_collection= Collection<Item>{
            id: object::new(ctx),
            global_id: object::id(global),
            pools: vec_set::empty<ID>(),
        };
        //amm_implements_event::collection_created_event(lp_name);
        object_bag::add(&mut global.collection, lp_name, new_collection);
    }



    // public entry fun create_coin_pool_muti_coins<CoinType,Item: key+store>(
        
    // )
    public entry fun create_new_coin_pool<CoinType,Item: key+store>(
        global: &mut Global,
        coin_in: Coin<CoinType>,
        fee: u64,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        ctx: &mut TxContext,
    ){
        assert!(spot_price > MIN_START_PRICE,err_code::err_input_start_price());
        let lp_name = generate_collection_name<Item>();
        let has_registered = object_bag::contains_with_type<String, Collection<Item>>(&global.collection, lp_name);

        if (!has_registered){
           let new_collection= Collection<Item>{
                id: object::new(ctx),
                global_id: object::id(global),
                pools: vec_set::empty<ID>(),
            };
            //amm_implements_event::collection_created_event(lp_name);
            object_bag::add(&mut global.collection, lp_name, new_collection);
        };
        let collection_mut=object_bag::borrow_mut(&mut global.collection,lp_name);
        create_coin_pool<CoinType,Item>(
            collection_mut,
            coin_in,
            fee,
            algorithm_type,
            spot_price,
            delta,
            ctx
        )
    }

    fun create_coin_pool<CoinType,Item: key+store>(
        collection: &mut Collection<Item>,
        coin_in: Coin<CoinType>,
        fee: u64,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        ctx: &mut TxContext,
    ){
        assert!(spot_price > MIN_START_PRICE,err_code::err_input_start_price());
        let lp_name = generate_collection_name<Item>();
        let pool= Pool<CoinType,Item>{
            id: object::new(ctx),
            collection_type: lp_name,
            coin: balance::zero<CoinType>(),
            coin_fee: fee,
            spot_price,
            delta,
            algorithm_type,
            receiver: tx_context::sender(ctx),
            pool_type: 0,
        };
        //let i = 0;

        coin::put(&mut pool.coin,coin_in);
        let pool_id=object::id(&pool);

        
         vec_set::insert<ID>(&mut collection.pools,pool_id);
        //dynamic_object_field::add(&mut collection.id,pool_id,pool);
        transfer::share_object(pool);
    }

    public entry fun create_new_nft_pool<CoinType,Item: key+store>(
        global: &mut Global,
        items: vector<Item>,
        fee: u64,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        ctx: &mut TxContext,
    ){
        assert!(spot_price > MIN_START_PRICE,err_code::err_input_start_price());
       let lp_name = generate_collection_name<Item>();
        let has_registered = object_bag::contains_with_type<String, Collection<Item>>(&global.collection, lp_name);

        if (!has_registered){
             let new_collection= Collection<Item>{
                id: object::new(ctx),
                global_id: object::id(global),
                pools: vec_set::empty<ID>(),
            };
           // amm_implements_event::collection_created_event(lp_name);
            object_bag::add(&mut global.collection, lp_name, new_collection);
        };
        let collection_mut=object_bag::borrow_mut(&mut global.collection,lp_name);
        create_nft_pool<CoinType,Item>(
            collection_mut,
            items,
            fee,
            algorithm_type,
            spot_price,
            delta,
            ctx
        )

    }

    fun create_nft_pool<CoinType,Item: key+store>(
        collection: &mut Collection<Item>,
        items: vector<Item>,
        fee: u64,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        ctx: &mut TxContext,
    ){

        let item_number=vector::length(&items);
        let lp_name = generate_collection_name<Item>();
        
        let pool= Pool<CoinType,Item>{
            id: object::new(ctx),
            collection_type: lp_name,
            coin: balance::zero<CoinType>(),
            coin_fee: fee,
            spot_price,
            delta,
            algorithm_type,
            receiver: tx_context::sender(ctx),
            pool_type:1,
        };
        
        let i = 0;
        let ids=vector::empty<ID>();
        while (i < item_number) {
            let nft = vector::pop_back(&mut items);
            let nft_id = object::id(&nft);
            vector::push_back(&mut ids, nft_id);
            // object_table::add(&mut pool.item, nft_id, nft);
            dynamic_object_field::add(&mut pool.id,nft_id,nft);
            i = i + 1;
        };
        // amm_implements_event::pool_nft_created_event(
        //     lp_name,
        //     object::id(&pool),
        //     ids,
        //     1,
        //     algorithm_type,
        //     spot_price,
        //     delta,
        //     fee
        // );
        let pool_id=object::id(&pool);

        vec_set::insert<ID>(&mut collection.pools,pool_id);
        //dynamic_object_field::add(&mut collection.id,pool_id,pool);
        transfer::share_object(pool);
        vector::destroy_empty(items);
    }



    public entry fun create_new_pool<CoinType,Item: key+store>(
        global: &mut Global,
        items: vector<Item>,
        coin_in: Coin<CoinType>,
        fee: u64,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        ctx: &mut TxContext,
    ){

       
       let lp_name = generate_collection_name<Item>();
        let has_registered = object_bag::contains_with_type<String, Collection<Item>>(&global.collection, lp_name);

        if (!has_registered){
            let new_collection= Collection<Item>{
                id: object::new(ctx),
                global_id: object::id(global),
                 pools: vec_set::empty<ID>(),
            };
            object_bag::add(&mut global.collection, lp_name, new_collection);
        };
        let collection_mut=object_bag::borrow_mut(&mut global.collection,lp_name);
        
        create_pool(
            collection_mut,
            items,
            coin_in,
            fee,
            algorithm_type,
            spot_price,
            delta,
            ctx
        )
    }



     fun create_pool<CoinType,Item: key+store>(
        collection: &mut Collection<Item>,
        items: vector<Item>,
        coin_in: Coin<CoinType>,
        fee: u64,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        ctx: &mut TxContext,
    ){

        let item_number=vector::length(&items);
        let coin_number=coin::value(&coin_in);
        assert!(coin_number>0,err_code::err_amount_is_zero());
        assert!(item_number>0,err_code::err_nft_number_is_zero());
        let lp_name = generate_collection_name<Item>();
        
        let pool= Pool<CoinType,Item>{
            id: object::new(ctx),
            collection_type: lp_name,
            coin: balance::zero<CoinType>(),
            coin_fee: fee,
            spot_price,
            delta,
            algorithm_type,
            receiver: tx_context::sender(ctx),
            pool_type:2,
        };

        

        let i = 0;
        let nft_ids=vector::empty<ID>();
        while (i < item_number) {
            let nft = vector::pop_back(&mut items);
            let nft_id = object::id(&nft);
            vector::push_back(&mut nft_ids, nft_id);
            dynamic_object_field::add(&mut pool.id,nft_id,nft);
            //object_table::add(&mut pool.item, nft_id, nft);
            i = i + 1;
        };
        
       
        let pool_id=object::id(&pool);

        //  amm_implements_event::pool_trade_created_event(
        //     lp_name,
        //     pool_id,
        //     coin::value(&coin_in),
        //     nft_ids,
        //     pool_type,
        //     algorithm_type,
        //     spot_price,
        //     delta,
        //     fee
        // );
         coin::put(&mut pool.coin,coin_in);

        //dynamic_object_field::add(&mut collection.id,pool_id,pool);
        vec_set::insert<ID>(&mut collection.pools,pool_id);
        transfer::share_object(pool);
        vector::destroy_empty(items);
    }

     public entry fun destory_pool<CoinType,Item: key+store>(  
        global: &mut Global,
        pool: &mut Pool<CoinType,Item>,
        item_ids: vector<ID>,
        receiver: address,
        ctx: &mut TxContext){
            assert!(get_pool_receiver(pool)==tx_context::sender(ctx),err_code::not_auth_operator());

            if (get_pool_funds(pool)>0){
                let get_coins=withdraw_pool_funds(pool,ctx);
                transfer::public_transfer(get_coins,receiver);
            };
             let item_num=vector::length(&item_ids);


            //if (get_pool_nft_number(pool)>=item_num){
            let i=0;
            while (i < item_num) {
                let nft_id=vector::pop_back(&mut item_ids);
                let nft=dynamic_object_field::remove(&mut pool.id,nft_id);
                transfer::public_transfer<Item>(nft,receiver);
                    //vector::push_back(&mut nft_collection,nft);
                i=i+1;
            }; 
             //};

            let lp_name = generate_collection_name<Item>();
            let collection_mut=object_bag::borrow_mut<String, Collection<Item>>(&mut global.collection,lp_name);
            vec_set::remove<ID>(&mut collection_mut.pools,&object::id(pool));
    }

    public entry fun add_nft_to_pool<CoinType,Item: key+store>(
         pool: &mut Pool<CoinType,Item>,
         items: vector<Item>,
         ctx: &mut TxContext
    ){

          //let ids = vector::empty<ID>();
          assert!(pool.receiver==tx_context::sender(ctx),err_code::not_auth_operator());

          let i=0;
          let nft_length=vector::length(&items);
          while (i < nft_length) {
            let item = vector::pop_back(&mut items);
            let nft_id = object::id(&item);
            //vector::push_back(&mut ids, nft_id);
            dynamic_object_field::add(&mut pool.id,nft_id,item);
            //object_table::add(&mut sales.nfts, nft_id, item);
            i=i+1;
        };
        //amm_implements_event::item_add_pool_event(object::id(pool),ids);
        vector::destroy_empty(items);
        
    }


    public entry fun add_coin_to_pool<CoinType,Item: key+store>(
         pool: &mut Pool<CoinType,Item>,
         coin_in: Coin<CoinType>,
         ctx: &mut TxContext
    ){
        assert!(pool.receiver==tx_context::sender(ctx),err_code::not_auth_operator());
        
         coin::put(&mut pool.coin,coin_in);
    }

    //public entry fun split_and_transfer<T>(
      //  c: &mut Coin<T>, amount: u64, recipient: address, ctx: &mut TxContext

    public entry fun remove_coin_from_pool<CoinType,Item: key+store>(
         pool: &mut Pool<CoinType,Item>,
         amount: u64,
         receiver: address,
         ctx: &mut TxContext
    ){
        //coin::take(&mut pool.coin,amount,ctx)
        assert!(pool.receiver==tx_context::sender(ctx),err_code::not_auth_operator());
        assert!(balance::value(&pool.coin)>=amount,err_code::err_pool_token_insufficient());
        let out_put=coin::take(&mut pool.coin,amount,ctx);
        transfer::public_transfer(out_put,receiver);
    }

    public entry fun remove_nft_from_pool<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        item_ids: vector<ID>,
        receiver: address,
        _ctx: &mut TxContext
    ){
          let item_num=vector::length(&item_ids);
          let i=0;
          while (i < item_num) {
                let nft_id=vector::pop_back(&mut item_ids);
                let nft=dynamic_object_field::remove(&mut pool.id,nft_id);
                transfer::public_transfer<Item>(nft,receiver);
                i=i+1;
            }; 
    }

    public(friend) fun withdraw_nft_and_transfer_one_receiver<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        item_ids: ID,
        receiver: address,
        _ctx: &mut TxContext,
    ){
        assert!(dynamic_object_field::exists_(& pool.id,item_ids),err_code::err_pool_not_exist_item_id());
        let nft=dynamic_object_field::remove<ID,Item>(&mut pool.id,item_ids);
        transfer::public_transfer<Item>(nft,receiver);
    }

    public(friend) fun withdraw_nft_and_transfer_receiver<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        item_ids: vector<ID>,
        receiver: address,
        _ctx: &mut TxContext,
        ){

            let item_num=vector::length(&item_ids);
            //assert(item_num>get_pool_nft_number(pool),err_code::err_pool_nft_insufficient());
           
            let i=0;
            while (i < item_num) {
                let nft_id=vector::pop_back(&mut item_ids);
                let nft=dynamic_object_field::remove<ID,Item>(&mut pool.id,nft_id);
                transfer::public_transfer<Item>(nft,receiver);
                i=i+1;
            }; 
            //amm_implements_event::item_remove_pool_event(object::id(pool),item_ids); 
        }


   

    public (friend) fun add_muti_nft<CoinType,Item: key+store>(
         pool: &mut Pool<CoinType,Item>,
         nftids: vector<Item>
    ): vector<ID>{
         
          let ids = vector::empty<ID>();
          let i=0;
          let nft_length=vector::length(&nftids);
          while (i < nft_length) {
            let item = vector::pop_back(&mut nftids);
            let nft_id = object::id(&item);
            vector::push_back(&mut ids, nft_id);
            dynamic_object_field::add(&mut pool.id,nft_id,item);
            //object_table::add(&mut sales.nfts, nft_id, item);
            i=i+1;
        };
        //amm_implements_event::item_add_pool_event(object::id(pool),ids);
        vector::destroy_empty(nftids);
        ids
    }


     public(friend) fun setting_pool_spot_price<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        new_spot_price: u64,
    ){
        pool.spot_price=new_spot_price;
        amm_implements_event::setting_pool_spot_price_event(object::id(pool),new_spot_price);
    }

    public(friend) fun setting_pool_delta<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        new_delta: u64,
    ){
        pool.delta=new_delta;
        amm_implements_event::setting_pool_delta_event(object::id(pool),new_delta);
    }

    public(friend) fun swap_pool_funds<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<CoinType>{
        coin::take(&mut pool.coin,amount,ctx)
    }

    public(friend) fun withdraw_pool_funds<CoinType,Item: key+store>(
         pool: &mut Pool<CoinType,Item>,
         ctx: &mut TxContext
    ): Coin<CoinType>{
        let amount=balance::value(&pool.coin);
        coin::take(&mut pool.coin,amount,ctx)
    }


    public(friend) fun put_pool_funds<CoinType,Item: key+store>(
        pool: &mut Pool<CoinType,Item>,
        coin_in: Coin<CoinType>,
    ){
        coin::put(&mut pool.coin,coin_in);
    }
    public fun get_pool_funds<CoinType,Item: key+store>(
         pool: &Pool<CoinType,Item>,
    ):u64{
        balance::value(&pool.coin)
    }

    public fun get_pool_type<CoinType,Item: key+store>(
         pool: &mut Pool<CoinType,Item>,
    ):u8{
        pool.pool_type
    }




    public  fun generate_collection_name<Item: key+store>():String{
          string::from_ascii(into_string(get<Item>()))
    }    

    public(friend) fun has_registered<CoinType, Item: key+store>(
        global: &Global
    ): bool {
       let lp_name = generate_collection_name<Item>();
        object_bag::contains_with_type<String, Collection<Item>>(&global.collection, lp_name)
    }


    public  fun get_pool_spot_price<CoinType,Item: key+store>(
        pool: & Pool<CoinType,Item>
        ):u64{
             pool.spot_price
    }

    public  fun get_pool_delta<CoinType,Item: key+store>(
        pool: & Pool<CoinType,Item>
        ):u64{
        pool.delta
    }
    public fun get_pool_fee<CoinType,Item: key+store>(
        pool: &Pool<CoinType,Item>
        ):u64{
        pool.coin_fee
    }
    public fun get_global_fee(
        global:  &Global,
    ): u64{
        global.protocol_fee
    }

     public fun get_global_receiver(
        global: &Global,
    ):address{
        global.receiver
    }

    public fun get_pool_receiver<CoinType,Item: key+store>(
        pool: &Pool<CoinType,Item>,
    ):address{
        pool.receiver
    }

    public fun get_pool_algorithm_type<CoinType,Item: key+store>(
         pool: &Pool<CoinType,Item>,
    ):u8{
        pool.algorithm_type
    }

    public fun get_collection_pool_ids<Item: key+store>(
        global: &mut Global,
    ):vector<ID>{
        let lp_name = generate_collection_name<Item>();
        let collection=object_bag::borrow<String, Collection<Item>>(&global.collection, lp_name);
        vec_set::into_keys(collection.pools)
    }

    // public fun get_pool_nft_number<CoinType,Item: key+store>(
    //      pool: &Pool<CoinType,Item>
    //      ): u64{
    //         object_table::length(&pool.item)
    // }

}
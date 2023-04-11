module suimelt::xyk_curve {

    use suimelt::err_code;


    
    //let spot_price=5*spot_price;
    //let delta=11+10*delta;
    public  fun get_buy_info(spot_price: u64,delta: u64, item_number: u64,fee: u64, protocol_fee: u64):(u64,u64,u64,u64){
        assert!(item_number!=0,err_code::err_nft_number_is_zero());

       

        let token_balance=spot_price;
        let nft_balabnce=delta;

         assert!(nft_balabnce>item_number,1);

        let input_value_without_fee=(item_number*token_balance)/(nft_balabnce-item_number);

        let calc_protocol_fee=input_value_without_fee*protocol_fee/10000;
        
        //let calc_protocol_fee=math::fmul(uint256(input_value_without_fee),uint256(protocol_fee),math::MIN_UNIT);

        let fee=input_value_without_fee*fee/10000;

        let input_value=input_value_without_fee+calc_protocol_fee+fee;

        let new_spot_price=spot_price+input_value_without_fee;

        let new_delta=delta-item_number;
         (new_spot_price,new_delta,input_value,calc_protocol_fee)
    }

    public  fun  get_sell_info(spot_price: u64,delta: u64, item_number: u64,fee: u64, protocol_fee: u64):(u64,u64,u64,u64){
            assert!(item_number!=0,err_code::err_nft_number_is_zero());
            let token_balance=spot_price;
            let nft_balabnce=delta; 
            let output_value_without_fee = (item_number*token_balance)/(nft_balabnce+item_number);
            let calc_protocol_fee= output_value_without_fee*protocol_fee/10000;
            let fee= output_value_without_fee*fee/10000;
            let output_value=output_value_without_fee-calc_protocol_fee-fee;
            let new_spot_price=spot_price-output_value_without_fee;
            let new_delta=delta+item_number;
            (new_spot_price,new_delta,output_value,calc_protocol_fee)
    }





}

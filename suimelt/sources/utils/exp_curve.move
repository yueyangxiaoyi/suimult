module suimelt::exp_curve{
    use  suimelt::amm_math;
    use suimelt::err_code;



    const UNIT:u64=10000;
    const MIN_PRICE: u64=10000;

    public fun get_buy_info(
        spot_price: u64,
        delta: u64, 
        item_number: u64,
        fee: u64, 
        protocol_fee: u64
    ):(u64,u64,u64,u64){
        assert!(item_number!=0,err_code::err_nft_number_is_zero());
       let pow_m=amm_math::pow((spot_price*(UNIT+delta)),item_number); 
       let pow_n=amm_math::pow(UNIT,item_number);

       // let new_spot_price=amm_math::div((amm_math::pow(amm_math::mul(spot_price,UNIT+delta),item_number)),amm_math::pow(UNIT,item_number));
        //newspot_price
        let new_spot_price=pow_m/pow_n;

        let buy_spot_price=spot_price*(UNIT+delta)/UNIT;

        let input_value=0;

        let i=0;
        
        while (item_number>=i){
            input_value=input_value+buy_spot_price;
            buy_spot_price=buy_spot_price*(UNIT+delta)/UNIT;
            i=i+1;
        };

        let calc_protocol_fee=input_value*protocol_fee/10000;

        input_value=input_value+input_value*fee/10000;

        input_value=input_value+calc_protocol_fee;
        (new_spot_price,delta,input_value,calc_protocol_fee)
    }
    
    public fun get_sell_info(
       spot_price: u64,
       delta: u64,
       item_number: u64,
       fee: u64,
       protocol_fee: u64
    ):(u64 ,u64,u64,u64){
        assert!(item_number!=0,err_code::err_nft_number_is_zero());

        let pow_m=amm_math::pow((spot_price*(UNIT-delta)),item_number); 
        let pow_n=amm_math::pow(UNIT,item_number);
        let new_start_price=pow_m/pow_n;

        if ( new_start_price < MIN_PRICE ){
            new_start_price=MIN_PRICE;
        };
        let output_value=0;

        let i=0;

        while (item_number>=i){
            output_value=output_value+spot_price;
            spot_price=spot_price*(UNIT-delta)/UNIT;
            i=i+1;
        };



        let calc_protocol_fee=output_value*protocol_fee/10000;

        output_value=output_value-output_value*fee/10000;

        output_value=output_value-calc_protocol_fee;

        (new_start_price,delta,output_value,calc_protocol_fee)
    }

}
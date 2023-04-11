module suimelt::linear_curve {


    use suimelt::err_code;

    
    public  fun get_buy_info(spot_price: u64,delta: u64, item_number: u64,fee: u64, protocol_fee: u64):(u64,u64,u64,u64){
        assert!(item_number!=0,err_code::err_nft_number_is_zero());
        let new_spot_price=spot_price + delta * item_number;
        let buy_spot_price= spot_price + delta;
        let input_value=item_number * buy_spot_price + (item_number * (item_number - 1) * delta) / 2;
        // div
        let calc_protocol_fee=input_value*protocol_fee/10000;
        //div
        input_value=input_value+input_value*fee/10000;
        
        input_value=input_value+protocol_fee;

        (new_spot_price,delta,input_value,calc_protocol_fee)
    }

    public  fun get_sell_info(
        spot_price: u64,
        delta: u64,
        item_number: u64,
        fee: u64, 
        protocol_fee: u64
    ):(u64 ,u64,u64,u64){
        assert!(item_number!=0,err_code::err_nft_number_is_zero());

        let new_spot_price=0; 
        // We first calculate the change in spot price after selling all of the items
        let total_price_decrease=delta*item_number;
        if (spot_price < total_price_decrease){
            // Then we set the new spot price to be 0. (Spot price is never negative)
            new_spot_price=0;
            // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
            let  number_util_zero_price = spot_price / delta + 1;
            item_number=number_util_zero_price;
        }else{
            new_spot_price = spot_price - (total_price_decrease);

        };
        let output_value =
            item_number *
                spot_price -
                (item_number * (item_number - 1) * delta) /
                    2;
        let calc_protocol_fee=output_value*protocol_fee/10000;

        output_value=output_value-output_value*fee/10000;
        output_value = output_value-calc_protocol_fee;

        (new_spot_price,delta,output_value,calc_protocol_fee)
    }


}

module suimelt::err_code {

    const Prefix: u64=0x0000;

    public  fun not_auth_operator(): u64{
        Prefix+0001
    }

    public fun err_input_amount(): u64{
        Prefix+0002
    }

    public  fun  err_amount_is_zero(): u64{
        Prefix+0003
    }
    public fun  err_nft_number_is_zero(): u64{
        Prefix+0004
    }

    public fun err_pool_nft_insufficient(): u64{
        Prefix+0005
    }

    public fun err_input_too_litter():u64{
        Prefix+0006
    }

    public fun err_input_amount_insufficient(): u64{
        Prefix+0007
    }
    public fun err_input_token_insufficient(): u64{
        Prefix+0008
    }
    public fun err_pool_type(): u64{
        Prefix+0009
    }

     public fun err_pool_token_insufficient(): u64{
        Prefix+0010
    }
    public fun err_pool_not_exist_item_id(): u64{
        Prefix+0011
    }

    public fun err_input_start_price(): u64{
        Prefix+0012
    }
    
    public fun err_collection_already_register(): u64{
        Prefix+0013
    }
    






}

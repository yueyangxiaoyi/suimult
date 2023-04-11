module suimelt::amm_pair_event{
    use sui::object::ID;
    use sui::event;

    friend suimelt::amm_pair;


    struct SwapTokenAndNFTEvent has copy,drop{
        pool_id: ID,
        nft_ids: vector<ID>,
        amount: u64,
        operator: address,
    }


    struct SwapNFTAndTokenEvent has copy,drop{
        pool_id: ID,
        nft_ids: vector<ID>,
        amount: u64,
        operator: address,
    }

    public(friend) fun swap_token_nft_event(
        pool_id: ID,
        nft_ids: vector<ID>,
        amount: u64,
        operator: address,
    ){
        event::emit(
            SwapTokenAndNFTEvent{
                pool_id,
                nft_ids,
                amount,
                operator
            }
        )
    }

    public(friend) fun swap_nft_token_event(
        pool_id: ID,
        nft_ids: vector<ID>,
        amount: u64,
        operator: address,
    ){
        event::emit(
            SwapNFTAndTokenEvent{
                pool_id,
                nft_ids,
                amount,
                operator
            }
        )

    }



    

}
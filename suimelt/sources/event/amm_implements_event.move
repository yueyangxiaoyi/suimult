module suimelt::amm_implements_event{
    use sui::event;
    use sui::object::ID;
    use std::string::String;
    friend suimelt::amm_implements;




    struct GlobalCreateEvent has copy,drop{
        global_id: ID,
        owner: address,
        protocol_fee: u64,
    }

    struct ProtocolFeeUpdateEvent has copy,drop{
        fee: u64,
    }

    struct CollectionCreatedEvent has copy,drop{
         collection_type: String
    }

    struct PoolAddCollectionEvent has copy,drop{
        collection_type: String,
        pool_id: ID,
        
    }
    struct PoolNFTCreatedEvent has copy,drop{
        collection_type: String,
        pool_id: ID,
        nft_ids: vector<ID>,
        pool_type: u8,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        fee: u64,
    }
    struct PoolTokenCreatedEvent has copy,drop{
        collection_type: String,
        pool_id: ID,
        token_balance: u64,
        pool_type: u8,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        fee: u64,
    }

    struct ItemAddToPoolEvent has copy,drop{
        pool_id: ID,
        nft_ids: vector<ID>,
    }

    struct ItemRemovedFromPoolEvent has copy,drop{
        pool_id: ID,
        nft_ids: vector<ID>,
    }

    struct PoolSpotPriceUpdateEvent has copy,drop{
        pool: ID,
        new_spot_price: u64,
    }
    struct PoolDeltaUpdateEvent has copy,drop{
        pool: ID,
        new_delta: u64,
    }



    struct PoolTradeCreatedEvent has copy,drop{
        collection_type: String,
        pool_id: ID,
        token_balance: u64,
        nft_ids: vector<ID>,
        pool_type: u8,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        fee: u64,
    }

    struct PoolDestoryEvent has copy,drop{
        collection_type: String,
        pool_id: ID,
    }

    // struct SwapPoolFundsEvent has copy,drop{
    //     pool: ID,
    //     amount: u64
    // }




    public(friend)  fun global_create_event(
        global_id: ID,
        owner: address,
        protocol_fee: u64,
        ){
            event::emit(GlobalCreateEvent{
                global_id,
                owner,
                protocol_fee
            })
            
        }


    public(friend) fun collection_created_event( collection_type: String){
         event::emit(CollectionCreatedEvent{
                collection_type
            })    
    }

    public(friend) fun pool_nft_created_event(
        collection_type: String,
        pool_id: ID,
        nft_ids: vector<ID>,
        pool_type: u8,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        fee: u64,
    ){
         event::emit(PoolNFTCreatedEvent{
               collection_type,
               pool_id,
               nft_ids,
               pool_type,
               algorithm_type,
               spot_price,
               delta,
               fee,
            })
    }


    public(friend) fun pool_token_created_event(
        collection_type: String,
        pool_id: ID,
        token_balance: u64,
        pool_type: u8,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        fee: u64,
    ){
         event::emit(PoolTokenCreatedEvent{
               collection_type,
               pool_id,
               token_balance,
               pool_type,
               algorithm_type,
               spot_price,
               delta,
               fee,
            })
    }


    public(friend) fun pool_trade_created_event(
        collection_type: String,
        pool_id: ID,
        token_balance: u64,
        nft_ids: vector<ID>,
        pool_type: u8,
        algorithm_type: u8,
        spot_price: u64,
        delta: u64,
        fee: u64,
    ){
         event::emit(PoolTradeCreatedEvent{
               collection_type,
               pool_id,
               token_balance,
               nft_ids,
               pool_type,
               algorithm_type,
               spot_price,
               delta,
               fee,
            })
    }

    public(friend) fun pool_add_collection_event( 
        collection_type: String,
        pool_id: ID,){
            event::emit(PoolAddCollectionEvent{
               collection_type,
               pool_id
            })
        }

    public(friend) fun protocol_fee_update_event(
        fee: u64,
    ){
        event::emit(ProtocolFeeUpdateEvent{
              fee
            })
    }

    public(friend) fun pool_destory_and_remove_collection_event(
        collection_type: String,
        pool_id: ID,
    ){
         event::emit(PoolDestoryEvent{
               collection_type,
               pool_id
            })

    }

    public(friend) fun item_remove_pool_event(
        pool_id: ID,
        nft_ids: vector<ID>,
    ){
         event::emit(ItemRemovedFromPoolEvent{
               pool_id,
               nft_ids
            })

    }


    public(friend) fun item_add_pool_event(
        pool_id: ID,
        nft_ids: vector<ID>,
    ){
         event::emit(ItemAddToPoolEvent{
               pool_id,
               nft_ids
        })

    }

    public(friend) fun setting_pool_spot_price_event(
        pool: ID,
        new_spot_price: u64,
    ){
        event::emit(PoolSpotPriceUpdateEvent{
            pool,
            new_spot_price
        })

    }

    public(friend) fun setting_pool_delta_event(
        pool: ID,
        new_delta: u64,
    ){
        event::emit(PoolDeltaUpdateEvent{
            pool,
            new_delta
        })
    }







    
}
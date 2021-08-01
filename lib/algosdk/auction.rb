module AlgoSDK
  class Bid
    def initialize(bidder, bid_currency, limit_price, bid_id, auction_key, auction_id)
      @bidder = bidder
      @bid_currency = bid_currency
      @limit_price = limit_price
      @bid_id = bid_id
      @auction_key = auction_key
      @auction_id = auction_id
    end

    def dictify()
      {
        "aid" => @auction_id,
        "auc" => @auction_key, #TODO: decode this
        "bidder" => @bidder, #TODO: decode this
        "cur" => @bid_currency,
        "id" => @bid_id,
        "price" => @limit_price,
      }
    end
  end

  class SignedBid
    def initialize(bid, signature)
      @bid = bid
      @signature = signature
    end
  end

  class NoteField
    def initialize(signed_bid, note_field_type)
      @signed_bid = signed_bid
      @note_field_type = note_field_type
    end
  end
end

require_relative 'encoding'

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

    def hashify()
      {
        "aid" => @auction_id,
        "auc" => decode_address(@auction_key),
        "bidder" => decode_address(@bidder),
        "cur" => @bid_currency,
        "id" => @bid_id,
        "price" => @limit_price,
      }
    end

    def sign(private_key)
      """
      Sign a bid.
      Args:
          private_key (str): private_key of the bidder
      Returns:
          SignedBid: signed bid with the signature
      """
      temp = msgpack_encode(self)
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

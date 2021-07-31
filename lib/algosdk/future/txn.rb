module AlgoSDK
  class SuggestedParams
    "" "
        Contains various fields common to all transaction types.
        Args:
            fee (int): transaction fee (per byte if flat_fee is false). When flat_fee is true, 
                fee may fall to zero but a group of N atomic transactions must
                still have a fee of at least N*min_txn_fee.
            first (int): first round for which the transaction is valid
            last (int): last round for which the transaction is valid
            gh (str): genesis hash
            gen (str, optional): genesis id
            flat_fee (bool, optional): whether the specified fee is a flat fee
            consensus_version (str, optional): the consensus protocol version as of 'first'
            min_fee (int, optional): the minimum transaction fee (flat)
        Attributes:
            fee (int)
            first (int)
            last (int)
            gen (str)
            gh (str)
            flat_fee (bool)
            consensus_version (str)
            min_fee (int)
        " ""

    def initialize(fee, first, last, gh, gen = nil, flat_fee = false,
                                         consensus_version = nil, min_fee = nil)
      @first = first
      @last = last
      @gh = gh
      @gen = gen
      @fee = fee
      @flat_fee = flat_fee
      @consensus_version = consensus_version
      @min_fee = min_fee
    end

    def json
      jsonified_cls = Hash.new

      instance_variables.each do |instance_variable|
        jsonified_cls[instance_variable.to_s.delete("@")] = instance_variable_get("#{instance_variable}")
      end

      jsonified_cls
    end
  end
end

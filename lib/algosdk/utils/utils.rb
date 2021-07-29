module AlgoSDK
  class Utils
    def self.stringify_round_info(block_num, round_num)
      if !block_num.nil? and !round_num.nil?
        raise AlgoSDK::Errors::ArgsError.new("Invalid input, please specify only `block_nun` or `round_num`, not both.")
      elsif !block_num.nil?
        block_num.to_s
      elsif !round_num.nil?
        round_num.to_s
      end
    end
  end
end

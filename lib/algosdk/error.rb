# typed: true
module AlgoSDK
  module Errors
    class AlgodRequestError < StandardError
      def initialize(requrl)
        @requrl = requrl
        @message = "Error while building and executing request: #{@requrl}"
        super(@message)
      end
    end

    class ArgsError < StandardError
      def initialize(message)
        super(message)
      end
    end

    class UnderspecifiedRoundError < StandardError
      def initialize(message)
        super(message)
      end
    end

    class IncorrectArgumentType < StandardError
      def initialize(message)
        super(message)
      end
    end

    class HeadersError < StandardError
      def initialize(message)
        super(message)
      end
    end

    class WrongKeyLengthError < StandardError
      def initialize(message)
        super(message)
      end
    end

    class GenericWalletRequestError < StandardError
      def initialize(error, name)
        @error = error
        @name = name
        @message = "The following error occurred:\nRequest Response: #{error} \nWallet Name: #{name}"
        super(@message)
      end
    end
  end
end

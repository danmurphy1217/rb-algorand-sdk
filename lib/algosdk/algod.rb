require_relative "error"
require_relative "encoding"
require_relative "utils/constants"
require_relative "transaction"
require_relative "account"

require "base64"
require "net/http"
require "json"

API_VERSION = "/v2"

module AlgoSDK
  class AlgodClient
    "" "
        Client class for kmd. Handles all algod requests.
        Args:
            algod_token (str): algod API token
            algod_address (str): algod address
            headers (dict, optional): extra header name/value for all requests
        Attributes:
            algod_token (str)
            algod_address (str)
            headers (dict)
        " ""

    def initialize(algod_token, algod_address, headers = {})
      @algod_token = algod_token
      @algod_address = algod_address
      @headers = headers
    end

    def algod_request(method, requrl, params = nil, data = nil, headers = nil, raw_response = false)
      final_headers_for_req = Hash.new

      if !@headers.empty?
        # if the headers are not empty
        final_headers_for_req = final_headers_for_req.merge(@headers)
        p final_headers_for_req
      end

      if headers
        p headers
        final_headers_for_req = final_headers_for_req.merge(headers)
        p final_headers_for_req
      end
    end
  end
end

account_data = generate_account()
addr = account_data.shift
pk = account_data.shift
raise "Encoding working incorrectly" unless pk = address_from_pk(pk)

@algo = AlgoSDK::AlgodClient.new("algod_token", "algod_address", { :hi => "This is message" })
@algo.algod_request("GET", "accounts/address/", {}, addr, { :msg => "headers" }, true)

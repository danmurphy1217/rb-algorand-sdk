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

    def self.build_req(method, uri_obj, req_data, headers)
      Net::HTTP.start(uri_obj.host, uri_obj.port) do |http|
        if method == "GET"
          request = Net::HTTP::Get.new(uri_obj, headers)
        elsif method == "POST"
          request = Net::HTTP::Post.new(uri_obj, headers)
        end

        response = http.request request # Net::HTTPResponse object

        JSON.parse(response.body)
      end
    end

    def algod_request(method, requrl, params = nil, data = nil, headers = nil, raw_response = false)
      final_headers_for_req = Hash.new

      if !@headers.empty?
        # if the headers are not empty
        final_headers_for_req = final_headers_for_req.merge(@headers)
      end

      if headers
        final_headers_for_req = final_headers_for_req.merge(headers)
      end

      if not Constants::NO_AUTH.include?(requrl)
        final_headers_for_req = final_headers_for_req.merge({
          Constants::ALGOD_AUTH_HEADER => @algod_token,
        })
      end

      if !Constants::UNVERSIONED_PATHS.include?(requrl)
        # requrl should be versioned appropriately
        requrl = API_VERSION + requrl
      end

      uri = URI(@algod_address + requrl)

      if params
        uri.query = URI.encode_www_form(params)
      end

      request = self.class.build_req(method, uri, data, final_headers_for_req)
      p request
    end
  end
end

account_data = generate_account()
addr = account_data.shift
pk = account_data.shift
raise "Encoding working incorrectly" unless pk = address_from_pk(pk)

@algo = AlgoSDK::AlgodClient.new("1e506580e964a022db4a5eb64e561240718afa6bd65e9ef1d5a2f72fe62f3775", "http://127.0.0.1:8080", { :hi => "This is message" })
@algo.algod_request("GET", "/status")
@algo.algod_request("GET", "/accounts/MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4")

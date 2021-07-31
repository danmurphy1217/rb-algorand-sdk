# typed: true
require_relative "error"
require_relative "encoding"
require_relative "utils/constants"
require_relative "utils/utils"
require_relative "transaction"
require_relative "account"
require_relative "future/txn"

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

      begin
        request = self.class.build_req(method, uri, data, final_headers_for_req)
      rescue
        raise AlgoSDK::Errors::AlgodRequestError.new(@algod_address + requrl)
      end
      request
    end

    def status(**kwargs)
      "" "Return node status." ""
      req = "/status"
      algod_request("GET", req, **kwargs)
    end

    def health(**kwargs)
      "" "Return null if the node is running." ""
      req = "/health"
      algod_request("GET", req, **kwargs)
    end

    def status_after_block(block_num = nil, round_num = nil, **kwargs)
      "" "
      Return node status immediately after blockNum.
      Args:
          block_num (int, optional): block number
          round_num (int, optional): alias for block_num; specify one of
              these
      " ""
      if block_num.nil? and round_num.nil?
        raise AlgoSDK::Errors::ArgsError.new("Invalid input, either `block_nun` or `round_num` is required")
      end

      req = "/status/wait-for-block-after/" + Utils::stringify_round_info(block_num, round_num)
      algod_request("GET", req, **kwargs)
    end

    def pending_transactions(max_transactions, **kwargs)
      "" "
      Return pending transactions.
      Args:
          max_txns (int): maximum number of transactions to return;
              if max_txns is 0, return all pending transactions
      " ""
      query = { "max": max_transactions }
      req = "/transactions/pending"
      algod_request("GET", req, params = query, **kwargs)
    end

    def versions(**kwargs)
      "" "Return algod versions." ""
      req = "/versions"
      return algod_request("GET", req, **kwargs)
    end

    def ledger_supply(**kwargs)
      "" "Return supply details for node's ledger." ""
      req = "/ledger/supply"
      return algod_request("GET", req, **kwargs)
    end

    def transactions_by_address(address, first = nil, last = nil,
                                         limit = nil, from_date = nil, to_date = nil,
                                **kwargs)
      "" "
        Return transactions for an address. If indexer is not enabled, you can
        search by date and you do not have to specify first and last rounds.
        Args:
            address (str): account public key
            first (int, optional): no transactions before this block will be
                returned
            last (int, optional): no transactions after this block will be
                returned; defaults to last round
            limit (int, optional): maximum number of transactions to return;
                default is 100
            from_date (str, optional): no transactions before this date will be
                returned; format YYYY-MM-DD
            to_date (str, optional): no transactions after this date will be
                returned; format YYYY-MM-DD
        " ""
      query = Hash.new
      if !first.nil?
        query["firstRound"] = first
      end
      if !last.nil?
        query["lastRound"] = last
      end
      if !limit.nil?
        query["max"] = limit
      end
      if !to_date.nil?
        query["toDate"] = to_date
      end
      if !from_date.nil?
        query["fromDate"] = from_date
      end
      req = "/account/" + address + "/transactions"
      algod_request("GET", req, params = query, **kwargs)
    end

    def account_info(address, **kwargs)
      "" "
        Return account information for an address.
        Args:
            address (str): account public key
        " ""
      req = "/account/" + address
      algod_request("GET", req, **kwargs)
    end

    def asset_info(asset_id)
      "" "
        Return asset information for an asset id.

        Args:
          asset_id (str): asset id
      " ""
      req = "/assets/" + asset_id
      algod_request("GET", req)
    end

    def list_assets(max_index = nil, max_assets = nil, **kwargs)
      "" "
        Return a list of assets of length == max_assets with IDs <= max_index.

        Args:
          max_index (int): maximum asset index to include
          max_assets (int): maximum number of assets to return. Defaults to 100.
      " ""
      query = Hash.new
      query["assetIdx"] = max_index.nil? ? 0 : max_index
      query["max"] = max_assets.nil? ? 100 : max_assets

      req = "/assets"
      algod_request("GET", req, params = query, **kwargs)
    end

    def txn_info(address, txn_id, **kwargs)
      "" "
      Return transaction information.
      Args:
          address (str): account public key
          transaction_id (str): transaction ID
      " ""
      req = "/account/" + address + "/transaction/" + txn_id.to_s
      algod_request("GET", req, **kwargs)
    end

    def pending_transaction_info(txn_id, **kwargs)
      "" "
      Return transaction information for a pending transaction.
      Args:
          transaction_id (str): transaction ID
      " ""
      req = "/transactions/pending/" + txn_id.to_s
      return algod_request("GET", req, **kwargs)
    end

    def transaction_by_id(txn_id, **kwargs)
      "" "
      Return transaction information; only works if indexer is enabled.
      Args:
          transaction_id (str): transaction ID
      " ""
      req = "/transaction/" + txn_id.to_s
      return algod_request("GET", req, **kwargs)
    end

    def suggested_fee(**kwargs)
      "" "Return suggested transaction fee." ""
      req = "/transactions/fee"
      return algod_request("GET", req, **kwargs)
    end

    def suggested_params(**kwargs)
      "" "Return suggested transaction parameters." ""
      req = "/transactions/params"
      return algod_request("GET", req, **kwargs)
    end

    def suggested_params_as_object(**kwargs)
      "" "Return suggested transaction parameters." ""
      req = "/transactions/params"
      res = algod_request("GET", req, **kwargs)

      AlgoSDK::SuggestedParams.new(
        res["fee"],
        res["last-round"],
        res["last-round"] + 1000,
        res["genesis-hash"],
        res["genesis-id"],
        false
      )
    end

    def send_raw_txn(txn, **kwargs)
      "" "
      Broadcast a signed transaction to the network.
      Sets the default Content-Type header, if not previously set.
      Args:
          txn (str): transaction to send, encoded in base64
          request_header (dict, optional): additional header for request
      Returns:
          str: transaction ID
      " ""
      #TODO!
    end
  end
end

# account_data = generate_account()
# addr = account_data.shift
# pk = account_data.shift
# raise "Encoding working incorrectly" unless pk = address_from_pk(pk)

@algo = AlgoSDK::AlgodClient.new("1e506580e964a022db4a5eb64e561240718afa6bd65e9ef1d5a2f72fe62f3775", "http://127.0.0.1:8080", { :hi => "This is message" })
# @algo.algod_request("GET", "/status")
# @algo.algod_request("GET", "/accounts/MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4")
# p @algo.status_after_block(1000)
# p @algo.pending_transactions(1)
# p @algo.versions()
# p @algo.ledger_supply()
# p @algo.transactions_by_address("MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4")
# p @algo.account_info("MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4")
# p @algo.asset_info("31566704")
# p @algo.list_assets()
# p @algo.txn_info("MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4", 100)
# p @algo.pending_transaction_info("100000")
# p @algo.suggested_params_as_object().json
# p @algo.suggested_params_as_object()

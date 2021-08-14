# typed: true
require_relative 'error'
require_relative 'encoding'
require_relative 'utils/constants'
require_relative 'utils/utils'
require_relative 'transaction'
require_relative 'account'
require_relative 'future/txn'

require 'base64'
require 'net/http'
require 'json'

API_VERSION = '/v2'

module AlgoSDK
  class AlgodClient
    '' "
        Client class for kmd. Handles all algod requests.
        Args:
            algod_token (str): algod API token
            algod_address (str): algod address
            headers (dict, optional): extra header name/value for all requests
        Attributes:
            algod_token (str)
            algod_address (str)
            headers (dict)
        " ''

    def initialize(algod_token, algod_address, headers = {})
      @algod_token = algod_token
      @algod_address = algod_address
      @headers = headers
    end

    def self.build_req(method, uri_obj, _req_data, headers)
      Net::HTTP.start(uri_obj.host, uri_obj.port, use_ssl: uri_obj.scheme == 'https') do |http|
        if method == 'GET'
          request = Net::HTTP::Get.new(uri_obj, headers)
        elsif method == 'POST'
          request = Net::HTTP::Post.new(uri_obj, headers)
        end

        response = http.request request # Net::HTTPResponse object

        response
      end
    end

    def algod_request(method, requrl, params = nil, data = nil, headers = nil, _raw_response = false)
      final_headers_for_req = {}

      unless @headers.empty?
        # if the headers are not empty
        final_headers_for_req = final_headers_for_req.merge(@headers)
      end

      final_headers_for_req = final_headers_for_req.merge(headers) if headers

      unless Constants::NO_AUTH.include?(requrl)
        final_headers_for_req = final_headers_for_req.merge({
                                                              Constants::ALGOD_AUTH_HEADER => @algod_token
                                                            })
      end

      unless Constants::UNVERSIONED_PATHS.include?(requrl)
        # requrl should be versioned appropriately
        requrl = API_VERSION + requrl
      end

      uri = URI(@algod_address + requrl)

      uri.query = URI.encode_www_form(params) if params

      begin
        request = self.class.build_req(method, uri, data, final_headers_for_req)
      rescue StandardError
        raise AlgoSDK::Errors::AlgodRequestError, @algod_address + requrl
      end

      request
    end

    def status(**kwargs)
      '' 'Return node status.' ''
      req = '/status'
      algod_request('GET', req, **kwargs)
    end

    def health(**kwargs)
      '' 'Return null if the node is running.' ''
      req = '/health'
      algod_request('GET', req, **kwargs)
    end

    def metrics(**kwargs)
      '''return metrics about algod functioning.'''
      req = '/metrics'
      algod_request('GET', req, **kwargs)
    end

    def swagger(**kwargs)
      '''Returns the current swagger spec in json.'''
      req = '/swagger.json'
      algod_request('GET', req, **kwargs)
    end

    def status_after_block(block_num = nil, round_num = nil, **kwargs)
      '' "
      Return node status immediately after blockNum.
      Args:
          block_num (int, optional): block number
          round_num (int, optional): alias for block_num; specify one of
              these
      " ''
      if block_num.nil? && round_num.nil?
        raise AlgoSDK::Errors::ArgsError, 'Invalid input, either `block_nun` or `round_num` is required'
      end

      req = '/status/wait-for-block-after/' + Utils.stringify_round_info(block_num, round_num)
      algod_request('GET', req, **kwargs)
    end

    def pending_transactions(max_transactions, **kwargs)
      '' "
      Return pending transactions.
      Args:
          max_txns (int): maximum number of transactions to return;
              if max_txns is 0, return all pending transactions
      " ''
      query = { "max": max_transactions }
      req = '/transactions/pending'
      algod_request('GET', req, params = query, **kwargs)
    end

    def versions(**kwargs)
      '' 'Return algod versions.' ''
      req = '/versions'
      algod_request('GET', req, **kwargs)
    end

    def ledger_supply(**kwargs)
      '' "Return supply details for node's ledger." ''
      req = '/ledger/supply'
      algod_request('GET', req, **kwargs)
    end

    def transactions_by_address(address, first = nil, last = nil,
                                limit = nil, from_date = nil, to_date = nil,
                                **kwargs)
      '' "
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
        " ''
      query = {}
      query['firstRound'] = first unless first.nil?
      query['lastRound'] = last unless last.nil?
      query['max'] = limit unless limit.nil?
      query['toDate'] = to_date unless to_date.nil?
      query['fromDate'] = from_date unless from_date.nil?
      req = '/accounts/' + address + '/transactions'
      algod_request('GET', req, params = query, **kwargs)
    end

    def account_info(address, **kwargs)
      '' "
        Return account information for an address.
        Args:
            address (str): account public key
        " ''
      req = '/accounts/' + address
      algod_request('GET', req, **kwargs)
    end

    def asset_info(asset_id)
      '' "
        Return asset information for an asset id.

        Args:
          asset_id (str): asset id
      " ''
      req = '/assets/' + asset_id
      algod_request('GET', req)
    end

    def list_assets(max_index = nil, max_assets = nil, **kwargs)
      '' "
        Return a list of assets of length == max_assets with IDs <= max_index.

        Args:
          max_index (int): maximum asset index to include
          max_assets (int): maximum number of assets to return. Defaults to 100.
      " ''
      query = {}
      query['assetIdx'] = max_index.nil? ? 0 : max_index
      query['max'] = max_assets.nil? ? 100 : max_assets

      req = '/assets'
      algod_request('GET', req, params = query, **kwargs)
    end

    def txn_info(address, txn_id, **kwargs)
      '' "
      Return transaction information.
      Args:
          address (str): account public key
          transaction_id (str): transaction ID
      " ''
      req = '/accounts/' + address + '/transaction/' + txn_id.to_s
      algod_request('GET', req, **kwargs)
    end

    def pending_transactions_for_account(address, **kwargs)
      '' "
      Return transaction information.
      Args:
          address (str): account public key
          transaction_id (str): transaction ID
      " ''
      req = '/accounts/' + address + '/transactions/pending'
      algod_request('GET', req, **kwargs)
    end

    def info_for_pending_transaction(txn_id, **kwargs)
      '' "
      Return transaction information for a pending transaction.
      Args:
          transaction_id (str): transaction ID
      " ''
      req = '/transactions/pending/' + txn_id.to_s
      algod_request('GET', req, **kwargs)
    end

    def transaction_by_id(txn_id, **kwargs)
      '' "
      Return transaction information; only works if indexer is enabled.
      Args:
          transaction_id (str): transaction ID
      " ''
      req = '/transaction/' + txn_id.to_s
      algod_request('GET', req, **kwargs)
    end

    def get_application(application_id, **kwargs)
      ''"
      Get application information for `application_id`

      Given a application id, it returns application information
      including creator, approval and clear programs, global and
      local schemas, and global state.
      "''
      req = '/applications/' + application_id
      algod_request('GET', req, **kwargs)
    end

    def get_asset(asset_id, **kwargs)
      ''"
      Get asset information for `asset_id`

      Given a asset id, it returns asset information
      including creator, name, total supply and special
      addresses.
      "''
      req = '/assets/' + asset_id
      algod_request('GET', req, **kwargs)
    end

    def suggested_fee(**kwargs)
      '' 'Return suggested transaction fee.' ''
      req = '/transactions/fee'
      algod_request('GET', req, **kwargs)
    end

    def suggested_params(**kwargs)
      '' 'Return suggested transaction parameters.' ''
      req = '/transactions/params'
      algod_request('GET', req, **kwargs)
    end

    def suggested_params_as_object(**kwargs)
      '' 'Return suggested transaction parameters.' ''
      req = '/transactions/params'
      res = algod_request('GET', req, **kwargs)

      AlgoSDK::SuggestedParams.new(
        res['fee'],
        res['last-round'],
        res['last-round'] + 1000,
        res['genesis-hash'],
        res['genesis-id'],
        false
      )
    end

    def send_raw_txn(txn, headers = nil, **kwargs)
      '' "
      Broadcast a signed transaction to the network.
      Sets the default Content-Type header, if not previously set.
      Args:
          txn (str): transaction to send, encoded in base64
          request_header (dict, optional): additional header for request
      Returns:
          str: transaction ID
      " ''
      # TODO!
      txn_headers = !headers.nil? ? headers : {}

      if !txn_headers.has_key?('Content-Type') && !txn_headers.has_key?('content-type')
        txn_headers['Content-Type'] = 'application/x-binary'
      end

      decoded_txn = Base64.decode64(txn)
      req = '/transactions'
      algod_request('POST', req, data = decoded_txn, headers = txn_headers, **kwargs)['txId']
    end

    def send_txn(_txn, **_kwargs)
      '' "
      Broadcast a signed transaction object to the network.
      Args:
          txn (SignedTransaction or MultisigTransaction): transaction to send
          request_header (dict, optional): additional header for request
      Returns:
          str: transaction ID
      " ''
      # TODO! have to build out all txns
      # self.class.send_raw_txn(encoding.msgpack_encode(txn), **kwargs)
    end

    def send_txns(txns, **kwargs)
      '' "
      Broadcast list of a signed transaction objects to the network.
      Args:
          txns (SignedTransaction[] or MultisigTransaction[]):
              transactions to send
          request_header (dict, optional): additional header for request
      Returns:
          str: first transaction ID
      " ''
      serialized = []
      txns.each do |txn|
        serialized.append(Base64.decode64(msgpack_encode(txn)))
      end
      send_raw_txn(Base64.encode64(serialized.join('')), **kwargs)
    end

    def block_info(round_num = nil, **kwargs)
      '' "
      Return block information.
      Args:
          round_num (int, optional): the round to retrieve block_info for.
      " ''
      if round_num.nil?
        raise AlgoSDK::Errors::UnderspecifiedRoundError, 'Must specify `round_num` arg.'
      elsif !round_num.is_a?(Integer)
        raise AlgoSDK::Errors::IncorrectArgumentType, "`round_num` must be an integer, you passed #{round_num}."
      end

      req = '/blocks/' + specify_round_string(round_num)
      algod_request('GET', req, **kwargs)
    end

    def block_info_raw(round_num = nil, **kwargs)
      '' "
      Return decoded raw block as the network sees it.

      Args:
          round_num (int, optional): the round to retrieve block_info for.
      " ''
      raise AlgoSDK::Errors::UnderspecifiedRoundError, 'Must specify `round_num` arg.' if round_num.nil?

      if kwargs[:headers].nil?
        kwargs[:headers] = {}
        kwargs[:headers]['Content-Type'] = 'application/x-algorand-block-v1'
      elsif !kwargs[:headers].has_key?('Content-Type') && !kwargs[:headers].has_key?('content-type')
        kwargs[:headers]['content-type'] = 'application/x-algorand-block-v1'
      else
        kwargs[:headers]['content-type'] = 'application/x-algorand-block-v1'
      end

      req = '/blocks/' + specify_round_string(round_num)
      # query = { :raw => 1 }
      query = {}
      kwargs['raw_response'] = true
      response = algod_request('GET', req, query, **kwargs)
      block_type = 'application/x-algorand-block-v1'
      content_type = response['content-type']

      if content_type != block_type
        raise AlgoSDK::Errors::HeadersError, "expected 'Content-Type: #{block_type}' but got #{content_type}"
      end

      # TODO: return msgpack.loads(response.read())
      'TODO!!!'
      # TODO
    end

    def get_merkle_proof_for_round_and_txn(round, txid, **kwargs)
      unless round.is_a?(Integer)
        raise AlgoSDK::Errors::IncorrectArgumentType, "`round` must be an integer, you passed #{round}."
      end

      req = '/blocks/' + round.to_s + '/transactions/' + txid.to_s + '/proof'
      algod_request('GET', req, **kwargs)
    end

    def catchup_to(catchpoint, **kwargs)
      # TODO
      """Given a catchpoint, it starts catching up to this catchpoint"""
      req = '/catchup/' + catchpoint
      algod_request('POST', req, **kwargs)
    end

    def abort_catchup(catchpoint, **kwargs)
      # TODO test
      """Given a catchpoint, it aborts catching up to this catchpoint"""
      req = '/catchup/' + catchpoint
      algod_request('DELETE', req, **kwargs)
    end

    def get_ledger_supply(**kwargs)
      req = '/ledger/supply'
      algod_request('GET', req, **kwargs)
    end

    def register_participation_keys_for(address, **kwargs)
      #TODO: test
      req = '/register-participation-keys/' + address
      algod_request('POST', req, **kwargs)
    end

    def shutdown(timeout = nil, **kwargs)
      """
      Special management endpoint to shutdown the node
      Optionally provide a timeout parameter to indicate
      that the node should begin shutting down after a number
      of seconds.
      """
      #TODO test
      if timeout.nil?
        req = "/shutdown"
      else
        req = "/shutdown" + "?timeout=#{timeout}"
      end

      algod_request('POST', req)
    end

    private

    def specify_round_string(round_num)
      '' "
      Return the round number specified in either 'block' or 'round_num'.
      Args:
          block (int): user specified variable
          round_num (int): user specified variable
      " ''
      round_num.to_s
    end
  end
end

# account_data = generate_account()
# addr = account_data.shift
# pk = account_data.shift
# raise "Encoding working incorrectly" unless pk = address_from_pk(pk)

# @algo = AlgoSDK::AlgodClient.new("1e506580e964a022db4a5eb64e561240718afa6bd65e9ef1d5a2f72fe62f3775", "http://127.0.0.1:8080", { :hi => "This is message" })
# @algo = AlgoSDK::AlgodClient.new("", "https://testnet.algoexplorerapi.io", headers = { 'User-Agent': "DanM" })

# p @algo.algod_request("GET", "/status").body
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
# p @algo.suggested_params_as_object().hashify
# p @algo.suggested_params_as_object()
# p @algo.send_txns(["adfgdg", "aewtghb"])
# p @algo.block_raw(100, headers: { 'User-Agent': "DanM" })

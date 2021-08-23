require_relative 'utils/constants'
require_relative 'error'

require 'base64'
require 'net/http'
require 'json'

API_VERSION = '/v2'

module AlgoSDK
  class IndexerClient
    def initialize(indexer_token, indexer_address, headers)
      @indexer_token = indexer_token
      @indexer_address = indexer_address
      @headers = headers
    end

    def self.build_req(method, uri_obj, req_data, headers)
      Net::HTTP.start(uri_obj.host, uri_obj.port, use_ssl: uri_obj.scheme == 'https') do |http|
        if method == 'GET'
          request = Net::HTTP::Get.new(uri_obj, headers)
        elsif method == 'POST'
          request = Net::HTTP::Post.new(uri_obj, headers)
          request.body = req_data.is_a?(String) ? req_data : URI.encode_www_form(req_data)
        elsif method == 'DELETE'
          http = Net::HTTP.new(uri_obj.host, uri_obj.port)
          request = Net::HTTP::Delete.new(uri_obj.path, headers)
          request.body = req_data.is_a?(String) ? req_data : URI.encode_www_form(req_data)
        end
        response = http.request request # Net::HTTPResponse object

        response.body || response.response.body
      end
    end

    def indexer_request(method, requrl, params: nil, data: nil, headers: nil)
      final_headers_for_req = {}

      unless @headers.empty?
        # if the headers are not empty
        final_headers_for_req = final_headers_for_req.merge(@headers)
      end

      final_headers_for_req = final_headers_for_req.merge(headers) if headers

      unless Constants::NO_AUTH.include?(requrl)
        final_headers_for_req = final_headers_for_req.merge({
                                                              Constants::INDEXER_AUTH_HEADER => @indexer_token
                                                            })
      end

      unless Constants::UNVERSIONED_PATHS.include?(requrl)
        # requrl should be versioned appropriately
        requrl = API_VERSION + requrl
      end

      uri = URI(@indexer_address + requrl)

      uri.query = URI.encode_www_form(params) if params

      begin
        request = self.class.build_req(method, uri, data.to_json, final_headers_for_req)
      rescue StandardError
        raise AlgoSDK::Errors::AlgodRequestError, @indexer_address + requrl
      end

      request
    end

    def health(**kwargs)
      req = '/health'

      indexer_request('GET', req, **kwargs)
    end

    def search_accounts(**kwargs)
      req = '/accounts'
      query = {}
      query['asset-id'] = kwargs[:asset_id] if kwargs[:asset_id]
      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['next'] = kwargs[:next_page] if kwargs[:next_page]
      query['currency-greater-than'] = kwargs[:min_balance] if kwargs[:min_balance]
      query['currency-less-than'] = kwargs[:max_balance] if kwargs[:max_balance]
      query['auth-addr'] = kwargs[:auth_addr] if kwargs[:auth_addr]
      query['application-id'] = kwargs[:application_id] if kwargs[:application_id]
      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]
      query['round'] = kwargs[:round].to_int if kwargs[:round]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      indexer_request('GET', req, params: query, data: data, headers: headers)
    end

    def get_account(address, **kwargs)
      req = "/accounts/#{address}"

      query = {}
      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]
      query['round'] = kwargs[:round] if kwargs[:round]

      indexer_request('GET', req, params: query, **kwargs)
    end

    def get_account_txns(address, **kwargs)
      req = "/accounts/#{address}/transactions"
      query = {}

      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['next'] = kwargs[:next] if kwargs[:next]
      query['note-prefix'] = Base64.encode64(kwargs[:note_prefix]) if kwargs[:note_prefix]
      query['tx-type'] = kwargs[:tx_type] if kwargs[:tx_type]
      query['sig-type'] = kwargs[:sig_type] if kwargs[:sig_type]
      query['txid'] = kwargs[:txid] if kwargs[:txid]
      query['min-round'] = kwargs[:min_round] if kwargs[:min_round]
      query['max-round'] = kwargs[:max_round] if kwargs[:max_round]
      query['round'] = kwargs[:round] if kwargs[:round]
      query['asset-id'] = kwargs[:asset_id] if kwargs[:asset_id]
      query['before-time'] = kwargs[:before_time] if kwargs[:before_time]
      query['after-time'] = kwargs[:after_time] if kwargs[:after_time]
      query['currency-greater-than'] = kwargs[:currency_greater_than] if kwargs[:currency_greater_than]
      query['currency-greater-than'] = kwargs[:currency_less_than] if kwargs[:currency_less_than]
      query['rekey-to'] = kwargs[:rekey_to] if kwargs[:rekey_to]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def search_applications(**kwargs)
      req = '/applications'
      query = {}

      query['application-id'] = kwargs[:application_id] if kwargs[:application_id]
      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]
      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['next'] = kwargs[:next] if kwargs[:next]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def get_application(app_id, **kwargs)
      req = "/applications/#{app_id}"
      query = {}

      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def search_assets(**kwargs)
      req = '/assets'
      query = {}

      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['creator'] = kwargs[:creator] if kwargs[:creator]
      query['asset-id'] = kwargs[:asset_id] if kwargs[:asset_id]
      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]
      query['name'] = kwargs[:name] if kwargs[:name]
      query['next'] = kwargs[:next] if kwargs[:next]
      query['unit'] = kwargs[:unit] if kwargs[:unit]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def get_asset(asset_id, **kwargs)
      req = "/assets/#{asset_id}"
      query = {}

      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def search_accounts_with_asset(asset_id, **kwargs)
      req = "/assets/#{asset_id}/balances"
      query = {}

      query['currency-greater-then'] = kwargs[:currency_greater_than] if kwargs[:currency_greater_than]
      query['currency-less-then'] = kwargs[:currency_less_than] if kwargs[:currency_less_than]
      query['asset-id'] = kwargs[:asset_id] if kwargs[:asset_id]
      query['include-all'] = kwargs[:include_all] if kwargs[:include_all]
      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['next'] = kwargs[:next] if kwargs[:next]
      query['round'] = kwargs[:round] if kwargs[:round]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def search_asset_txns(asset_id, **kwargs)
      req = "/assets/#{asset_id}/transactions"
      query = {}

      query['address'] = kwargs[:address] if kwargs[:address]
      query['address-role'] = kwargs[:address_role] if kwargs[:address_role]
      query['after-time'] = kwargs[:after_time] if kwargs[:after_time]
      query['before-time'] = kwargs[:before_time] if kwargs[:before_time]
      query['currency-greater-than'] = kwargs[:currency_greater_than] if kwargs[:currency_greater_than]
      query['currency-less-than'] = kwargs[:currency_less_than] if kwargs[:currency_less_than]
      query['exclude-close-to'] = kwargs[:exclude_close_to] if kwargs[:exclude_close_to]
      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['max-round'] = kwargs[:max_round] if kwargs[:max_round]
      query['min-round'] = kwargs[:min_round] if kwargs[:min_round]
      query['next'] = kwargs[:next] if kwargs[:next]
      query['note-prefix'] = Base64.encode64(kwargs[:note_prefix]) if kwargs[:note_prefix]
      query['rekey-to'] = kwargs[:rekey_to] if kwargs[:rekey_to]
      query['round'] = kwargs[:round] if kwargs[:round]
      query['sig-type'] = kwargs[:sig_type] if kwargs[:sig_type]
      query['tx-type'] = kwargs[:tx_type] if kwargs[:tx_type]
      query['txid'] = kwargs[:txid] if kwargs[:txid]

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def get_block(round_number, **kwargs)
      req = "/blocks/#{round_number}"

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: nil, data: data, headers: headers))
    end

    def search_txns(**kwargs)
      req = "/transactions"
      query = {}

      query['address'] = kwargs[:address] if kwargs[:address]
      query['address-role'] = kwargs[:address_role] if kwargs[:address_role]
      query['after-time'] = kwargs[:after_time] if kwargs[:after_time]
      query['application-id'] = kwargs[:application_id] if kwargs[:application_id]
      query['asset-id'] = kwargs[:asset_id] if kwargs[:asset_id]
      query['before-time'] = kwargs[:before_time] if kwargs[:before_time]
      query['currency-greater-than'] = kwargs[:currency_greater_than] if kwargs[:currency_greater_than]
      query['currency-less-than'] = kwargs[:currency_less_than] if kwargs[:currency_less_than]
      query['exclude-close-to'] = kwargs[:exclude_close_to] if kwargs[:exclude_close_to]
      query['limit'] = kwargs[:limit] if kwargs[:limit]
      query['max-round'] = kwargs[:max_round] if kwargs[:max_round]
      query['min-round'] = kwargs[:min_round] if kwargs[:min_round]
      query['next'] = kwargs[:next] if kwargs[:next]
      query['note-prefix'] = Base64.encode64(kwargs[:note_prefix]) if kwargs[:note_prefix]
      query['rekey-to'] = kwargs[:rekey_to] if kwargs[:rekey_to]
      query['round'] = kwargs[:round] if kwargs[:round]
      query['sig-type'] = kwargs[:sig_type] if kwargs[:sig_type]
      query['tx-type'] = kwargs[:tx_type] if kwargs[:tx_type]
      query['txid'] = kwargs[:txid] if kwargs[:txid]


      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: query, data: data, headers: headers))
    end

    def get_txn(txn_id, **kwargs)
      req = "/transactions/#{txn_id}"

      data = kwargs[:data] if kwargs[:data]
      headers = kwargs[:headers] if kwargs[:headers]

      JSON.parse(indexer_request('GET', req, params: nil, data: data, headers: headers))
    end
    private

    def build_kwargs(keyword, value, kwargs)
      if kwargs.has_key?(keyword.to_sym)
        kwargs[keyword.to_sym].update(value)
      else
        kwargs[keyword.to_sym] = {}
        kwargs[keyword.to_sym] = value
      end

      kwargs
    end
  end
end

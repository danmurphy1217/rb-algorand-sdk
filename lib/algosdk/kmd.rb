require_relative 'utils/constants'
require_relative 'error'

require 'base64'
require 'net/http'
require 'json'

API_VERSION = '/v1'

module AlgoSDK
  class KmdClient
    def initialize(kmd_token, kmd_address, headers)
      @kmd_token = kmd_token
      @kmd_address = kmd_address
      @headers = headers
    end

    # TODO: implement BaseAPI class that implements endpoints that are common across clients

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

    def kmd_request(method, requrl, params: nil, data: nil, headers: nil, raw_response: false)
      final_headers_for_req = {}

      unless @headers.empty?
        # if the headers are not empty
        final_headers_for_req = final_headers_for_req.merge(@headers)
      end

      final_headers_for_req = final_headers_for_req.merge(headers) if headers

      unless Constants::NO_AUTH.include?(requrl)
        final_headers_for_req = final_headers_for_req.merge({
                                                              Constants::KMD_AUTH_HEADER => @kmd_token
                                                            })
      end

      unless Constants::UNVERSIONED_PATHS.include?(requrl)
        # requrl should be versioned appropriately
        requrl = API_VERSION + requrl
      end

      uri = URI(@kmd_address + requrl)

      uri.query = URI.encode_www_form(params) if params

      begin
        request = self.class.build_req(method, uri, data.to_json, final_headers_for_req)
      rescue StandardError
        raise AlgoSDK::Errors::AlgodRequestError, @kmd_address + requrl
      end

      request
    end

    def versions(**kwargs)
      req = '/versions'
      JSON.parse(kmd_request('GET', req, **kwargs).body)['versions']
    end

    def generate_key(wallet_handle_token, _display_mnemonic = true, **kwargs)
      # TODO : test
      req = '/key'
      final_kwargs = build_kwargs('data',
                                  { 'wallet_handle_token' => wallet_handle_token }, kwargs)
      kmd_request('POST', req, **final_kwargs)
    end

    def delete_key(address, wallet_handle_token, wallet_password, **kwargs)
      # TODO : test
      req = '/key'

      final_kwargs = build_kwargs('data',
                                  { 'address' => address, 'wallet_handle_token' => wallet_handle_token,
                                    'wallet_password' => wallet_password }, kwargs)

      response = kmd_request('DELETE', req, **final_kwargs)

      response == {}
    end

    def export_key(address, wallet_handle_token, wallet_password, **kwargs)
      '''Export the secret key associated with the passed public key.'''
      req = '/key/export'
      final_kwargs = build_kwargs('data',
                                  { 'address' => address, 'wallet_handle_token' => wallet_handle_token,
                                    'wallet_password' => wallet_password }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def import_key(private_key, wallet_handle_token, **kwargs)
      '''Import an account into the wallet.'''

      req = '/key/import'

      final_kwargs = build_kwargs('data',
                                  { 'private_key' => private_key, 'wallet_handle_token' => wallet_handle_token }, kwargs)
      kmd_request('POST', req, **final_kwargs)
    end

    def list_keys(wallet_handle_token, **kwargs)
      '''Lists all of the public keys in this wallet.'''
      req = '/key/list'

      final_kwargs = build_kwargs('data',
                                  { 'wallet_handle_token' => wallet_handle_token }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def export_master_key(wallet_handle_token, wallet_password, **kwargs)
      ''"Get the wallet's master derivation key."''

      req = '/master-key/export'

      final_kwargs = build_kwargs('data',
                                  { 'wallet_handle_token' => wallet_handle_token, 'wallet_password' => wallet_password }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def delete_multisig_preimage_information(address, wallet_handle_token, wallet_password, **kwargs)
      '''Deletes multisig preimage information for the passed address from the wallet.'''
      req = '/multisig'

      final_kwargs = build_kwargs('data',
                                  { 'address' => address, 'wallet_handle_token' => wallet_handle_token,
                                    'wallet_password' => wallet_password }, kwargs)

      kmd_request('DELETE', req, **final_kwargs)
    end

    def export_multisig_preimage_information(address, wallet_handle_token, **kwargs)
      '''
        Given a multisig address whose preimage this wallet stores, returns
        the information used to generate the address, including public keys,
        threshold, and multisig version.
      '''
      req = '/multisig/export'

      final_kwargs = build_kwargs('data',
                                  { 'address' => address, 'wallet_handle_token' => wallet_handle_token }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def import_multisig_preimage_information(multisig_version, public_key_arr, threshold, _wallet_handle_token, **kwargs)
      '''
        Given a multisig address whose preimage this wallet stores, returns
        the information used to generate the address, including public keys,
        threshold, and multisig version.
      '''
      req = '/multisig/import'

      final_kwargs = build_kwargs('data',
                                  { 'multisig_version' => multisig_version, 'pks' => public_key_arr,
                                    'threshold' => threshold, 'wallet_handle_token' => wallet_handle_token }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def list_multisig_accounts(wallet_handle_token, **kwargs)
      '''Lists all of the multisig accounts whose preimages this wallet stores'''

      req = '/multisig/list'

      final_kwargs = build_kwargs('data', { 'wallet_handle_token' => wallet_handle_token }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def sign_multisig(_wallet_handle_token, _wallet_password, _public_key, _transaction)
      '''Sign a multisig transaction.'''
      req = '/multisig/sign'

      # TODO: yikes

      # build_kwargs('data', { '' => '', '' => '', '' => '' })
    end

    def sign_multisig_txn
      # TODO:
      req = 'multisig/signprogram'
    end

    def sign_txn
      # TODO
      req = '/transaction/sign'
    end

    def create_wallet(name, password, driver_name = 'sqlite', master_derivation_key = nil, **kwargs)
      req = '/wallet'

      final_kwargs = build_kwargs('data',
                                  { 'wallet_driver_name' => driver_name, 'wallet_name' => name, 'wallet_password' => password }, kwargs)

      !master_derivation_key.nil? ? final_kwargs.merge({ 'master_derivation_key' => master_derivation_key }) : nil

      p final_kwargs

      kmd_request('POST', req, **final_kwargs)
    end

    def get_wallet(**kwargs)
      req = '/wallets'

      kmd_request('GET', req, **kwargs)
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

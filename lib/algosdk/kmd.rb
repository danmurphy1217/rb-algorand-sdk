require_relative 'utils/constants'
require_relative 'error'

require 'base64'
require 'net/http'
require 'json'

API_VERSION = '/v1'

module AlgoSDK
  class KmdClient
    attr_reader :kmd_token, :kmd_address, :headers

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

    def generate_key(wallet_handle_token, display_mnemonic = true, **kwargs)
      # TODO : test
      req = '/key'
      final_kwargs = build_kwargs('data',
                                  { 'wallet_handle_token' => wallet_handle_token, 'display_mnemonic' => display_mnemonic }, kwargs)
      kmd_request('POST', req, **final_kwargs)
    end

    def delete_key(address, wallet_handle_token, wallet_password, **kwargs)
      # TODO : test
      req = '/key'

      final_kwargs = build_kwargs('data',
                                  { 'address' => address, 'wallet_handle_token' => wallet_handle_token,
                                    'wallet_password' => wallet_password }, kwargs)

      response = kmd_request('DELETE', req, **final_kwargs)

      JSON.parse(response) == {}
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

      response = kmd_request('DELETE', req, **final_kwargs)

      JSON.parse(response) == {}
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

    def import_multisig_preimage_information(multisig_version, public_key_arr, threshold, wallet_handle_token, **kwargs)
      '''
        Given a multisig address whose preimage this wallet stores, returns
        the information used to generate the address, including public keys,
        threshold, and multisig version.
      '''
      # TODO: I think I need to encode wallet addr to get the public key
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
      AlgoSDK::Wallet.new(@kmd_token, @kmd_address, @headers, kwargs, name: name, password: password, driver_name: driver_name,
                                                                      master_derivation_key: master_derivation_key)
    end

    def get_wallets(**kwargs)
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

  class Wallet < KmdClient
    attr_reader :name, :password, :id

    def initialize(kmd_token, kmd_address, headers)
      super(kmd_token, kmd_address, headers)
      # TODO
    end

    def init(**kwargs)
      ''"
      Unlock the wallet and return a wallet handle token that can be used for subsequent
      operations. These tokens expire periodically and must be renewed.
      "''
      token = AlgoSDK::WalletHandleToken.new(@kmd_token, @kmd_address, @headers, kwargs, wallet_id: @id,
                                                                                         wallet_password: @password)
      @value = token.value

      @value
    end

    def create(wallet_name, password, driver_name, master_derivation_key,  **kwargs)
      req = '/wallet'
      final_kwargs = build_kwargs('data',
                                  { 'wallet_driver_name' => driver_name, 'wallet_name' => wallet_name, 'wallet_password' => password }, kwargs)

      !master_derivation_key.nil? ? final_kwargs.merge({ 'master_derivation_key' => master_derivation_key }) : nil

      response = kmd_request('POST', req, **final_kwargs)

      @name = wallet_name
      @password = password

      if JSON.parse(response)['error'].nil?
        p "Created Wallet #{@name}"
        @id = JSON.parse(response)['wallet']['id']
      else
        JSON.parse(response)
      end
    end

    def info(**kwargs)
      ''"
      Returns information about the wallet associated with the passed wallet handle token.
      Additionally returns expiration information about the token itself.
      "''
      req = '/wallet/info'
      final_kwargs = build_kwargs('data', { 'wallet_handle_token' => @value }, kwargs)

      kmd_request('POST', req, **final_kwargs)
    end

    def name=(new_name)
      req = '/wallet/rename'
      final_kwargs = build_kwargs('data',
                                  { 'wallet_id' => @id, 'wallet_name' => new_name,
                                    'wallet_password' => @password }, {})

      response = kmd_request('POST', req, **final_kwargs)

      if JSON.parse(response)["error"].nil?
        @name = new_name
        @name
      else
        JSON.parse(response)
      end
    end
  end

  class WalletHandleToken < KmdClient
    attr_reader :value

    def initialize(kmd_token, kmd_address, headers, kwargs, **req_data)
      super(kmd_token, kmd_address, headers)
      req = '/wallet/init'
      final_kwargs = build_kwargs('data', req_data, kwargs)

      p JSON.parse(kmd_request('POST', req, **final_kwargs))
      @value = JSON.parse(kmd_request('POST', req, **final_kwargs))['wallet_handle_token']
    end

    def invalidate
      req = '/wallet/release'
      final_kwargs = build_kwargs('data', { 'wallet_handle_token' => @value }, {})
      response = kmd_request('POST', req, **final_kwargs)

      if JSON.parse(response).empty?
        "Released Token #{value}"
      else
        response
      end
    end

    def renew
      req = '/wallet/renew'
      final_kwargs = build_kwargs('data', { 'wallet_handle_token' => @value }, {})
      response = kmd_request('POST', req, **final_kwargs)

      if JSON.parse(response)['wallet_handle']['expires_seconds'] == 59
        "Renewed Token #{@value}"
      else
        JSON.parse(response)
      end
    end
  end
end

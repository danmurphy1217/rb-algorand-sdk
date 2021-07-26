require "rbnacl"
require "base64"
require "openssl"
require_relative "utils/constants"
require_relative "encoding"

def generate_account()
  # Generate an account.
  # Returns [(str, str)]: the private key and account address.

  signing_key = RbNaCl::Signatures::Ed25519::SigningKey.generate
  verify_key = signing_key.verify_key
  address = checksum(verify_key.to_bytes)
  encoded_address = Base64.encode64(address)
  private_key = Base64.encode64(verify_key.to_bytes + signing_key.to_bytes)
  # TODO: use private key to compute address
  #! https://github.com/algorand/py-algorand-sdk/blob/develop/algosdk/account.py
  p encoded_address, private_key
end

def address_from_pk(pk)
  # pk: (str) private key
  # given the private key, derive the public address
  private_key = Base64.decode64(pk)[0...Constants::KEY_LEN_BYTES]
  address = checksum(private_key)
  p Base64.encode64(address)
end

account_data = generate_account()
addr = account_data.shift
pk = account_data.shift
address_from_pk(pk)

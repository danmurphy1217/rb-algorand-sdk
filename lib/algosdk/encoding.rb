# typed: true
require_relative "utils/constants"

def checksum(addr)
  "" "
    Compute the checksum of size checkSumLenBytes for the address.
    addr (bytes): address in bytes
    Returns => bytes: checksum of the address
    " ""
  digested_chksum = Digest::SHA512.digest(addr)
  return digested_chksum[-32...]
end

def msgpack_encode(obj)
  "" "
  Encode the object using canonical msgpack.
  Args:
      obj (Transaction, SignedTransaction, MultisigTransaction, Multisig,\
          Bid, or SignedBid): object to be encoded
  Returns:
      str: msgpack encoded object
  Note:
      Canonical Msgpack: maps must contain keys in lexicographic order; maps
      must omit key-value pairs where the value is a zero-value; positive
      integer values must be encoded as 'unsigned' in msgpack, regardless of
      whether the value space is semantically signed or unsigned; integer
      values must be represented in the shortest possible encoding; binary
      arrays must be represented using the 'bin' format family (that is, use
      the most recent version of msgpack rather than the older msgpack
      version that had no 'bin' family).
  " ""
  if not obj.is_a?(Hash)
    #TODO: d = obj.hashify(), each txn should have hasify method
  end
  # od = _sort_dict(d)
  # base64.b64encode(msgpack.packb(od, use_bin_type = True)).decode()
  Base64.encode64(obj)
end

def decode_address(address)
  "" "
  Decode a string address into its address bytes and checksum.
  Args:
      addr (str): base32 address
  Returns:
      bytes: address decoded into bytes
  " ""
  if not address
    return addr
  end
  if not address.length == Constants::ADDRESS_LEN
    raise AlgoSDK::Error::WrongKeyLengthError.new("Incorrect public key provide: length must be #{Constants::ADDRESS_LEN}")
  end
  # TODO: decode address
end

def encode_address(address_bytes)
end

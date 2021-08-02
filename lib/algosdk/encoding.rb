# typed: true
require_relative "utils/constants"
require "activesupport"
require "msgpack"

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
  hashed_obj = obj
  if not hashed_obj.is_a?(Hash)
    hashed_obj = obj.hashify()
  end

  ordered_hash = order_hash(hashed_obj)
  Base64.encode64(MessagePack.pack(ordered_hash))
end

def order_hash(hash)
  "" "
  Sorts a dictionary recursively, while also removing null values

  Args:
    hash (Hash): Hash to be sorted

    Returns:
        OrderedDict: sorted dictionary with no zero values
  " ""
  ordered_hash = ActiveSupport::OrderedHash.new
  sorted_keys = hash.keys.sort
  sorted_keys.each do |key|
    if hash[key].instance_of?(Hash)
      ordered_hash[key] = order_hash(hash[key])
    elsif hash[key]
      ordered_hash[key]
    end

    ordered_hash
  end
end

# TODO: fix this up once txn classes are setup
# def future_msgpack_decode(enc)
#   "" "
#   Decode a msgpack encoded object from a string.
#   Args:
#       enc (str): string to be decoded
#   Returns:
#       Transaction, SignedTransaction, Multisig, Bid, or SignedBid:\
#           decoded object
#   " ""
#   decoded = enc
#   if not isinstance(enc, dict)
#       decoded = MessagePack.unpack(Base64.decode64(enc))
#   end
#   if "type" in decoded
#       future.transaction.Transaction.undictify(decoded)
#   end
#   if "l" in decoded
#       future.transaction.LogicSig.undictify(decoded)
#   end
#   if "msig" in decoded
#       return future.transaction.MultisigTransaction.undictify(decoded)
#   end
#   if "lsig" in decoded
#       if "txn" in decoded
#           future.transaction.LogicSigTransaction.undictify(decoded)
#       end
#       future.transaction.LogicSigAccount.undictify(decoded)
#     end
#   if "sig" in decoded
#       future.transaction.SignedTransaction.undictify(decoded)
#   end
#   if "txn" in decoded
#       future.transaction.Transaction.undictify(decoded["txn"])
#   end
#   if "subsig" in decoded
#       future.transaction.Multisig.undictify(decoded)
#   end
#   if "txlist" in decoded
#       future.transaction.TxGroup.undictify(decoded)
#   end
#   if "t" in decoded
#       auction.NoteField.undictify(decoded)
#   end
#   if "bid" in decoded
#       auction.SignedBid.undictify(decoded)
#   end
#   if "auc" in decoded
#       auction.Bid.undictify(decoded)
#   end
# end

def is_valid_address(addr)
  "" "
  Check if the string address is a valid Algorand address.
  Args:
      addr (str): base32 address
  Returns:
      bool: whether or not the address is valid
  " ""
  #TODO!
  # if not addr.is_a?(String)
  #     return false
  # end
  # if not len(_undo_padding(addr)) == constants.address_len:
  #     return False
  # try:
  #     decoded = decode_address(addr)
  #     if isinstance(decoded, str):
  #         return False
  #     return True
  # except:
  #     return False
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

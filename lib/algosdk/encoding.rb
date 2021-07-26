def checksum(addr)
  "" "
    Compute the checksum of size checkSumLenBytes for the address.
    addr (bytes): address in bytes
    Returns => bytes: checksum of the address
    " ""
  digested_chksum = Digest::SHA512.digest(addr)
  return digested_chksum[-32...]
end

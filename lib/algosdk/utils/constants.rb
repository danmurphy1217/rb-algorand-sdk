# typed: true
module Constants
  "" "int: how long addresses are in bytes" ""
  KEY_LEN_BYTES = 32
  ADDRESS_LEN = 58
  NO_AUTH = []
  ALGOD_AUTH_HEADER = "X-Algo-API-Token"
  KMD_AUTH_HEADER = "X-KMD-API-Token"
  UNVERSIONED_PATHS = ["/health", "/versions", "/metrics", "/genesis", "/swagger.json"]
end

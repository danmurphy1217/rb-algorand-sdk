# typed: true
module Constants
  "" "int: how long addresses are in bytes" ""
  KEY_LEN_BYTES = 32
  NO_AUTH = []
  ALGOD_AUTH_HEADER = "X-Algo-API-Token"
  UNVERSIONED_PATHS = ["/health", "/versions", "/metrics", "/genesis"]
end

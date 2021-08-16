require_relative 'algosdk/encoding'
require_relative 'algosdk/algod'

@algo = AlgoSDK::AlgodClient.new("1e506580e964a022db4a5eb64e561240718afa6bd65e9ef1d5a2f72fe62f3775", "http://127.0.0.1:8080", { :hi => "This is message" })
p @algo.shutdown().body
# 302065124

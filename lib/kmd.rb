require_relative 'algosdk/kmd'

@kmd = AlgoSDK::KmdClient.new(
  'c7e8d0791b7523b27a42f508027f2071fc6bbead17efae85ed7f4d7627093c81',
  'http://127.0.0.1:7833',
  { hi: 'This is message' }
)
wallet_id = 'c25f8ae3e88e4d6a29e1ea8cd313ce1d'
wallet_addr = "7STTRKA6L3LCI7BQI4RTTBP2A3UUIJ3KXZCS4CRDWM4ONAQVL6RKYPCYKA"
password = 'DPM#1217'
private_key = 'XUgELkWKpUddBf0g9evsbysutT275EFH5rr3WLTKuxX8pzioHl7WJHwwRyM5hfoG6UQnar5FLgojszjmghVfog=='
master_derivation_key = 'vkXrwVQiIi1vKgRWt57lFoJZWiLXX5SPD0ND6bw5mSc'

# @wallet = @kmd.create_wallet("asdsdfdsadfagf dfad", "123")

@wallet = AlgoSDK::Wallet.new(@kmd.kmd_token, @kmd.kmd_address, @kmd.headers)
p @wallet.create("asdfasdgag dfad", "123", "sqlite", nil)
p @wallet.init
p @wallet.info
@wallet.name = "HELLO jsdnfljasdfbnl IS A NEW NAME"
p @wallet.info
# wallet_info = @kmd.get_wallet(wallet_handle_token.value)
# p wallet_info
# renamed_wallet = @kmd.rename_wallet(wallet_id, 'THIS IS MY NEW NAME', password)
# p renamed_wallet
# p @kmd.get_wallet(wallet_handle_token.value)
# wallet_handle_token.renew

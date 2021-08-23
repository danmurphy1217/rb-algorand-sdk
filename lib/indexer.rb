require_relative 'algosdk/indexer'

@indexer = AlgoSDK::IndexerClient.new("", "https://algoexplorerapi.io/idx2", headers = { 'User-Agent': "DanM" })
# p @indexer.search_accounts(asset_id: 163650, limit: 10)
# p @indexer.get_account("MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4")
# p @indexer.get_account_txns("MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4", note_prefix: "purchase;01FDMNDA1G0PT5KMZAV21K9QKP")
# p @indexer.search_applications(application_id: 309161643, limit: 10)
# p @indexer.get_application(309161643)
# p @indexer.search_assets(asset_id: 312769)
# p @indexer.get_asset(312769)
# p @indexer.search_accounts_with_asset(312769, limit: 10)
# p @indexer.search_asset_txns(312769, limit: 10, sig_type: "sig")
# p @indexer.get_block(15778131)["transactions"].length
# p @indexer.search_txns(address: "MXIGC5RCUFNFV2TB7ODAGQ4H7VC75DCH2SBBG7ATWPLB4YHBO7FFPNVLJ4")
p @indexer.get_txn("VR62N7NLKWQSROKGWMKYXJXU3TYC46YJCKRE3CAWWUIYSQHUBDMQ")
# p @indexer.health()

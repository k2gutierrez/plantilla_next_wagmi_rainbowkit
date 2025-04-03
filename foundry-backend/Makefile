-include .env

.PHONY:; all test deploy

build :; forge build

test :; forge test

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit

deploy-sepolia :
	@forge script script/DeployCava.s.sol:DeployCava --rpc-url $(SEPOLIA_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-curtis :
	@forge script script/DeployCava.s.sol:DeployCava --rpc-url $(CURTIS_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(APESCAN_API_KEY) -vvvv

deploy-ape :
	@forge script script/DeployCava.s.sol:DeployCava --rpc-url $(APECHAIN_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(APESCAN_API_KEY) -vvvv

sepolia-json :; forge verify-contract $(CAVA_CONTRACT_ADDRESS) src/Cava.sol:Cava --etherscan-api-key $(ETHERSCAN_API_KEY) --rpc-url $(SEPOLIA_RPC_URL) --show-standard-json-input > json.json

curtis-json :; forge verify-contract $(CAVA_CONTRACT_ADDRESS) src/Cava.sol:Cava --etherscan-api-key $(APESCAN_API_KEY) --rpc-url $(CURTIS_RPC_URL) --show-standard-json-input > json.json

coverage-report :; forge coverage --report debug > coverage.txt

coverage :; forge coverage
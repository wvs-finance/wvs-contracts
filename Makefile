-include .env
export

build-login:
	forge build  src/login/*

test-login:
	forge test --match-path "test/login/*"

deploy-login:
	forge script script/login/*




start-reactive-local:
	anvil --fork-url $(REACTIVE_RPC_ENDPOINT) --chain-id 1597 --port 8545

test-reactive:
	forge test --fork-url http://localhost:8545 -vvvv

start-unichain-local:
	anvil --fork-url $(UNICHAIN_RPC_ENDPOINT) --chain-id 130 --port 8546

deploy-login-reactive:
	forge script script/login/Deploy.s.sol:DeployReactive --sig "deploy()" --private-key $(PRIVATE_KEY) --rpc-url $(LASNA_RPC_ENDPOINT) --broadcast

deploy-login-sepolia:
	forge script script/login/Deploy.s.sol:DeployNonReactive --sig "deploy()" --private-key $(PRIVATE_KEY) --rpc-url $(SEPOLIA_RPC_ENDPOINT) --broadcast

pay-socket-server:
	cast send --rpc-url $(LASNA_RPC_ENDPOINT) --private-key $(PRIVATE_KEY) $(SOCKET_SERVER) "coverDebt()"

pay-socket:
	cast send --rpc-url $(LASNA_RPC_ENDPOINT) --private-key $(PRIVATE_KEY) $CONTRACT_ADDR "coverDebt()"

pay-destination:
	cast send --rpc-url $(SEPOLIA_RPC_ENDPOINT) --private-key $REACTIVE_PRIVATE_KEY $CONTRACT_ADDR "coverDebt()"

login:
	forge script script/login/Login.s.sol:Login --broadcast --sig "login()" --private-key $(PRIVATE_KEY) --rpc-url $(LASNA_RPC_ENDPOINT)
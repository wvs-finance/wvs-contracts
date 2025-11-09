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

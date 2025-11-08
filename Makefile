
build-login:
	forge build  src/login/*

test-login:
	forge test --match-path "test/login/*"

deploy-login:
	forge script script/login/*

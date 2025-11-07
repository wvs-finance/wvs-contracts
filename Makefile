
build-login:
	forge build regexOn(src, test, script)/login/*

test-login:
	forge test --match-path test/login/*

deploy-login:
	forge script script/login/*

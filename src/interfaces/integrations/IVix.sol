
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;



interface IVix{
    
    // TODO: From now is this. But the interface actually hides params that are noisy or our implementation

    // NOTE: Notice the derive token is the same as the underlying pool address from where the instrument is being created ...
    // Taken from Vix.t.sol:56
    //   -->(address[2] memory ivTokenAddresses) = hook.deploy2Currency(poolAdd,["HIGH-IV-BTC","LOW-IV-BTC"],["HIVB","LIVB"],poolAdd);
        
    function deploy2Currency(
        address deriveToken,
        string[2] memory _tokenName,
        string[2] memory _tokenSymbol,
        address _poolAddress 
    ) public returns(address[2] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// import {EnumerableMap}


interface IHedgeQuoter{
    
    
    enum Status{
        ACTIVE;
        SETTLED;
        CANCELLED;
    }

    struct Hedge{
       uint256 notional;
        uint48 createdAt;
        uint48 maturity;
        address strategy;
        Status status;
    }


}

abstract contract HedgeQuoterBase{
    // NOTE: The strategies are identified as token id's on ERC1155 
    // Then probalyb there is no need to store them on a EnumerableMap

    // The owner of those tokens is ??


}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;


enum HedgeType{
    OPTION,
    VARIANCE_SWAP
}


struct HedgeConfig{
    address underlying;
    uint48 expiration;
    address collateral;
    bytes custom_data;
}

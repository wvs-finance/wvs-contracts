// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC1155Receiver} from "Compose/src/token/ERC1155/ERC1155Facet.sol";

import "../../types/Shared.sol";

interface IAdapter{
    function create_hedge(HedgeConfig calldata _hedge_config) external;

}

abstract contract BaseAdapter is IAdapter, IERC1155Receiver{
    // struct AdapterBaseStorage{

    // }
}
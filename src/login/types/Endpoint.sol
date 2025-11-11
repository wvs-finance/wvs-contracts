// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


struct Endpoint{
    bytes4[] selectors;
    // bytes data;
}

using EndpointLib for Endpoint global;

library EndpointLib{
    function __init__() internal pure returns(Endpoint memory _endpoint){
        _endpoint = Endpoint({
            selectors: new bytes4[](uint256(0x00))
            // data : new bytes(uint256(0x00))
        });
    }


    function add(
        Endpoint memory _endpoint,
        bytes4 _event_selector
        // bytes memory _data 
    ) internal pure returns(Endpoint memory endpoint){
        bytes4[] memory selectors = new bytes4[](_endpoint.selectors.length + uint256(0x01));
        // bytes memory data = new bytes(_endpoint.data.length + uint256(0x01));

        for (uint256 index; index < _endpoint.selectors.length; index++){
            selectors[index] = _endpoint.selectors[index];
            // data[index] = _endpoint.data[index];
        }

        selectors[_endpoint.selectors.length] = _event_selector;
        // data[data.length - uint256(0x01)] = _data;

        endpoint.selectors = selectors;
        // endpoint.data = data;
    }

    function has(
        Endpoint memory _endpoint,
        bytes4 _event_selector
    ) internal pure returns(bool){
        bool _found;
        for (uint256 index; index < _endpoint.selectors.length; index++){
            if (_endpoint.selectors[index] == _event_selector){
                _found = true;
                break;
            }
        }
        return _found;
    }

}
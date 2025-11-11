// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface  IMockOriginSimple{
    function state() external returns(uint256);
    function stimulus() external;
    function action() external;
}
contract MockOriginSimple{
    uint256 public _state;

    
    event Stimulus(uint256 indexed _state);

    function stimulus() external{
        emit Stimulus(_state);    
    }

    function action() external{
        _state++;
        emit Stimulus(_state);
    }

    function state() public returns(uint256){
        return _state;
    }
}
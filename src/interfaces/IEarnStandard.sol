// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEarnStandard {
    function execEarn(address _protocol, address _token, address _user, uint256 _amount) external returns (uint256);
    function withdrawEarn(address _protocol, address _token, address _user, uint256 _amount)
        external
        returns (uint256);
}

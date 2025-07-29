// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockVault {
    function deposit(address _token, uint256 _amount, address _user) external returns (uint256);
    function withdraw(address _token, uint256 _amount, address _user) external returns (uint256);
    function distributeReward(address _token, uint256 _amount) external;
}

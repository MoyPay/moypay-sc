// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockVault {
    function deposit(uint256 amount, address _user) external returns (uint256);
    function withdraw(uint256 amount, address _user) external returns (uint256);
}

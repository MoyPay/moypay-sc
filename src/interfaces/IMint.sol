// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMint {
    function mint(address to, uint256 amount) external;
}

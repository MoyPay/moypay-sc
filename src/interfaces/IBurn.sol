// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBurn {
    function burn(address from, uint256 amount) external;
}
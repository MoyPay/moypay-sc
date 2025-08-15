// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

contract MoyPayTestnet is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("core_testnet"));
    }
}

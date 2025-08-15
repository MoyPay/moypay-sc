// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperScript} from "./Helper.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMint} from "../src/interfaces/IMint.sol";

contract ShortcutFaucets is Script, HelperScript {
    // *** FILL THIS ***
    address public myWallet = vm.envAddress("ADDRESS");
    uint256 public amount = 100_000e18;
    // *****************

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("core_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        // Mint USDC
        IMint(mockUSDC).mint(myWallet, amount);

        // Mint USDC
        IMint(mockUSDC).mint(myWallet, amount);

        // check balance
        console.log("balance", IERC20(mockUSDC).balanceOf(myWallet) / IERC20Metadata(mockUSDC).decimals(), "USDC");

        vm.stopBroadcast();
    }

    // RUN
    // forge script ShortcutFaucets --broadcast --verify -vvv
}

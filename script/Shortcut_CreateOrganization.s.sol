// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperScript} from "./Helper.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IFactory} from "../src/interfaces/IFactory.sol";

contract ShortcutCreateOrganization is Script, HelperScript {
    // *** FILL THIS ***
    address public myWallet = vm.envAddress("ADDRESS");
    string public organizationName = "TechCorp Demo";
    // *****************

    address public newOrganization;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("core_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Organization Creation & Setup ===");
        console.log("Wallet:", myWallet);
        console.log("Organization Name:", organizationName);
        console.log("");

        // Step 1: Create Organization
        _createOrganization();

        // Step 2: Check final status
        _checkStatus();

        vm.stopBroadcast();

        console.log("=== Organization Setup Complete ===");
        console.log("New Organization Address:", newOrganization);
        console.log("Save this address for use in other scripts!");
    }

    function _createOrganization() internal {
        console.log("2. Creating Organization...");
        newOrganization = IFactory(factory).createOrganization(mockUSDC, organizationName);
        console.log("Organization created at:", newOrganization);
        console.log("");
    }

    function _checkStatus() internal view {
        console.log("4. Status Check...");

        uint256 ownerBalance = IERC20(mockUSDC).balanceOf(myWallet);
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(newOrganization);

        console.log("Owner remaining balance:", ownerBalance / (10 ** IERC20Metadata(mockUSDC).decimals()), "USDC");
        console.log("Organization balance:", orgBalance / (10 ** IERC20Metadata(mockUSDC).decimals()), "USDC");
        console.log("");
    }

    // RUN
    // forge script ShortcutCreateOrganization --broadcast --verify -vvv
}

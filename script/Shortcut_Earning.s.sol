// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperScript} from "./Helper.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Organization} from "../src/Organization.sol";

contract ShortcutEarning is Script, HelperScript {
    // *** FILL THIS ***
    address public myWallet = vm.envAddress("ADDRESS");
    address public targetOrganization = 0x1bae6B168bE7DCf5D6872a408aA001Dd2bc8B7F5; // UPDATE THIS
    
    // Employee for testing earning (use actual employee address)
    address public testEmployee = 0x742d35Cc6466354BC3C18Cc5ed4A5322F5485bF0;
    
    uint256 public earnAmount = 2_000e6; // 2,000 USDC to earn
    uint256 public autoEarnAmount = 1_000e6; // 1,000 USDC for auto-earn
    // *****************

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Earning Functionality Demo ===");
        console.log("Organization:", targetOrganization);
        console.log("Test Employee:", testEmployee);
        console.log("");

        // Step 1: Check initial status
        _checkInitialStatus();

        // Step 2: Simulate time for salary accrual
        _simulateTimeForSalary();

        // Step 3: Demonstrate earning with different protocols
        _demonstrateEarning();

        // Step 4: Demonstrate auto-earn functionality
        _demonstrateAutoEarn();

        // Step 5: Demonstrate withdraw earn
        _demonstrateWithdrawEarn();

        // Step 6: Check final status
        _checkFinalStatus();

        vm.stopBroadcast();
        
        console.log("=== Earning Demo Complete ===");
    }

    function _checkInitialStatus() internal {
        console.log("1. Initial Status Check...");
        
        uint256 empBalance = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("Employee balance:", empBalance / 1e6, "USDC");
        console.log("Available salary:", availableSalary / 1e6, "USDC");
        console.log("");
    }

    function _simulateTimeForSalary() internal {
        console.log("2. Simulating Time for Salary Accrual...");
        
        // Simulate 20 days passing (about 2/3 of a month)
        vm.warp(block.timestamp + 20 days);
        
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary after 20 days:", availableSalary / 1e6, "USDC");
        console.log("");
    }

    function _demonstrateEarning() internal {
        console.log("3. Demonstrating Earning with Different Protocols...");
        
        // Earn with Morpho protocol
        console.log("Earning with Morpho...");
        vm.startPrank(testEmployee);
        uint256 morphoShares = Organization(targetOrganization).earn(testEmployee, mockVaultMorpho, earnAmount);
        vm.stopPrank();
        console.log("Morpho shares received:", morphoShares / 1e18);
        
        // Simulate more time passing
        vm.warp(block.timestamp + 5 days);
        
        // Earn with Compound protocol
        console.log("Earning with Compound...");
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary before Compound earn:", availableSalary / 1e6, "USDC");
        
        vm.startPrank(testEmployee);
        uint256 compoundShares = Organization(targetOrganization).earn(testEmployee, mockVaultCompound, earnAmount);
        vm.stopPrank();
        console.log("Compound shares received:", compoundShares / 1e18);
        
        // Earn with Aave protocol
        vm.warp(block.timestamp + 3 days);
        console.log("Earning with Aave...");
        
        vm.startPrank(testEmployee);
        uint256 aaveShares = Organization(targetOrganization).earn(testEmployee, mockVaultAave, earnAmount / 2); // Smaller amount
        vm.stopPrank();
        console.log("Aave shares received:", aaveShares / 1e18);
        console.log("");
    }

    function _demonstrateAutoEarn() internal {
        console.log("4. Demonstrating Auto-Earn Functionality...");
        
        // Enable auto-earn for Centuari protocol
        vm.startPrank(testEmployee);
        Organization(targetOrganization).enableAutoEarn(mockVaultCentuari, autoEarnAmount);
        vm.stopPrank();
        console.log("Auto-earn enabled for Centuari with", autoEarnAmount / 1e6, "USDC threshold");
        
        // Simulate time passing and trigger auto-earn
        vm.warp(block.timestamp + 7 days);
        
        uint256 availableBefore = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary before auto-earn:", availableBefore / 1e6, "USDC");
        
        // Trigger auto-earn (can be called by anyone)
        Organization(targetOrganization).autoEarn(testEmployee);
        console.log("Auto-earn triggered for employee");
        
        uint256 availableAfter = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary after auto-earn:", availableAfter / 1e6, "USDC");
        console.log("");
    }

    function _demonstrateWithdrawEarn() internal {
        console.log("5. Demonstrating Withdraw Earn...");
        
        uint256 empBalanceBefore = IERC20(mockUSDC).balanceOf(testEmployee);
        console.log("Employee balance before withdraw earn:", empBalanceBefore / 1e6, "USDC");
        
        // Withdraw some shares from Morpho
        uint256 sharesToWithdraw = 1000e18; // 1000 shares
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawEarn(testEmployee, mockVaultMorpho, sharesToWithdraw, false);
        vm.stopPrank();
        
        uint256 empBalanceAfter = IERC20(mockUSDC).balanceOf(testEmployee);
        console.log("Withdrew", sharesToWithdraw / 1e18, "shares from Morpho");
        console.log("Employee balance after withdraw earn:", empBalanceAfter / 1e6, "USDC");
        
        // Withdraw from Compound as well
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawEarn(testEmployee, mockVaultCompound, sharesToWithdraw / 2, false);
        vm.stopPrank();
        
        uint256 empBalanceFinal = IERC20(mockUSDC).balanceOf(testEmployee);
        console.log("Withdrew", (sharesToWithdraw / 2) / 1e18, "shares from Compound");
        console.log("Employee final balance:", empBalanceFinal / 1e6, "USDC");
        console.log("");
    }

    function _checkFinalStatus() internal {
        console.log("6. Final Status Check...");
        
        uint256 empBalance = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("Employee final balance:", empBalance / 1e6, "USDC");
        console.log("Employee available salary:", availableSalary / 1e6, "USDC");
        console.log("Organization balance:", orgBalance / 1e6, "USDC");
        console.log("");
    }

    // Function to earn with specific protocol and amount
    function earnWithProtocol(address _protocol, uint256 _amount) public {
        console.log("=== Custom Earn ===");
        console.log("Protocol:", _protocol);
        console.log("Amount:", _amount / 1e6, "USDC");
        
        vm.startPrank(testEmployee);
        uint256 shares = Organization(targetOrganization).earn(testEmployee, _protocol, _amount);
        vm.stopPrank();
        
        console.log("Shares received:", shares / 1e18);
    }

    // Function to withdraw earn from specific protocol
    function withdrawEarnFromProtocol(address _protocol, uint256 _shares, bool _isOfframp) public {
        console.log("=== Custom Withdraw Earn ===");
        console.log("Protocol:", _protocol);
        console.log("Shares:", _shares / 1e18);
        console.log("Offramp:", _isOfframp ? "Yes" : "No");
        
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawEarn(testEmployee, _protocol, _shares, _isOfframp);
        vm.stopPrank();
        
        console.log("Withdraw earn completed!");
    }

    // Function to enable auto-earn for specific protocol
    function enableAutoEarnForProtocol(address _protocol, uint256 _amount) public {
        console.log("=== Enable Auto Earn ===");
        console.log("Protocol:", _protocol);
        console.log("Amount:", _amount / 1e6, "USDC");
        
        vm.startPrank(testEmployee);
        Organization(targetOrganization).enableAutoEarn(_protocol, _amount);
        vm.stopPrank();
        
        console.log("Auto-earn enabled!");
    }

    // Function to disable auto-earn for specific protocol
    function disableAutoEarnForProtocol(address _protocol) public {
        console.log("=== Disable Auto Earn ===");
        console.log("Protocol:", _protocol);
        
        Organization(targetOrganization).disableAutoEarn(testEmployee, _protocol);
        
        console.log("Auto-earn disabled!");
    }

    // Function to manually trigger auto-earn
    function triggerAutoEarn() public {
        console.log("=== Trigger Auto Earn ===");
        
        uint256 availableBefore = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary before:", availableBefore / 1e6, "USDC");
        
        Organization(targetOrganization).autoEarn(testEmployee);
        
        uint256 availableAfter = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary after:", availableAfter / 1e6, "USDC");
        console.log("Auto-earn triggered!");
    }

    // RUN
    // forge script ShortcutEarning --broadcast --verify -vvv
    //
    // Custom earn:
    // forge script ShortcutEarning --sig "earnWithProtocol(address,uint256)" 0xdf2706AD5966ac71C9016b4a4F93c9054e48F54b 3000000000 --broadcast -vvv
    //
    // Custom withdraw earn:
    // forge script ShortcutEarning --sig "withdrawEarnFromProtocol(address,uint256,bool)" 0xdf2706AD5966ac71C9016b4a4F93c9054e48F54b 500000000000000000000 false --broadcast -vvv
    //
    // Enable auto-earn:
    // forge script ShortcutEarning --sig "enableAutoEarnForProtocol(address,uint256)" 0x797e0d9957ff4EeFa3330e809A10820ddC2937dc 1500000000 --broadcast -vvv
    //
    // Trigger auto-earn:
    // forge script ShortcutEarning --sig "triggerAutoEarn()" --broadcast -vvv
}
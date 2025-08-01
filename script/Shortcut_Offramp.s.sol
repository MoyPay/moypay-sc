// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperScript} from "./Helper.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Organization} from "../src/Organization.sol";
import {IMint} from "../src/interfaces/IMint.sol";

contract ShortcutOfframp is Script, HelperScript {
    // *** FILL THIS ***
    address public myWallet = vm.envAddress("ADDRESS");
    address public targetOrganization = 0x1bae6B168bE7DCf5D6872a408aA001Dd2bc8B7F5; // UPDATE THIS
    
    // Employee for testing offramp (use actual employee address)
    address public testEmployee = 0x742d35Cc6466354BC3C18Cc5ed4A5322F5485bF0;
    
    uint256 public offrampAmount1 = 500e6; // 500 USDC for regular offramp
    uint256 public offrampAmount2 = 1_000e6; // 1,000 USDC for withdrawAll offramp
    uint256 public earnAmount = 2_000e6; // 2,000 USDC to earn before offramp
    // *****************

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Offramp Functionality Demo ===");
        console.log("Organization:", targetOrganization);
        console.log("Test Employee:", testEmployee);
        console.log("");

        // Step 1: Check initial state and setup
        _checkInitialState();

        // Step 2: Simulate salary accrual
        _simulateSalaryAccrual();

        // Step 3: Demonstrate regular withdraw with offramp
        _demonstrateRegularOfframp();

        // Step 4: Demonstrate earning and then offramp withdraw earn
        _demonstrateEarnOfframp();

        // Step 5: Demonstrate withdrawAll with offramp
        _demonstrateWithdrawAllOfframp();

        // Step 6: Demonstrate organization owner offramp
        _demonstrateOwnerOfframp();

        // Step 7: Check final state
        _checkFinalState();

        vm.stopBroadcast();
        
        console.log("=== Offramp Demo Complete ===");
        console.log("All offramp operations burn tokens instead of transferring them");
    }

    function _checkInitialState() internal {
        console.log("1. Initial State Check...");
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        uint256 empBalance = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("USDC Total Supply:", totalSupplyBefore / 1e6, "USDC");
        console.log("Employee balance:", empBalance / 1e6, "USDC");
        console.log("Organization balance:", orgBalance / 1e6, "USDC");
        console.log("Employee available salary:", availableSalary / 1e6, "USDC");
        console.log("");
    }

    function _simulateSalaryAccrual() internal {
        console.log("2. Simulating Salary Accrual...");
        
        // Simulate 25 days passing for substantial salary accrual
        vm.warp(block.timestamp + 25 days);
        
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Available salary after 25 days:", availableSalary / 1e6, "USDC");
        console.log("");
    }

    function _demonstrateRegularOfframp() internal {
        console.log("3. Regular Withdraw with Offramp...");
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        uint256 empBalanceBefore = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 orgBalanceBefore = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("Before offramp:");
        console.log("- Total Supply:", totalSupplyBefore / 1e6, "USDC");
        console.log("- Employee balance:", empBalanceBefore / 1e6, "USDC");
        console.log("- Organization balance:", orgBalanceBefore / 1e6, "USDC");
        
        // Employee withdraws with offramp (tokens will be burned)
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdraw(offrampAmount1, true); // true = offramp
        vm.stopPrank();
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        uint256 empBalanceAfter = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 orgBalanceAfter = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("After offramp withdraw of", offrampAmount1 / 1e6, "USDC:");
        console.log("- Total Supply:", totalSupplyAfter / 1e6, "USDC", "(reduced by", (totalSupplyBefore - totalSupplyAfter) / 1e6, ")");
        console.log("- Employee balance:", empBalanceAfter / 1e6, "USDC", "(no change - tokens burned)");
        console.log("- Organization balance:", orgBalanceAfter / 1e6, "USDC");
        console.log("");
    }

    function _demonstrateEarnOfframp() internal {
        console.log("4. Earn and Offramp Withdraw Earn...");
        
        // First, employee earns with Morpho
        vm.startPrank(testEmployee);
        uint256 shares = Organization(targetOrganization).earn(testEmployee, mockVaultMorpho, earnAmount);
        vm.stopPrank();
        console.log("Employee earned", earnAmount / 1e6, "USDC with Morpho, received", shares / 1e18, "shares");
        
        // Simulate some yield generation time
        vm.warp(block.timestamp + 10 days);
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        uint256 orgBalanceBefore = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("Before earn offramp:");
        console.log("- Total Supply:", totalSupplyBefore / 1e6, "USDC");
        console.log("- Organization balance:", orgBalanceBefore / 1e6, "USDC");
        
        // Employee withdraws earn with offramp
        uint256 sharesToWithdraw = shares / 2; // Withdraw half
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawEarn(testEmployee, mockVaultMorpho, sharesToWithdraw, true); // true = offramp
        vm.stopPrank();
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        uint256 orgBalanceAfter = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("After earn offramp of", sharesToWithdraw / 1e18, "shares:");
        console.log("- Total Supply:", totalSupplyAfter / 1e6, "USDC", "(reduced by", (totalSupplyBefore - totalSupplyAfter) / 1e6, ")");
        console.log("- Organization balance:", orgBalanceAfter / 1e6, "USDC");
        console.log("");
    }

    function _demonstrateWithdrawAllOfframp() internal {
        console.log("5. WithdrawAll with Offramp...");
        
        // Simulate more time for additional salary accrual
        vm.warp(block.timestamp + 15 days);
        
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        uint256 empBalanceBefore = IERC20(mockUSDC).balanceOf(testEmployee);
        
        console.log("Available salary:", availableSalary / 1e6, "USDC");
        console.log("Before withdrawAll offramp:");
        console.log("- Total Supply:", totalSupplyBefore / 1e6, "USDC");
        console.log("- Employee balance:", empBalanceBefore / 1e6, "USDC");
        
        // Employee withdraws all with offramp
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawAll(true); // true = offramp
        vm.stopPrank();
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        uint256 empBalanceAfter = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 remainingSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("After withdrawAll offramp:");
        console.log("- Total Supply:", totalSupplyAfter / 1e6, "USDC", "(reduced by", (totalSupplyBefore - totalSupplyAfter) / 1e6, ")");
        console.log("- Employee balance:", empBalanceAfter / 1e6, "USDC", "(no change - tokens burned)");
        console.log("- Remaining salary:", remainingSalary / 1e6, "USDC", "(should be 0)");
        console.log("");
    }

    function _demonstrateOwnerOfframp() internal {
        console.log("6. Organization Owner Offramp...");
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        uint256 ownerBalanceBefore = IERC20(mockUSDC).balanceOf(myWallet);
        uint256 orgBalanceBefore = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("Before owner offramp:");
        console.log("- Total Supply:", totalSupplyBefore / 1e6, "USDC");
        console.log("- Owner balance:", ownerBalanceBefore / 1e6, "USDC");
        console.log("- Organization balance:", orgBalanceBefore / 1e6, "USDC");
        
        // Owner withdraws excess with offramp
        uint256 ownerOfframpAmount = 3_000e6; // 3,000 USDC
        Organization(targetOrganization).withdrawBalanceOrganization(ownerOfframpAmount, true); // true = offramp
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        uint256 ownerBalanceAfter = IERC20(mockUSDC).balanceOf(myWallet);
        uint256 orgBalanceAfter = IERC20(mockUSDC).balanceOf(targetOrganization);
        
        console.log("After owner offramp of", ownerOfframpAmount / 1e6, "USDC:");
        console.log("- Total Supply:", totalSupplyAfter / 1e6, "USDC", "(reduced by", (totalSupplyBefore - totalSupplyAfter) / 1e6, ")");
        console.log("- Owner balance:", ownerBalanceAfter / 1e6, "USDC", "(no change - tokens burned)");
        console.log("- Organization balance:", orgBalanceAfter / 1e6, "USDC");
        console.log("");
    }

    function _checkFinalState() internal {
        console.log("7. Final State Check...");
        
        uint256 totalSupply = IERC20(mockUSDC).totalSupply();
        uint256 empBalance = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        uint256 ownerBalance = IERC20(mockUSDC).balanceOf(myWallet);
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("Final USDC Total Supply:", totalSupply / 1e6, "USDC");
        console.log("Employee balance:", empBalance / 1e6, "USDC");
        console.log("Organization balance:", orgBalance / 1e6, "USDC");
        console.log("Owner balance:", ownerBalance / 1e6, "USDC");
        console.log("Employee available salary:", availableSalary / 1e6, "USDC");
        console.log("");
        
        console.log("Total tokens burned through offramp operations!");
    }

    // Function to demonstrate custom offramp withdrawal
    function customOfframpWithdraw(uint256 _amount) public {
        console.log("=== Custom Offramp Withdraw ===");
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        console.log("Amount to offramp:", _amount / 1e6, "USDC");
        console.log("Total Supply before:", totalSupplyBefore / 1e6, "USDC");
        
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdraw(_amount, true); // true = offramp
        vm.stopPrank();
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        console.log("Total Supply after:", totalSupplyAfter / 1e6, "USDC");
        console.log("Tokens burned:", (totalSupplyBefore - totalSupplyAfter) / 1e6, "USDC");
    }

    // Function to demonstrate custom offramp withdraw earn
    function customOfframpWithdrawEarn(address _protocol, uint256 _shares) public {
        console.log("=== Custom Offramp Withdraw Earn ===");
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        console.log("Protocol:", _protocol);
        console.log("Shares to withdraw:", _shares / 1e18);
        console.log("Total Supply before:", totalSupplyBefore / 1e6, "USDC");
        
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawEarn(testEmployee, _protocol, _shares, true); // true = offramp
        vm.stopPrank();
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        console.log("Total Supply after:", totalSupplyAfter / 1e6, "USDC");
        console.log("Tokens burned:", (totalSupplyBefore - totalSupplyAfter) / 1e6, "USDC");
    }

    // Function to demonstrate owner offramp
    function ownerOfframp(uint256 _amount) public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Owner Offramp ===");
        
        uint256 totalSupplyBefore = IERC20(mockUSDC).totalSupply();
        console.log("Amount to offramp:", _amount / 1e6, "USDC");
        console.log("Total Supply before:", totalSupplyBefore / 1e6, "USDC");
        
        Organization(targetOrganization).withdrawBalanceOrganization(_amount, true); // true = offramp
        
        uint256 totalSupplyAfter = IERC20(mockUSDC).totalSupply();
        console.log("Total Supply after:", totalSupplyAfter / 1e6, "USDC");
        console.log("Tokens burned:", (totalSupplyBefore - totalSupplyAfter) / 1e6, "USDC");
        
        vm.stopBroadcast();
    }

    // RUN
    // forge script ShortcutOfframp --broadcast --verify -vvv
    //
    // Custom offramp withdraw:
    // forge script ShortcutOfframp --sig "customOfframpWithdraw(uint256)" 800000000 --broadcast -vvv
    //
    // Custom offramp withdraw earn:
    // forge script ShortcutOfframp --sig "customOfframpWithdrawEarn(address,uint256)" 0xdf2706AD5966ac71C9016b4a4F93c9054e48F54b 500000000000000000000 --broadcast -vvv
    //
    // Owner offramp:
    // forge script ShortcutOfframp --sig "ownerOfframp(uint256)" 2000000000 --broadcast -vvv
}
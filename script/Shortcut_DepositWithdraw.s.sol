// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperScript} from "./Helper.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Organization} from "../src/Organization.sol";
import {IMint} from "../src/interfaces/IMint.sol";

contract ShortcutDepositWithdraw is Script, HelperScript {
    // *** FILL THIS ***
    address public myWallet = vm.envAddress("ADDRESS");
    address public targetOrganization = 0x1bae6B168bE7DCf5D6872a408aA001Dd2bc8B7F5; // UPDATE THIS
    
    // Employee for testing withdrawals (use actual employee address)
    address public testEmployee = 0x742d35Cc6466354BC3C18Cc5ed4A5322F5485bF0;
    
    uint256 public depositAmount = 25_000e6; // 25,000 USDC
    uint256 public withdrawAmount = 1_500e6; // 1,500 USDC
    // *****************

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Deposit & Withdraw Operations ===");
        console.log("Organization:", targetOrganization);
        console.log("Test Employee:", testEmployee);
        console.log("");

        // Step 1: Check initial balances
        _checkInitialBalances();

        // Step 2: Deposit more funds (as organization owner)
        _depositFunds();

        // Step 3: Simulate time passing for salary accrual
        _simulateTimeAndAccrual();

        // Step 4: Employee withdrawal operations
        _demonstrateWithdrawals();

        // Step 5: Organization owner withdrawal
        _demonstrateOwnerWithdrawal();

        vm.stopBroadcast();
        
        console.log("=== Deposit & Withdraw Operations Complete ===");
    }

    function _checkInitialBalances() internal {
        console.log("1. Initial Balance Check...");
        
        uint256 ownerBalance = IERC20(mockUSDC).balanceOf(myWallet);
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        uint256 empBalance = IERC20(mockUSDC).balanceOf(testEmployee);
        
        console.log("Owner balance:", ownerBalance / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Organization balance:", orgBalance / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Employee balance:", empBalance / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        
        // Check employee available salary
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Employee available salary:", availableSalary / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("");
    }

    function _depositFunds() internal {
        console.log("2. Depositing Additional Funds...");
        
        // Mint more USDC if needed
        uint256 currentBalance = IERC20(mockUSDC).balanceOf(myWallet);
        if (currentBalance < depositAmount) {
            uint256 mintAmount = depositAmount * 2;
            IMint(mockUSDC).mint(myWallet, mintAmount);
            console.log("Minted additional USDC:", mintAmount / 10 ** IERC20Metadata(mockUSDC).decimals());
        }
        
        // Approve and deposit
        IERC20(mockUSDC).approve(targetOrganization, depositAmount);
        Organization(targetOrganization).deposit(depositAmount);
        
        uint256 newOrgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        console.log("Deposited:", depositAmount / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("New organization balance:", newOrgBalance / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("");
    }

    function _simulateTimeAndAccrual() internal {
        console.log("3. Simulating Time Passage...");
        
        // Simulate 15 days passing (half a month)
        uint256 initialTimestamp = block.timestamp;
        vm.warp(block.timestamp + 15 days);
        
        console.log("Simulated 15 days passing");
        console.log("Time moved from:", initialTimestamp, "to:", block.timestamp);
        
        // Check new available salary
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        console.log("Employee available salary after 15 days:", availableSalary / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("");
    }

    function _demonstrateWithdrawals() internal {
        console.log("4. Employee Withdrawal Operations...");
        
        // Get current employee balance before withdrawal
        uint256 empBalanceBefore = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("Employee balance before withdrawal:", empBalanceBefore / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Available salary:", availableSalary / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        
        // Employee withdraws partial salary
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdraw(withdrawAmount, false); // Normal withdrawal
        vm.stopPrank();
        
        uint256 empBalanceAfter = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 remainingSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("Employee withdrew:", withdrawAmount / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Employee balance after withdrawal:", empBalanceAfter / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Remaining available salary:", remainingSalary / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("");
    }

    function _demonstrateOwnerWithdrawal() internal {
        console.log("5. Organization Owner Withdrawal...");
        
        uint256 orgBalanceBefore = IERC20(mockUSDC).balanceOf(targetOrganization);
        uint256 ownerBalanceBefore = IERC20(mockUSDC).balanceOf(myWallet);
        
        console.log("Organization balance before:", orgBalanceBefore / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Owner balance before:", ownerBalanceBefore / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        
        // Owner withdraws excess funds (5,000 USDC)
        uint256 ownerWithdrawAmount = 5_000e6;
        Organization(targetOrganization).withdrawBalanceOrganization(ownerWithdrawAmount, false);
        
        uint256 orgBalanceAfter = IERC20(mockUSDC).balanceOf(targetOrganization);
        uint256 ownerBalanceAfter = IERC20(mockUSDC).balanceOf(myWallet);
        
        console.log("Owner withdrew:", ownerWithdrawAmount / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Organization balance after:", orgBalanceAfter / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Owner balance after:", ownerBalanceAfter / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("");
    }

    // Function to demonstrate withdrawAll functionality
    function demonstrateWithdrawAll() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Withdraw All Demo ===");
        
        // Simulate more time passing
        vm.warp(block.timestamp + 10 days);
        
        uint256 availableSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        uint256 empBalanceBefore = IERC20(mockUSDC).balanceOf(testEmployee);
        
        console.log("Available salary:", availableSalary / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Employee balance before:", empBalanceBefore / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        
        // Employee withdraws all available salary
        vm.startPrank(testEmployee);
        Organization(targetOrganization).withdrawAll(false); // Normal withdrawAll
        vm.stopPrank();
        
        uint256 empBalanceAfter = IERC20(mockUSDC).balanceOf(testEmployee);
        uint256 remainingSalary = Organization(targetOrganization)._currentSalary(testEmployee);
        
        console.log("Employee balance after withdrawAll:", empBalanceAfter / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Remaining salary (should be 0):", remainingSalary / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        
        vm.stopBroadcast();
    }

    // Function for custom deposit
    function customDeposit(uint256 _amount) public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("Custom deposit amount:", _amount / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        
        // Mint if needed
        uint256 currentBalance = IERC20(mockUSDC).balanceOf(myWallet);
        if (currentBalance < _amount) {
            IMint(mockUSDC).mint(myWallet, _amount * 2);
        }
        
        IERC20(mockUSDC).approve(targetOrganization, _amount);
        Organization(targetOrganization).deposit(_amount);
        
        console.log("Deposit completed!");
        vm.stopBroadcast();
    }

    // Function for employee custom withdrawal
    function employeeCustomWithdraw(address _employee, uint256 _amount, bool _isOfframp) public {
        console.log("Employee withdrawal:", _employee);
        console.log("Amount:", _amount / 10 ** IERC20Metadata(mockUSDC).decimals(), "USDC");
        console.log("Offramp:", _isOfframp ? "Yes" : "No");
        
        vm.startPrank(_employee);
        Organization(targetOrganization).withdraw(_amount, _isOfframp);
        vm.stopPrank();
        
        console.log("Withdrawal completed!");
    }

    // RUN
    // forge script ShortcutDepositWithdraw --broadcast --verify -vvv
    //
    // Withdraw all demo:
    // forge script ShortcutDepositWithdraw --sig "demonstrateWithdrawAll()" --broadcast -vvv
    //
    // Custom deposit:
    // forge script ShortcutDepositWithdraw --sig "customDeposit(uint256)" 10000000000 --broadcast -vvv
    //
    // Custom employee withdraw:
    // forge script ShortcutDepositWithdraw --sig "employeeCustomWithdraw(address,uint256,bool)" 0x123... 2000000000 false --broadcast -vvv
}
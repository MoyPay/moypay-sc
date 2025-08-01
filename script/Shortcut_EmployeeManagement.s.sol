// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperScript} from "./Helper.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Organization} from "../src/Organization.sol";

contract ShortcutEmployeeManagement is Script, HelperScript {
    // *** FILL THIS ***
    address public myWallet = vm.envAddress("ADDRESS");
    address public targetOrganization = 0x1bae6B168bE7DCf5D6872a408aA001Dd2bc8B7F5; // UPDATE THIS

    // Employee addresses (update these with real addresses)
    address public employee1 = 0x742D35Cc6466354bc3c18cc5ED4a5322F5485Bf0;
    address public employee2 = 0x8ba1f109551BD432803012645EAc136c4DD26630;
    address public employee3 = 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF;

    // Salaries (monthly)
    uint256 public employee1Salary = 5_000e6; // 5,000 USDC/month - Senior Developer
    uint256 public employee2Salary = 3_000e6; // 3,000 USDC/month - Designer
    uint256 public employee3Salary = 4_000e6; // 4,000 USDC/month - Product Manager
    // *****************

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Employee Management ===");
        console.log("Organization:", targetOrganization);
        console.log("");

        // Check organization balance before adding employees
        _checkOrganizationBalance();

        // Add employees
        _addEmployees();

        // Check status after adding employees
        _checkEmployeeStatus();

        vm.stopBroadcast();

        console.log("=== Employee Management Complete ===");
    }

    function _checkOrganizationBalance() internal view {
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        console.log("Organization balance:", orgBalance / 1e6, "USDC");

        uint256 totalSalaries = employee1Salary + employee2Salary + employee3Salary;
        console.log("Total monthly salaries:", totalSalaries / 1e6, "USDC");

        if (orgBalance < totalSalaries) {
            console.log("WARNING: Organization balance is less than total salaries!");
            console.log("Consider depositing more funds first.");
        }
        console.log("");
    }

    function _addEmployees() internal {
        console.log("1. Adding Employees...");

        // Add Employee 1 - Alice (Senior Developer)
        Organization(targetOrganization).addEmployee(
            "Alice Developer",
            employee1,
            employee1Salary,
            block.timestamp,
            true // start immediately
        );
        console.log("Added Employee 1 (Alice):", employee1);
        console.log("Role: Senior Developer");
        console.log("Salary:", employee1Salary / 1e6, "USDC/month");
        console.log("");

        // Add Employee 2 - Bob (Designer)
        Organization(targetOrganization).addEmployee(
            "Bob Designer",
            employee2,
            employee2Salary,
            block.timestamp,
            true // start immediately
        );
        console.log("Added Employee 2 (Bob):", employee2);
        console.log("Role: UI/UX Designer");
        console.log("Salary:", employee2Salary / 1e6, "USDC/month");
        console.log("");

        // Add Employee 3 - Carol (Product Manager)
        Organization(targetOrganization).addEmployee(
            "Carol PM",
            employee3,
            employee3Salary,
            block.timestamp,
            true // start immediately
        );
        console.log("Added Employee 3 (Carol):", employee3);
        console.log("Role: Product Manager");
        console.log("Salary:", employee3Salary / 1e6, "USDC/month");
        console.log("");
    }

    function _checkEmployeeStatus() internal view {
        console.log("2. Employee Status Check...");

        // Check available salaries (should be 0 since just added)
        uint256 emp1Available = Organization(targetOrganization)._currentSalary(employee1);
        uint256 emp2Available = Organization(targetOrganization)._currentSalary(employee2);
        uint256 emp3Available = Organization(targetOrganization)._currentSalary(employee3);

        console.log("Employee 1 available salary:", emp1Available / 1e6, "USDC");
        console.log("Employee 2 available salary:", emp2Available / 1e6, "USDC");
        console.log("Employee 3 available salary:", emp3Available / 1e6, "USDC");

        // Check organization balance after adding employees
        uint256 orgBalance = IERC20(mockUSDC).balanceOf(targetOrganization);
        console.log("Organization balance after adding employees:", orgBalance / 1e6, "USDC");
        console.log("");
    }

    // Function to add a single employee with custom parameters
    function addCustomEmployee(string memory _name, address _employee, uint256 _salary, bool _startNow) public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("Adding custom employee:", _name);
        console.log("Address:", _employee);
        console.log("Salary:", _salary / 1e6, "USDC/month");

        Organization(targetOrganization).addEmployee(
            _name, _employee, _salary, _startNow ? block.timestamp : block.timestamp + 30 days, _startNow
        );

        console.log("Employee added successfully!");
        vm.stopBroadcast();
    }

    // Function to modify employee salary
    function modifyEmployeeSalary(address _employee, uint256 _newSalary, bool _startNow) public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("Modifying salary for employee:", _employee);
        console.log("New salary:", _newSalary / 1e6, "USDC/month");

        Organization(targetOrganization).setEmployeeSalary(
            _employee, _newSalary, _startNow ? block.timestamp : block.timestamp + 30 days, _startNow
        );

        console.log("Salary updated successfully!");
        vm.stopBroadcast();
    }

    // Function to set employee status (active/inactive)
    function setEmployeeStatus(address _employee, bool _status) public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("Setting employee status:", _employee);
        console.log("New status:", _status ? "Active" : "Inactive");

        Organization(targetOrganization).setEmployeeStatus(_employee, _status);

        console.log("Employee status updated!");
        vm.stopBroadcast();
    }

    // RUN
    // forge script ShortcutEmployeeManagement --broadcast --verify -vvv
    //
    // Add custom employee:
    // forge script ShortcutEmployeeManagement --sig "addCustomEmployee(string,address,uint256,bool)" "John Dev" 0x123... 6000000000 true --broadcast -vvv
    //
    // Modify salary:
    // forge script ShortcutEmployeeManagement --sig "modifyEmployeeSalary(address,uint256,bool)" 0x123... 7000000000 true --broadcast -vvv
    //
    // Set status:
    // forge script ShortcutEmployeeManagement --sig "setEmployeeStatus(address,bool)" 0x123... false --broadcast -vvv
}

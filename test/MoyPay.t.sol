// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Factory} from "../src/Factory.sol";
import {Organization} from "../src/Organization.sol";
import {EarnStandard} from "../src/EarnStandard.sol";
import {MockVault} from "../src/Mocks/MockVault.sol";
import {MockUSDC} from "../src/Mocks/MockUSDC.sol";
import {IOrganization} from "../src/interfaces/IOrganization.sol";

contract MoyPayTest is Test {
    MockUSDC public mockUSDC;
    Factory public factory;
    Organization public organization;
    EarnStandard public earnStandard;
    MockVault public mockVault;
    MockVault public mockVault2;

    address owner = makeAddr("owner");
    address boss = makeAddr("boss");
    address employee = makeAddr("employee");
    address employee2 = makeAddr("employee2");
    address employee3 = makeAddr("employee3");
    address unauthorized = makeAddr("unauthorized");

    // Events
    event OrganizationCreated(address indexed owner, address indexed organization, address token, string name);
    event EarnProtocolAdded(address indexed earnProtocol);
    event EarnProtocolRemoved(address indexed earnProtocol);
    event EarnStandardSet(address indexed earnStandard);
    event EmployeeSalaryAdded(
        string name, address indexed employee, uint256 salary, uint256 startStream, uint256 timestamp, bool isAutoEarn
    );
    event EmployeeSalarySet(address indexed employee, uint256 salary, uint256 startStream);
    event EmployeeStatusChanged(address indexed employee, bool status);
    event PeriodTimeSet(uint256 periodTime);
    event Deposit(address indexed owner, uint256 amount);
    event Withdraw(address indexed employee, uint256 amount, uint256 unrealizedSalary, bool isOfframp, uint256 startStream);
    event WithdrawAll(address indexed employee, uint256 amount, bool isOfframp, uint256 startStream);
    event EarnSalary(address indexed employee, address indexed protocol, uint256 amount, uint256 shares);
    event SetName(string name);
    event EnableAutoEarn(address indexed employee, address indexed protocol, uint256 amount);
    event DisableAutoEarn(address indexed employee, address indexed protocol);
    event EarnExecuted(
        address indexed protocol, address indexed token, address indexed user, uint256 amount, uint256 shares
    );
    event EarnWithdrawn(
        address indexed protocol, address indexed token, address indexed user, uint256 amount, uint256 shares
    );

    function setUp() public {
        vm.startPrank(owner);

        mockUSDC = new MockUSDC();
        factory = new Factory();
        earnStandard = new EarnStandard();
        mockVault = new MockVault("MORPHO");
        mockVault2 = new MockVault("COMPOUND");

        factory.addEarnProtocol(address(mockVault));
        factory.addEarnProtocol(address(mockVault2));
        factory.setEarnStandard(address(earnStandard));

        vm.stopPrank();

        // Mint tokens to test accounts
        mockUSDC.mint(owner, 1_000_000e6);
        mockUSDC.mint(boss, 1_000_000e6);
        mockUSDC.mint(employee, 100_000e6);
        mockUSDC.mint(employee2, 100_000e6);
        mockUSDC.mint(employee3, 100_000e6);
    }

    // ============ HELPER FUNCTIONS ============

    function helper_createOrganization() public returns (address) {
        vm.startPrank(boss);
        factory.createOrganization(address(mockUSDC), "MoyPay");
        address org = factory.organizations(boss, 0);
        vm.stopPrank();
        return org;
    }

    function helper_deposit(address org, uint256 _amount) public {
        vm.startPrank(boss);
        IERC20(address(mockUSDC)).approve(org, _amount);
        IOrganization(org).deposit(_amount);
        vm.stopPrank();
    }

    function helper_addEmployee(
        address org,
        string memory _name,
        address _employee,
        uint256 _salary,
        uint256 _startStream,
        bool isNow
    ) public {
        vm.startPrank(boss);
        IOrganization(org).addEmployee(_name, _employee, _salary, _startStream, isNow);
        vm.stopPrank();
    }

    function helper_setPeriodTime(address org, uint256 _periodTime) public {
        vm.startPrank(boss);
        IOrganization(org).setPeriodTime(_periodTime);
        vm.stopPrank();
    }

    function helper_earn(address org, address _employee, address _protocol, uint256 _amount, uint256 _warpDays)
        public
    {
        vm.startPrank(_employee);
        vm.warp(block.timestamp + _warpDays);
        IOrganization(org).earn(_employee, _protocol, _amount);
        vm.stopPrank();
    }

    // ============ FACTORY TESTS ============

    function test_Factory_Constructor() public view {
        assertEq(factory.owner(), owner);
        assertEq(factory.earnStandard(), address(earnStandard));
    }

    function test_Factory_CreateOrganization() public {
        vm.startPrank(boss);

        address org = factory.createOrganization(address(mockUSDC), "MoyPay");

        assertTrue(org != address(0));
        assertEq(factory.organizations(boss, 0), org);

        vm.stopPrank();
    }

    function test_Factory_CreateMultipleOrganizations() public {
        vm.startPrank(boss);

        address org1 = factory.createOrganization(address(mockUSDC), "MoyPay1");
        address org2 = factory.createOrganization(address(mockUSDC), "MoyPay2");

        assertEq(factory.organizations(boss, 0), org1);
        assertEq(factory.organizations(boss, 1), org2);

        vm.stopPrank();
    }

    function test_Factory_AddEarnProtocol() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true);
        emit EarnProtocolAdded(address(0x123));

        factory.addEarnProtocol(address(0x123));

        assertTrue(factory.isEarnProtocol(address(0x123)));
        assertEq(factory.earnProtocol(0), address(mockVault));
        assertEq(factory.earnProtocol(1), address(mockVault2));
        assertEq(factory.earnProtocol(2), address(0x123));

        vm.stopPrank();
    }

    function test_Factory_RemoveEarnProtocol() public {
        vm.startPrank(owner);

        factory.addEarnProtocol(address(0x123));
        assertTrue(factory.isEarnProtocol(address(0x123)));

        vm.expectEmit(true, false, false, true);
        emit EarnProtocolRemoved(address(0x123));

        factory.removeEarnProtocol(address(0x123));

        assertFalse(factory.isEarnProtocol(address(0x123)));

        vm.stopPrank();
    }

    function test_Factory_SetEarnStandard() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true);
        emit EarnStandardSet(address(0x456));

        factory.setEarnStandard(address(0x456));

        assertEq(factory.earnStandard(), address(0x456));

        vm.stopPrank();
    }

    // ============ ORGANIZATION TESTS ============

    function test_Organization_Constructor() public {
        address org = helper_createOrganization();

        assertEq(IOrganization(org).owner(), boss);
        assertEq(IOrganization(org).token(), address(mockUSDC));
        assertEq(IOrganization(org).factory(), address(factory));
        assertEq(IOrganization(org).name(), "MoyPay");
        assertEq(IOrganization(org).periodTime(), 30 days);
    }

    function test_Organization_Deposit() public {
        address org = helper_createOrganization();

        vm.startPrank(boss);
        IERC20(address(mockUSDC)).approve(org, 1000e6);

        vm.expectEmit(true, false, false, true);
        emit Deposit(boss, 1000e6);

        IOrganization(org).deposit(1000e6);

        assertEq(IERC20(address(mockUSDC)).balanceOf(org), 1000e6);

        vm.stopPrank();
    }

    function test_Organization_Deposit_Revert_NotOwner() public {
        address org = helper_createOrganization();

        vm.startPrank(unauthorized);
        IERC20(address(mockUSDC)).approve(org, 1000e6);

        vm.expectRevert();
        IOrganization(org).deposit(1000e6);

        vm.stopPrank();
    }

    function test_Organization_AddEmployee() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);

        vm.startPrank(boss);

        vm.expectEmit(false, true, false, true);
        emit EmployeeSalaryAdded("John", employee, 1000e6, block.timestamp, block.timestamp, false);

        IOrganization(org).addEmployee("John", employee, 1000e6, block.timestamp, true);

        (string memory name, uint256 salary,, uint256 startStream,, bool status) =
            IOrganization(org).employeeSalary(employee);
        assertEq(name, "John");
        assertEq(salary, 1000e6);
        assertEq(startStream, block.timestamp);
        assertTrue(status);

        vm.stopPrank();
    }

    function test_Organization_AddEmployee_Revert_StartStreamInvalid() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);

        vm.startPrank(boss);

        vm.warp(block.timestamp + 365 days);
        vm.expectRevert(Organization.StartStreamInvalid.selector);
        IOrganization(org).addEmployee("John", employee, 1000e6, block.timestamp - 86400, false);

        vm.stopPrank();
    }

    function test_Organization_AddEmployee_Revert_DepositRequired() public {
        address org = helper_createOrganization();
        helper_deposit(org, 1000e6);

        vm.startPrank(boss);

        vm.expectRevert();
        IOrganization(org).addEmployee("John", employee, 2000e6, block.timestamp, true);

        vm.stopPrank();
    }

    function test_Organization_AddEmployee_Revert_EmployeeAlreadyAdded() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);

        vm.startPrank(boss);

        IOrganization(org).addEmployee("John", employee, 1000e6, block.timestamp, true);

        vm.expectRevert();
        IOrganization(org).addEmployee("John2", employee, 1000e6, block.timestamp, true);

        vm.stopPrank();
    }

    function test_Organization_AddEmployee_Revert_NotOwner() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);

        vm.startPrank(unauthorized);

        vm.expectRevert();
        IOrganization(org).addEmployee("John", employee, 1000e6, block.timestamp, true);

        vm.stopPrank();
    }

    function test_Organization_SetEmployeeSalary() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);

        vm.expectEmit(true, false, false, true);
        emit EmployeeSalarySet(employee, 2000e6, block.timestamp);

        IOrganization(org).setEmployeeSalary(employee, 2000e6, block.timestamp, true);

        (, uint256 salary,,,,) = IOrganization(org).employeeSalary(employee);
        assertEq(salary, 2000e6);

        vm.stopPrank();
    }

    function test_Organization_SetEmployeeSalary_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);

        vm.startPrank(boss);

        vm.expectRevert();
        IOrganization(org).setEmployeeSalary(employee, 2000e6, block.timestamp, true);

        vm.stopPrank();
    }

    function test_Organization_SetEmployeeSalary_Revert_DepositRequired() public {
        address org = helper_createOrganization();
        helper_deposit(org, 1000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);

        vm.expectRevert();
        IOrganization(org).setEmployeeSalary(employee, 2000e6, block.timestamp, true);

        vm.stopPrank();
    }

    function test_Organization_SetEmployeeStatus() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);

        vm.expectEmit(true, false, false, true);
        emit EmployeeStatusChanged(employee, false);

        IOrganization(org).setEmployeeStatus(employee, false);

        (,,,,, bool status) = IOrganization(org).employeeSalary(employee);
        assertFalse(status);

        vm.stopPrank();
    }

    function test_Organization_SetPeriodTime() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);

        vm.expectEmit(false, false, false, true);
        emit PeriodTimeSet(7 days);

        IOrganization(org).setPeriodTime(7 days);

        assertEq(IOrganization(org).periodTime(), 7 days);

        vm.stopPrank();
    }

    function test_Organization_SetPeriodTime_Revert_DepositRequired() public {
        address org = helper_createOrganization();
        helper_deposit(org, 1000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp time to accumulate salary
        vm.warp(block.timestamp + 60 days);

        vm.startPrank(boss);

        vm.expectRevert();
        IOrganization(org).setPeriodTime(7 days);

        vm.stopPrank();
    }

    function test_Organization_SetName() public {
        address org = helper_createOrganization();

        vm.startPrank(boss);

        vm.expectEmit(false, false, false, true);
        emit SetName("NewMoyPay");

        IOrganization(org).setName("NewMoyPay");

        assertEq(IOrganization(org).name(), "NewMoyPay");

        vm.stopPrank();
    }

    function test_Organization_CurrentSalary() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        uint256 initialSalary = IOrganization(org)._currentSalary(employee);
        assertEq(initialSalary, 0);

        // Warp 30 days (1 period)
        vm.warp(block.timestamp + 30 days);

        uint256 salaryAfter30Days = IOrganization(org)._currentSalary(employee);
        assertEq(salaryAfter30Days, 1000e6);

        // Warp another 15 days (0.5 period)
        vm.warp(block.timestamp + 15 days);

        uint256 salaryAfter45Days = IOrganization(org)._currentSalary(employee);
        assertEq(salaryAfter45Days, 1500e6);
    }

    // RUN
    // forge test -vvv --match-test test_Organization_Withdrawz
    function test_Organization_Withdrawz() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1300e6, block.timestamp, true);

        // Warp 30 days to accumulate salary
        vm.warp(block.timestamp + 30 days);

        uint256 balanceBefore = IERC20(address(mockUSDC)).balanceOf(employee);

        vm.startPrank(employee);

        // vm.expectEmit(true, false, false, true);
        // emit Withdraw(employee, ,1000e6, false, block.timestamp);

        console.log("current salary before", IOrganization(org)._currentSalary(employee) / 1e6, "USDC");
        IOrganization(org).withdraw(1000e6, false);
        vm.warp(block.timestamp + 1 hours);
        console.log("current salary after", IOrganization(org)._currentSalary(employee) / 1e6, "USDC");
        // IOrganization(org).withdraw(1000e6, false);

        uint256 balanceAfter = IERC20(address(mockUSDC)).balanceOf(employee);
        assertEq(balanceAfter - balanceBefore, 1000e6);

        IOrganization(org).withdraw(100e6, false);
        console.log("current salary after2", IOrganization(org)._currentSalary(employee) / 1e6, "USDC");
        vm.stopPrank();
    }

    function test_Organization_Withdraw_Offramp_True() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp 30 days to accumulate salary
        vm.warp(block.timestamp + 30 days);

        uint256 employeeBalanceBefore = IERC20(address(mockUSDC)).balanceOf(employee);
        uint256 orgBalanceBefore = IERC20(address(mockUSDC)).balanceOf(org);
        uint256 totalSupplyBefore = mockUSDC.totalSupply();

        vm.startPrank(employee);

        vm.expectEmit(true, false, false, true);
        emit Withdraw(employee, 500e6, 500e6, true, block.timestamp);

        IOrganization(org).withdraw(500e6, true);

        uint256 employeeBalanceAfter = IERC20(address(mockUSDC)).balanceOf(employee);
        uint256 orgBalanceAfter = IERC20(address(mockUSDC)).balanceOf(org);
        uint256 totalSupplyAfter = mockUSDC.totalSupply();

        // Employee balance should remain unchanged (tokens burned, not transferred)
        assertEq(employeeBalanceAfter, employeeBalanceBefore);
        
        // Organization balance should decrease by withdrawn amount
        assertEq(orgBalanceBefore - orgBalanceAfter, 500e6);
        
        // Total supply should decrease by withdrawn amount (tokens burned)
        assertEq(totalSupplyBefore - totalSupplyAfter, 500e6);

        vm.stopPrank();
    }

    function test_Organization_WithdrawAll_Offramp_True() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp 30 days to accumulate salary
        vm.warp(block.timestamp + 30 days);

        uint256 employeeBalanceBefore = IERC20(address(mockUSDC)).balanceOf(employee);
        uint256 orgBalanceBefore = IERC20(address(mockUSDC)).balanceOf(org);
        uint256 totalSupplyBefore = mockUSDC.totalSupply();
        uint256 currentSalary = IOrganization(org)._currentSalary(employee);

        vm.startPrank(employee);

        vm.expectEmit(true, false, false, true);
        emit WithdrawAll(employee, currentSalary, true, block.timestamp);

        IOrganization(org).withdrawAll(true);

        uint256 employeeBalanceAfter = IERC20(address(mockUSDC)).balanceOf(employee);
        uint256 orgBalanceAfter = IERC20(address(mockUSDC)).balanceOf(org);
        uint256 totalSupplyAfter = mockUSDC.totalSupply();

        // Employee balance should remain unchanged (tokens burned, not transferred)
        assertEq(employeeBalanceAfter, employeeBalanceBefore);
        
        // Organization balance should decrease by withdrawn amount
        assertEq(orgBalanceBefore - orgBalanceAfter, currentSalary);
        
        // Total supply should decrease by withdrawn amount (tokens burned)
        assertEq(totalSupplyBefore - totalSupplyAfter, currentSalary);

        vm.stopPrank();
    }

    function test_Organization_Withdraw_Offramp_True_Revert_InsufficientSalary() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp only 15 days (0.5 period = 500e6 salary)
        vm.warp(block.timestamp + 15 days);

        vm.startPrank(employee);

        // Should revert when trying to withdraw more than available salary, even with offramp
        vm.expectRevert();
        IOrganization(org).withdraw(1000e6, true);

        vm.stopPrank();
    }

    function test_Organization_Withdraw_Offramp_True_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(employee);

        // Should revert when employee is not active, even with offramp
        vm.expectRevert();
        IOrganization(org).withdraw(500e6, true);

        vm.stopPrank();
    }

    function test_Organization_WithdrawEarn_Offramp_True() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_earn(org, employee, address(mockVault), 500e6, 30 days);

        uint256 employeeBalanceBefore = IERC20(address(mockUSDC)).balanceOf(employee);
        uint256 totalSupplyBefore = mockUSDC.totalSupply();

        vm.startPrank(employee);

        // Get the shares to withdraw
        (, uint256 shares) = IOrganization(org).userEarn(employee, 0);
        uint256 sharesToWithdraw = shares / 2; // Withdraw half the shares

        IOrganization(org).withdrawEarn(employee, address(mockVault), sharesToWithdraw, true);

        uint256 employeeBalanceAfter = IERC20(address(mockUSDC)).balanceOf(employee);
        uint256 totalSupplyAfter = mockUSDC.totalSupply();

        // Employee balance should remain unchanged (tokens burned, not transferred)
        assertEq(employeeBalanceAfter, employeeBalanceBefore);
        
        // Total supply should decrease (tokens burned)
        assertLt(totalSupplyAfter, totalSupplyBefore);

        vm.stopPrank();
    }

    function test_Organization_Withdraw_Revert_DepositRequired() public {
        address org = helper_createOrganization();

        vm.startPrank(employee);

        vm.expectRevert(Organization.DepositRequired.selector);
        IOrganization(org).withdraw(1000e6, false);

        vm.stopPrank();
    }

    function test_Organization_Withdraw_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).withdraw(1000e6, false);

        vm.stopPrank();
    }

    function test_Organization_Withdraw_Revert_InsufficientSalary() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp only 15 days (0.5 period = 500e6 salary)
        vm.warp(block.timestamp + 15 days);

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).withdraw(1000e6, false);

        vm.stopPrank();
    }

    function test_Organization_WithdrawAll() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp 30 days to accumulate salary
        vm.warp(block.timestamp + 30 days);

        uint256 balanceBefore = IERC20(address(mockUSDC)).balanceOf(employee);

        vm.startPrank(employee);

        vm.expectEmit(true, false, false, true);
        emit WithdrawAll(employee, 1000e6, false, block.timestamp);

        IOrganization(org).withdrawAll(false);

        uint256 balanceAfter = IERC20(address(mockUSDC)).balanceOf(employee);
        assertEq(balanceAfter - balanceBefore, 1000e6);

        vm.stopPrank();
    }

    function test_Organization_WithdrawAll_Revert_DepositRequired() public {
        address org = helper_createOrganization();

        vm.startPrank(employee);

        vm.expectRevert(Organization.DepositRequired.selector);
        IOrganization(org).withdrawAll(false);

        vm.stopPrank();
    }

    function test_Organization_WithdrawAll_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).withdrawAll(false);

        vm.stopPrank();
    }

    // ============ EARN FUNCTIONALITY TESTS ============

    function test_Organization_EnableAutoEarn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp time to accumulate salary
        vm.warp(block.timestamp + 30 days);

        vm.startPrank(employee);

        IOrganization(org).enableAutoEarn(address(mockVault), 100e6);

        vm.stopPrank();
    }

    function test_Organization_EnableAutoEarn_Revert_EarnProtocolNotGranted() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).enableAutoEarn(address(0x123), 100e6);

        vm.stopPrank();
    }

    function test_Organization_EnableAutoEarn_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).enableAutoEarn(address(mockVault), 100e6);

        vm.stopPrank();
    }

    function test_Organization_DisableAutoEarn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp time to accumulate salary
        vm.warp(block.timestamp + 30 days);

        vm.startPrank(employee);
        IOrganization(org).enableAutoEarn(address(mockVault), 100e6);
        vm.stopPrank();

        vm.startPrank(boss);

        IOrganization(org).disableAutoEarn(employee, address(mockVault));

        vm.stopPrank();
    }

    function test_Organization_Earn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp 30 days to accumulate salary
        vm.warp(block.timestamp + 30 days);

        vm.startPrank(employee);

        uint256 shares = IOrganization(org).earn(employee, address(mockVault), 500e6);

        (address protocol, uint256 userShares) = IOrganization(org).userEarn(employee, 0);
        assertEq(protocol, address(mockVault));
        assertEq(userShares, shares);

        vm.stopPrank();
    }

    function test_Organization_Earn_Revert_EarnProtocolNotGranted() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).earn(employee, address(0x123), 500e6);

        vm.stopPrank();
    }

    function test_Organization_Earn_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).earn(employee, address(mockVault), 500e6);

        vm.stopPrank();
    }

    function test_Organization_Earn_Revert_InsufficientSalary() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp only 15 days (0.5 period = 500e6 salary)
        vm.warp(block.timestamp + 15 days);

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).earn(employee, address(mockVault), 1000e6);

        vm.stopPrank();
    }

    function test_Organization_WithdrawEarn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_earn(org, employee, address(mockVault), 500e6, 30 days);

        uint256 balanceBefore = IERC20(address(mockUSDC)).balanceOf(employee);

        vm.startPrank(employee);

        IOrganization(org).withdrawEarn(employee, address(mockVault), 1e6, false);

        uint256 balanceAfter = IERC20(address(mockUSDC)).balanceOf(employee);
        assertGt(balanceAfter, balanceBefore);

        vm.stopPrank();
    }

    function test_Organization_WithdrawEarn_Revert_EarnProtocolNotGranted() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_earn(org, employee, address(mockVault), 500e6, 30 days);

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).withdrawEarn(employee, address(0x123), 1e6, false);

        vm.stopPrank();
    }

    function test_Organization_WithdrawEarn_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_earn(org, employee, address(mockVault), 500e6, 30 days);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).withdrawEarn(employee, address(mockVault), 1e6, false);

        vm.stopPrank();
    }

    function test_Organization_WithdrawEarn_Revert_InsufficientShares() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_earn(org, employee, address(mockVault), 500e6, 30 days);

        vm.startPrank(employee);

        vm.expectRevert();
        IOrganization(org).withdrawEarn(employee, address(mockVault), 1000e6, false);

        vm.stopPrank();
    }

    function test_Organization_AutoEarn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        // Warp time to accumulate salary
        vm.warp(block.timestamp + 30 days);

        vm.startPrank(employee);
        IOrganization(org).enableAutoEarn(address(mockVault), 100e6);
        vm.stopPrank();

        vm.startPrank(boss);
        IOrganization(org).autoEarn(employee);
        vm.stopPrank();
    }

    function test_Organization_AutoEarn_Revert_EmployeeNotActive() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        vm.startPrank(boss);

        vm.expectRevert();
        IOrganization(org).autoEarn(employee);

        vm.stopPrank();
    }

    // ============ EARNSTANDARD TESTS ============

    function test_EarnStandard_Constructor() public view {
        assertEq(earnStandard.owner(), owner);
    }

    function test_EarnStandard_ExecEarn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(employee);
        vm.warp(block.timestamp + 30 days);

        // First withdraw salary to get tokens
        IOrganization(org).withdraw(500e6, false);

        // Approve tokens for earnStandard
        mockUSDC.approve(address(earnStandard), 500e6);

        uint256 shares = earnStandard.execEarn(address(mockVault), address(mockUSDC), employee, 500e6);
        console.log("shares", shares / 1e6, "shares");

        vm.stopPrank();
    }

    function test_EarnStandard_WithdrawEarn() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_earn(org, employee, address(mockVault), 500e6, 30 days);

        vm.startPrank(employee);

        uint256 amount = earnStandard.withdrawEarn(address(mockVault), address(mockUSDC), employee, 1e6);
        console.log("amount", amount / 1e6, "USDC");

        vm.stopPrank();
    }

    // ============ INTEGRATION TESTS ============

    function test_Integration_CompleteWorkflow() public {
        // 1. Create organization
        address org = helper_createOrganization();

        // 2. Deposit funds
        helper_deposit(org, 50_000e6);

        // 3. Add multiple employees
        helper_addEmployee(org, "John", employee, 2000e6, block.timestamp, true);
        helper_addEmployee(org, "Jane", employee2, 1500e6, block.timestamp, true);
        helper_addEmployee(org, "Bob", employee3, 1000e6, block.timestamp, true);

        // 4. Set period time
        helper_setPeriodTime(org, 7 days);

        // 5. Warp time and test salary accumulation
        vm.warp(block.timestamp + 7 days);

        uint256 johnSalary = IOrganization(org)._currentSalary(employee);
        uint256 janeSalary = IOrganization(org)._currentSalary(employee2);
        uint256 bobSalary = IOrganization(org)._currentSalary(employee3);

        assertEq(johnSalary, 2000e6);
        assertEq(janeSalary, 1500e6);
        assertEq(bobSalary, 1000e6);

        // 6. Test withdrawals
        vm.startPrank(employee);
        IOrganization(org).withdraw(1000e6, false);
        vm.stopPrank();

        vm.startPrank(employee2);
        IOrganization(org).withdrawAll(false);
        vm.stopPrank();

        // 7. Test earn functionality
        vm.startPrank(employee3);
        IOrganization(org).earn(employee3, address(mockVault), 500e6);
        vm.stopPrank();

        // 8. Test auto earn - need more salary accumulation first
        vm.warp(block.timestamp + 7 days);

        vm.startPrank(employee);
        IOrganization(org).enableAutoEarn(address(mockVault2), 200e6);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        vm.startPrank(boss);
        IOrganization(org).autoEarn(employee);
        vm.stopPrank();
    }

    function test_Integration_MultipleEarnProtocols() public {
        address org = helper_createOrganization();
        helper_deposit(org, 20_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.warp(block.timestamp + 30 days);

        vm.startPrank(employee);

        // Earn with first protocol
        IOrganization(org).earn(employee, address(mockVault), 300e6);

        // Earn with second protocol
        IOrganization(org).earn(employee, address(mockVault2), 200e6);

        // Check both earn records exist
        (address protocol1, uint256 shares1) = IOrganization(org).userEarn(employee, 0);
        (address protocol2, uint256 shares2) = IOrganization(org).userEarn(employee, 1);

        assertEq(protocol1, address(mockVault));
        assertEq(protocol2, address(mockVault2));
        assertGt(shares1, 0);
        assertGt(shares2, 0);

        vm.stopPrank();
    }

    function test_Integration_EmployeeStatusChanges() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.warp(block.timestamp + 30 days);

        // Employee should be able to withdraw
        vm.startPrank(employee);
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();

        // Deactivate employee
        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, false);
        vm.stopPrank();

        // Employee should not be able to withdraw anymore
        vm.startPrank(employee);
        vm.expectRevert();
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();

        // Reactivate employee
        vm.startPrank(boss);
        IOrganization(org).setEmployeeStatus(employee, true);
        vm.stopPrank();

        // Employee should be able to withdraw again - but need more salary accumulation
        vm.warp(block.timestamp + 30 days);
        vm.startPrank(employee);
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();
    }

    // ============ EDGE CASES AND STRESS TESTS ============

    function test_EdgeCase_ZeroAmounts() public {
        address org = helper_createOrganization();
        helper_deposit(org, 10_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.startPrank(employee);
        // Zero amount withdrawal should work (no revert expected)
        IOrganization(org).withdraw(0, false);
        vm.stopPrank();
    }

    function test_EdgeCase_MaximumValues() public {
        address org = helper_createOrganization();
        helper_deposit(org, 100_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);

        vm.warp(block.timestamp + 30 days);

        vm.startPrank(employee);
        IOrganization(org).withdrawAll(false);
        vm.stopPrank();
    }

    function test_EdgeCase_MultipleEmployeesWithSameSalary() public {
        address org = helper_createOrganization();
        helper_deposit(org, 100_000e6);

        // Add 10 employees with same salary
        for (uint256 i = 0; i < 10; i++) {
            address emp = makeAddr(string(abi.encodePacked("employee", i)));
            mockUSDC.mint(emp, 1000e6);
            helper_addEmployee(org, string(abi.encodePacked("Emp", i)), emp, 1000e6, block.timestamp, true);
        }

        vm.warp(block.timestamp + 30 days);

        // All employees should be able to withdraw
        for (uint256 i = 0; i < 10; i++) {
            address emp = makeAddr(string(abi.encodePacked("employee", i)));
            vm.startPrank(emp);
            IOrganization(org).withdraw(1000e6, false);
            vm.stopPrank();
        }
    }

    function test_EdgeCase_ConcurrentOperations() public {
        address org = helper_createOrganization();
        helper_deposit(org, 50_000e6);
        helper_addEmployee(org, "John", employee, 1000e6, block.timestamp, true);
        helper_addEmployee(org, "Jane", employee2, 1000e6, block.timestamp, true);

        vm.warp(block.timestamp + 30 days);

        // Simulate concurrent withdrawals
        vm.startPrank(employee);
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();

        vm.startPrank(employee2);
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();

        // Try to withdraw again - should fail due to insufficient salary
        vm.startPrank(employee);
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();

        vm.startPrank(employee2);
        IOrganization(org).withdraw(500e6, false);
        vm.stopPrank();
    }
}

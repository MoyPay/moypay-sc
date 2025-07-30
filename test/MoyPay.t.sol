// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Factory} from "../src/Factory.sol";
import {Organization} from "../src/Organization.sol";
import {EarnStandard} from "../src/EarnStandard.sol";
import {MockVault} from "../src/Mocks/MockVault.sol";
import {MockUSDC} from "../src/Mocks/MockUSDC.sol";
import {IOrganization} from "../src/intefaces/IOrganization.sol";
import {IMockVault} from "../src/intefaces/IMockVault.sol";

contract MoyPayTest is Test {
    MockUSDC public mockUSDC;
    Factory public factory;
    Organization public organization;
    EarnStandard public earnStandard;
    MockVault public mockVault;

    address owner = makeAddr("owner");
    address boss = makeAddr("boss");
    address employee = makeAddr("employee");

    // RUN
    // forge test -vvv --match-test test_createOrganization
    function setUp() public {
        vm.startPrank(owner);

        mockUSDC = new MockUSDC();
        factory = new Factory();
        earnStandard = new EarnStandard();
        mockVault = new MockVault("MORPHO");
        mockVault = new MockVault("COMPOUND");
        mockVault = new MockVault("CENTUARI");
        mockVault = new MockVault("TUMBUH");
        mockVault = new MockVault("CAER");
        mockVault = new MockVault("AAVE");
        organization = new Organization(address(mockUSDC), address(factory), owner, "MoyPay");

        factory.addEarnProtocol(address(mockVault));
        factory.setEarnStandard(address(earnStandard));

        vm.stopPrank();

        mockUSDC.mint(owner, 100_000e6);
        mockUSDC.mint(boss, 100_000e6);
    }

    function helper_createOrganization() public {
        vm.startPrank(boss);
        factory.createOrganization(address(mockUSDC), "MoyPay");
        vm.stopPrank();
    }

    function helper_deposit(uint256 _amount) public {
        vm.startPrank(boss);
        address org = factory.organizations(boss, 0);
        IERC20(address(mockUSDC)).approve(org, _amount);
        IOrganization(org).deposit(_amount);
        vm.stopPrank();
    }

    function helper_addEmployee(string memory _name, uint256 _salary, uint256 _startStream) public {
        vm.startPrank(boss);
        address org = factory.organizations(boss, 0);
        IOrganization(org).addEmployee(_name, employee, _salary, _startStream, false);
        vm.stopPrank();
    }

    function helper_setPeriodTime(uint256 _periodTime) public {
        vm.startPrank(boss);
        address org = factory.organizations(boss, 0);
        IOrganization(org).setPeriodTime(_periodTime);
        vm.stopPrank();
    }

    function helper_earn(uint256 _amount, uint256 _warpDays) public {
        vm.startPrank(employee);
        address org = factory.organizations(boss, 0);
        vm.warp(block.timestamp + _warpDays);
        IOrganization(org).earn(employee, address(mockVault), _amount);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_createOrganization
    function test_createOrganization() public {
        helper_createOrganization();
    }

    // RUN
    // forge test -vvv --match-test test_deposit
    function test_deposit() public {
        helper_createOrganization();
        helper_deposit(1000e6);
    }

    // RUN
    // forge test -vvv --match-test test_addEmployee
    function test_addEmployee() public {
        helper_createOrganization();
        helper_deposit(10_000e6);
        helper_addEmployee("Jadifa", 1000e6, block.timestamp);
    }

    // RUN
    // forge test -vvv --match-test test_withdrawAll
    function test_withdrawAll() public {
        helper_createOrganization();
        helper_deposit(10_000e6);
        helper_addEmployee("Jadifa", 1000e6, block.timestamp);
        helper_setPeriodTime(30 days);
        address org = factory.organizations(boss, 0);

        vm.startPrank(employee);
        console.log("balance before", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");
        vm.warp(block.timestamp + 30 days);
        IOrganization(org).withdrawAll(false);
        console.log("balance after", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdraw
    function test_withdraw() public {
        helper_createOrganization();
        helper_deposit(10_000e6);
        helper_setPeriodTime(30 days);
        helper_addEmployee("Jadifa", 1000e6, block.timestamp);
        address org = factory.organizations(boss, 0);

        vm.startPrank(employee);
        console.log("balance before", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");
        vm.warp(block.timestamp + 30 days);
        IOrganization(org).withdraw(1000e6, false);
        console.log("balance after", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_earn
    function test_earn() public {
        helper_createOrganization();
        helper_deposit(10_000e6);
        helper_setPeriodTime(30 days);
        helper_addEmployee("Jadifa", 1000e6, block.timestamp);
        address org = factory.organizations(boss, 0);

        vm.startPrank(employee);
        vm.warp(block.timestamp + 30 days);
        console.log("# check employee current salary");
        console.log("***********************");
        console.log("current salary after earn", IOrganization(org)._currentSalary(employee) / 1e6, "USDC");
        IOrganization(org).earn(employee, address(mockVault), 100e6);
        console.log("***********************");
        console.log("# check employee earn");
        console.log("***********************");
        (address protocol, uint256 shares) = IOrganization(org).userEarn(employee, 0);
        console.log("protocol", protocol);
        console.log("shares", shares / 1e6, "shares");
        console.log("balance of vault", IERC20(address(mockUSDC)).balanceOf(address(mockVault)) / 1e6, "USDC");
        console.log("***********************");
        console.log("# check employee current salary");
        console.log("***********************");
        console.log("current salary after earn", IOrganization(org)._currentSalary(employee) / 1e6, "USDC");
        console.log("***********************");
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_distributeReward
    function test_distributeReward() public {
        helper_createOrganization();
        helper_deposit(10_000e6);
        helper_setPeriodTime(30 days);
        helper_addEmployee("Jadifa", 1000e6, block.timestamp);
        helper_earn(1000e6, 30 days);

        vm.startPrank(boss);
        IERC20(address(mockUSDC)).approve(address(mockVault), 1000e6);
        IMockVault(address(mockVault)).distributeReward(address(mockUSDC), 1000e6);
        vm.stopPrank();
        console.log("balance of vault", IERC20(address(mockUSDC)).balanceOf(address(mockVault)) / 1e6, "USDC");
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdrawEarn
    function test_withdrawEarn() public {
        helper_createOrganization();
        helper_deposit(10_000e6);
        helper_setPeriodTime(30 days);
        helper_addEmployee("Jadifa", 1000e6, block.timestamp);
        helper_earn(900e6, 30 days);

        vm.startPrank(boss);
        IERC20(address(mockUSDC)).approve(address(mockVault), 1000e6);
        IMockVault(address(mockVault)).distributeReward(address(mockUSDC), 1000e6);
        vm.stopPrank();

        console.log("balance of vault", IERC20(address(mockUSDC)).balanceOf(address(mockVault)) / 1e6, "USDC");
        console.log("balance of employee", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");

        console.log("***********************");
        console.log("***********************");

        address org = factory.organizations(boss, 0);
        console.log("balance of vault before", IERC20(address(mockUSDC)).balanceOf(address(mockVault)) / 1e6, "USDC");
        console.log("balance of employee before", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");
        vm.startPrank(employee);
        IOrganization(org).withdrawEarn(employee, address(mockVault), 1e6, false);
        (, uint256 shares) = IOrganization(org).userEarn(employee, 0);
        console.log("shares", shares / 1e6, "shares");
        vm.stopPrank();
        console.log("balance of vault after", IERC20(address(mockUSDC)).balanceOf(address(mockVault)) / 1e6, "USDC");
        console.log("balance of employee after", IERC20(address(mockUSDC)).balanceOf(employee) / 1e6, "USDC");
        console.log("***********************");
        console.log("current salary after earn", IOrganization(org)._currentSalary(employee) / 1e6, "USDC");
    }
}

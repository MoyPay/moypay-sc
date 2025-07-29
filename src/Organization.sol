// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEarnStandard} from "./intefaces/IEarnStandard.sol";
import {IFactory} from "./intefaces/IFactory.sol";

contract Organization is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error NotOwner();
    error TransferFailed();
    error DepositRequired();
    error InsufficientSalary();
    error EmployeeNotActive();
    error EarnProtocolNotGranted();

    struct Employees {
        uint256 salary;
        uint256 createdAt;
        bool status;
    }

    struct Earn {
        address protocol;
        uint256 shares;
    }

    address public owner;
    address public token;
    address public factory;
    address[] public employees;
    mapping(address => Employees) public employeeSalary;
    mapping(address => Earn[]) public userEarn;

    uint256 public periodTime; // block.timestamp == (Yearly || Monthly || Weekly || Daily)

    constructor(address _token, address _factory, address _owner) {
        token = _token;
        factory = _factory;
        owner = _owner;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert NotOwner();
    }

    function setEmployeeSalary(address _employee, uint256 _salary) public onlyOwner {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        employeeSalary[_employee] = Employees({salary: _salary, createdAt: block.timestamp, status: true});
        employees.push(_employee);
    }

    function setEmployeeStatus(address _employee, bool _status) public onlyOwner {
        if (!employeeSalary[_employee].status) revert EmployeeNotActive();
        employeeSalary[_employee].status = _status;
        if (_currentSalary() > IERC20(token).balanceOf(address(this))) revert InsufficientSalary();
        if (!_status) IERC20(token).safeTransfer(msg.sender, _currentSalary());
    }

    function setPeriodTime(uint256 _periodTime) public onlyOwner {
        periodTime = _periodTime;
    }

    // ******************* DISTRIBUTE SALARY
    function deposit(uint256 amount) public onlyOwner nonReentrant {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        employeeSalary[msg.sender].createdAt = block.timestamp;
        if (realizedSalary < amount) revert InsufficientSalary();
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function withdrawAll() public nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        employeeSalary[msg.sender].createdAt = block.timestamp;
        IERC20(token).safeTransfer(msg.sender, realizedSalary);
    }

    function _currentSalary() internal view returns (uint256) {
        uint256 currentSalary =
            (block.timestamp - employeeSalary[msg.sender].createdAt) * employeeSalary[msg.sender].salary / periodTime;
        return currentSalary;
    }
    // **********************************

    function earn(address _protocol, uint256 _amount) public nonReentrant returns (uint256) {
        if (!IFactory(factory).isEarnProtocol(_protocol)) revert EarnProtocolNotGranted(); // earn protocol owner must provided to prevent leaked data contract guys
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        if (realizedSalary < _amount) revert InsufficientSalary();

        address earnStandard = IFactory(factory).earnStandard();
        IERC20(token).approve(earnStandard, _amount);
        uint256 shares = IEarnStandard(earnStandard).execEarn(_protocol, token, msg.sender, _amount);
        for (uint256 i = 0; i < userEarn[msg.sender].length; i++) {
            if (userEarn[msg.sender][i].protocol == _protocol) {
                userEarn[msg.sender][i].shares += shares;
                return shares;
            }
        }
        userEarn[msg.sender].push(Earn({protocol: _protocol, shares: shares}));
        return shares;
    }
}

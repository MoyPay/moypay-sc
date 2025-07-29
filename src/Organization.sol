// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEarn} from "./intefaces/IEarn.sol";
import {IFactory} from "./intefaces/IFactory.sol";

contract Organization is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error NotOwner();
    error TransferFailed();
    error DepositRequired();
    error InsufficientBalance();
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

    constructor(address _token, address _factory) {
        owner = msg.sender;
        token = _token;
        factory = _factory;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert NotOwner();
    }

    function setEmployeeSalary(address _employee, uint256 _salary) public {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        employeeSalary[_employee] = Employees({salary: _salary, createdAt: block.timestamp, status: true});
        employees.push(_employee);
    }

    function setEmployeeStatus(address _employee, bool _status) public {
        if (!employeeSalary[_employee].status) revert EmployeeNotActive();
        employeeSalary[_employee].status = _status;
        if (_currentSalary() > IERC20(token).balanceOf(address(this))) revert InsufficientBalance();
        if (!_status) IERC20(token).transfer(msg.sender, _currentSalary());
    }

    // ******************* DISTRIBUTE SALARY
    function deposit(uint256 amount) public onlyOwner nonReentrant {
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
    }

    function withdraw(uint256 amount) public nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        employeeSalary[msg.sender].createdAt = block.timestamp;
        if (realizedSalary < amount) revert InsufficientBalance();
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawAll() public nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        employeeSalary[msg.sender].createdAt = block.timestamp;
        IERC20(token).transfer(msg.sender, realizedSalary);
    }

    function _currentSalary() internal view returns (uint256) {
        uint256 currentSalary =
            (block.timestamp - employeeSalary[msg.sender].createdAt) * employeeSalary[msg.sender].salary / periodTime;
        return currentSalary;
    }
    // **********************************

    function earn(address _protocol, uint256 _amount) public nonReentrant returns (uint256) {
        if (!IFactory(factory).isEarnProtocol(_protocol)) revert EarnProtocolNotGranted();
        IERC20(token).approve(_protocol, _amount);
        uint256 shares = IEarn(_protocol).execEarn(_protocol, address(token), msg.sender, _amount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEarnStandard} from "./intefaces/IEarnStandard.sol";
import {IFactory} from "./intefaces/IFactory.sol";
import {IBurn} from "./intefaces/IBurn.sol";

contract Organization is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Events
    event EmployeeSalarySet(string name, address indexed employee, uint256 salary, uint256 timestamp);
    event EmployeeStatusChanged(address indexed employee, bool status);
    event PeriodTimeSet(uint256 periodTime);
    event Deposit(address indexed owner, uint256 amount);
    event Withdraw(address indexed employee, uint256 amount, bool isOfframp);
    event WithdrawAll(address indexed employee, uint256 amount, bool isOfframp);
    event EarnSalary(address indexed employee, address indexed protocol, uint256 amount, uint256 shares);
    event SetName(string name);

    error NotOwner();
    error TransferFailed();
    error DepositRequired();
    error InsufficientSalary();
    error EmployeeNotActive();
    error EarnProtocolNotGranted();
    error InsufficientShares();

    struct Employees {
        string name;
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

    uint256 public periodTime = 30 days; // block.timestamp == (Yearly || Monthly || Weekly || Daily)

    string public name;

    constructor(address _token, address _factory, address _owner, string memory _name) {
        token = _token;
        factory = _factory;
        owner = _owner;
        name = _name;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert NotOwner();
    }

    function setEmployeeSalary(string memory _name, address _employee, uint256 _salary) public onlyOwner {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        employeeSalary[_employee] = Employees({name: _name, salary: _salary, createdAt: block.timestamp, status: true});
        employees.push(_employee);
        emit EmployeeSalarySet(_name, _employee, _salary, block.timestamp);
    }

    function setEmployeeStatus(address _employee, bool _status) public onlyOwner {
        if (!employeeSalary[_employee].status) revert EmployeeNotActive();
        employeeSalary[_employee].status = _status;
        if (_currentSalary() > IERC20(token).balanceOf(address(this))) revert InsufficientSalary();
        if (!_status) {
            IERC20(token).safeTransfer(_employee, _currentSalary());
            for (uint256 i = 0; i < userEarn[_employee].length; i++) {
                if (userEarn[_employee][i].shares > 0) {
                    withdrawEarn(userEarn[_employee][i].protocol, userEarn[_employee][i].shares, false);
                }
            }
        }
        emit EmployeeStatusChanged(_employee, _status);
    }

    function setPeriodTime(uint256 _periodTime) public onlyOwner {
        periodTime = _periodTime;
        emit PeriodTimeSet(_periodTime);
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
        emit SetName(_name);
    }

    // ******************* DISTRIBUTE SALARY
    function deposit(uint256 amount) public onlyOwner nonReentrant {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount, bool isOfframp) public nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        employeeSalary[msg.sender].createdAt = block.timestamp;
        if (realizedSalary < amount) revert InsufficientSalary();
        if (isOfframp) {
            IBurn(token).burn(msg.sender, amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, amount, isOfframp);
    }

    function withdrawAll(bool isOfframp) public nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary();
        employeeSalary[msg.sender].createdAt = block.timestamp;
        if (isOfframp) {
            IBurn(token).burn(msg.sender, realizedSalary);
        } else {
            IERC20(token).safeTransfer(msg.sender, realizedSalary);
        }
        emit WithdrawAll(msg.sender, realizedSalary, isOfframp);
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
                emit EarnSalary(msg.sender, _protocol, _amount, shares);
                return shares;
            }
        }
        userEarn[msg.sender].push(Earn({protocol: _protocol, shares: shares}));
        emit EarnSalary(msg.sender, _protocol, _amount, shares);
        return shares;
    }

    function withdrawEarn(address _protocol, uint256 _shares, bool isOfframp) public nonReentrant {
        if (!IFactory(factory).isEarnProtocol(_protocol)) revert EarnProtocolNotGranted();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        for (uint256 i = 0; i < userEarn[msg.sender].length; i++) {
            if (userEarn[msg.sender][i].protocol == _protocol) {
                if (userEarn[msg.sender][i].shares < _shares) revert InsufficientShares();
                userEarn[msg.sender][i].shares -= _shares;
            }
        }
        address earnStandard = IFactory(factory).earnStandard();
        uint256 amount = IEarnStandard(earnStandard).withdrawEarn(_protocol, token, msg.sender, _shares);

        if (isOfframp) {
            IBurn(token).burn(msg.sender, amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, amount, isOfframp);
    }
}

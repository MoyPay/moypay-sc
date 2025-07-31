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
    event EmployeeSalaryAdded(
        string name, address indexed employee, uint256 salary, uint256 startStream, uint256 timestamp, bool isAutoEarn
    );
    event EmployeeSalarySet(address indexed employee, uint256 salary, uint256 startStream);
    event EmployeeStatusChanged(address indexed employee, bool status);
    event PeriodTimeSet(uint256 periodTime);
    event Deposit(address indexed owner, uint256 amount);
    event Withdraw(
        address indexed employee, uint256 amount, uint256 unrealizedSalary, bool isOfframp, uint256 startStream
    );
    event WithdrawAll(address indexed employee, uint256 amount, bool isOfframp, uint256 startStream);
    event EarnSalary(address indexed employee, address indexed protocol, uint256 amount, uint256 shares);
    event SetName(string name);
    event EnableAutoEarn(address indexed employee, address indexed protocol, uint256 amount);
    event DisableAutoEarn(address indexed employee, address indexed protocol);
    event WithdrawBalanceOrganization(uint256 amount, bool isOfframp);

    error NotOwner();
    error TransferFailed();
    error DepositRequired();
    error InsufficientSalary();
    error EmployeeNotActive();
    error EarnProtocolNotGranted();
    error InsufficientShares();
    error EmployeeAlreadyAdded();
    error StartStreamInvalid();

    struct Employees {
        string name;
        uint256 salary;
        uint256 unrealizedSalary;
        uint256 startStream;
        uint256 createdAt;
        bool status;
    }

    struct Earn {
        address protocol;
        uint256 shares;
        uint256 autoEarnAmount;
        bool isAutoEarn;
    }

    address public owner;
    address public token;
    address public factory;
    address[] public employees;
    mapping(address => Employees) public employeeSalary;
    mapping(address => Earn[]) public userEarn;

    // TODO:
    // START STREAM

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

    function addEmployee(string memory _name, address _employee, uint256 _salary, uint256 _startStream, bool isNow)
        public
        onlyOwner
    {
        //***** PROTECTION */
        if (_startStream < block.timestamp && !isNow) revert StartStreamInvalid();
        uint256 totalSalary = 0;
        for (uint256 i = 0; i < employees.length; i++) {
            totalSalary += employeeSalary[employees[i]].salary;
        }
        totalSalary += _salary;
        if (totalSalary > IERC20(token).balanceOf(address(this))) revert DepositRequired();

        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i] == _employee) revert EmployeeAlreadyAdded();
        }
        //******************/

        if (employeeSalary[_employee].status) revert EmployeeAlreadyAdded();
        employeeSalary[_employee] = Employees({
            name: _name,
            salary: _salary,
            startStream: isNow ? block.timestamp : _startStream,
            unrealizedSalary: 0,
            createdAt: block.timestamp,
            status: true
        });
        employees.push(_employee);
        emit EmployeeSalaryAdded(
            _name, _employee, _salary, employeeSalary[_employee].startStream, block.timestamp, false
        );
    }

    function setEmployeeSalary(address _employee, uint256 _salary, uint256 _startStream, bool isNow) public onlyOwner {
        //***** PROTECTION */
        if (!employeeSalary[_employee].status) revert EmployeeNotActive();

        uint256 totalSalary = 0;
        for (uint256 i = 0; i < employees.length; i++) {
            totalSalary += _currentSalary(employees[i]);
        }
        totalSalary += _salary;
        if (totalSalary > IERC20(token).balanceOf(address(this))) revert DepositRequired();
        //******************/

        IERC20(token).safeTransfer(_employee, _currentSalary(_employee));
        employeeSalary[_employee].salary = _salary;
        employeeSalary[_employee].startStream = isNow ? block.timestamp : _startStream;
        emit EmployeeSalarySet(_employee, _salary, employeeSalary[_employee].startStream);
    }

    function setEmployeeStatus(address _employee, bool _status) public onlyOwner {
        for (uint256 n = 0; n < employees.length; n++) {
            if (employees[n] == _employee) {
                if (_currentSalary(_employee) > IERC20(token).balanceOf(address(this))) revert DepositRequired();
                IERC20(token).safeTransfer(_employee, _currentSalary(_employee));
                for (uint256 i = 0; i < userEarn[_employee].length; i++) {
                    if (userEarn[_employee][i].shares > 0) {
                        withdrawEarn(_employee, userEarn[_employee][i].protocol, userEarn[_employee][i].shares, false);
                    }
                }
                employeeSalary[_employee].status = _status;
            }
        }
        emit EmployeeStatusChanged(_employee, _status);
    }

    // TODO: REMOVE EMPLOYEE

    function setPeriodTime(uint256 _periodTime) public onlyOwner {
        for (uint256 n = 0; n < employees.length; n++) {
            if (_currentSalary(employees[n]) > IERC20(token).balanceOf(address(this))) revert DepositRequired();
            IERC20(token).safeTransfer(employees[n], _currentSalary(employees[n]));
            for (uint256 i = 0; i < userEarn[employees[n]].length; i++) {
                if (userEarn[employees[n]][i].shares > 0) {
                    withdrawEarn(
                        employees[n], userEarn[employees[n]][i].protocol, userEarn[employees[n]][i].shares, false
                    );
                }
            }
        }
        periodTime = _periodTime;
        emit PeriodTimeSet(_periodTime);
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
        emit SetName(_name);
    }

    function withdrawBalanceOrganization(uint256 amount, bool isOfframp) public onlyOwner nonReentrant {
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        uint256 totalSalary = 0;
        for (uint256 i = 0; i < employees.length; i++) {
            totalSalary += _currentSalary(employees[i]);
        }
        if (totalSalary < amount) revert InsufficientSalary();

        if (isOfframp) {
            IBurn(token).burn(msg.sender, amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit WithdrawBalanceOrganization(amount, isOfframp);
    }

    // ******************* DISTRIBUTE SALARY
    function deposit(uint256 amount) public onlyOwner nonReentrant {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount, bool isOfframp) public nonReentrant {
        //***** PROTECTION */
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary(msg.sender);
        employeeSalary[msg.sender].startStream = block.timestamp;
        if (realizedSalary < amount) revert InsufficientSalary();
        //******************/

        if (isOfframp) {
            IBurn(token).burn(msg.sender, amount);
        } else {
            employeeSalary[msg.sender].unrealizedSalary += (realizedSalary - amount);
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit Withdraw(
            msg.sender,
            amount,
            employeeSalary[msg.sender].unrealizedSalary,
            isOfframp,
            employeeSalary[msg.sender].startStream
        );
    }

    function withdrawAll(bool isOfframp) public nonReentrant {
        //***** PROTECTION */
        if (IERC20(token).balanceOf(address(this)) == 0) revert DepositRequired();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        //******************/

        uint256 realizedSalary = _currentSalary(msg.sender);
        employeeSalary[msg.sender].startStream = block.timestamp;
        if (isOfframp) {
            IBurn(token).burn(msg.sender, realizedSalary);
        } else {
            IERC20(token).safeTransfer(msg.sender, realizedSalary);
        }
        emit WithdrawAll(msg.sender, realizedSalary, isOfframp, employeeSalary[msg.sender].startStream);
    }

    function _currentSalary(address _employee) public view returns (uint256) {
        uint256 currentSalary =
            (block.timestamp - employeeSalary[_employee].startStream) * employeeSalary[_employee].salary / periodTime;
        currentSalary += employeeSalary[_employee].unrealizedSalary;
        return currentSalary;
    }
    // **********************************

    function enableAutoEarn(address _protocol, uint256 _eachAmount) public {
        if (!IFactory(factory).isEarnProtocol(_protocol)) revert EarnProtocolNotGranted();
        if (!employeeSalary[msg.sender].status) revert EmployeeNotActive();
        for (uint256 i = 0; i < userEarn[msg.sender].length; i++) {
            if (userEarn[msg.sender][i].protocol == _protocol) {
                userEarn[msg.sender][i].autoEarnAmount = _eachAmount;
                userEarn[msg.sender][i].isAutoEarn = true;
                return;
            }
        }
        userEarn[msg.sender].push(Earn({protocol: _protocol, shares: 0, autoEarnAmount: _eachAmount, isAutoEarn: true}));
        earn(msg.sender, _protocol, _eachAmount);
        emit EnableAutoEarn(msg.sender, _protocol, _eachAmount);
    }

    function autoEarn(address _user) public {
        if (!employeeSalary[_user].status) revert EmployeeNotActive();
        for (uint256 i = 0; i < userEarn[_user].length; i++) {
            if (userEarn[_user][i].isAutoEarn) {
                earn(_user, userEarn[_user][i].protocol, userEarn[_user][i].autoEarnAmount);
            }
        }
    }

    function disableAutoEarn(address _user, address _protocol) public {
        for (uint256 i = 0; i < userEarn[_user].length; i++) {
            if (userEarn[_user][i].protocol == _protocol) {
                userEarn[_user][i].isAutoEarn = false;
                userEarn[_user][i].autoEarnAmount = 0;
            }
        }
        emit DisableAutoEarn(_user, _protocol);
    }

    function earn(address _user, address _protocol, uint256 _amount) public nonReentrant returns (uint256) {
        //***** PROTECTION */
        if (!IFactory(factory).isEarnProtocol(_protocol)) revert EarnProtocolNotGranted(); // earn protocol owner must provided to prevent leaked data contract guys
        if (!employeeSalary[_user].status) revert EmployeeNotActive();
        uint256 realizedSalary = _currentSalary(_user);
        if (realizedSalary < _amount) revert InsufficientSalary();
        //******************/

        address earnStandard = IFactory(factory).earnStandard();
        IERC20(token).approve(earnStandard, _amount);
        uint256 shares = IEarnStandard(earnStandard).execEarn(_protocol, token, _user, _amount);
        for (uint256 i = 0; i < userEarn[_user].length; i++) {
            if (userEarn[_user][i].protocol == _protocol) {
                userEarn[_user][i].shares += shares;
                employeeSalary[_user].unrealizedSalary += (realizedSalary - _amount);
                employeeSalary[_user].startStream = block.timestamp;
                emit EarnSalary(_user, _protocol, _amount, shares);
                return shares;
            }
        }
        userEarn[_user].push(Earn({protocol: _protocol, shares: shares, autoEarnAmount: 0, isAutoEarn: false}));
        employeeSalary[_user].unrealizedSalary += (realizedSalary - _amount);
        employeeSalary[_user].startStream = block.timestamp;
        emit EarnSalary(_user, _protocol, _amount, shares);
        return shares;
    }

    function withdrawEarn(address _user, address _protocol, uint256 _shares, bool isOfframp) public nonReentrant {
        //***** PROTECTION */
        if (!IFactory(factory).isEarnProtocol(_protocol)) revert EarnProtocolNotGranted();
        if (!employeeSalary[_user].status) revert EmployeeNotActive();
        //******************/

        for (uint256 i = 0; i < userEarn[_user].length; i++) {
            if (userEarn[_user][i].protocol == _protocol) {
                if (userEarn[_user][i].shares < _shares) revert InsufficientShares();
                userEarn[_user][i].shares -= _shares;
            }
        }
        address earnStandard = IFactory(factory).earnStandard();
        uint256 amount = IEarnStandard(earnStandard).withdrawEarn(_protocol, token, _user, _shares);

        if (isOfframp) {
            IBurn(token).burn(_user, amount);
        } else {
            IERC20(token).safeTransfer(_user, amount);
        }
        emit Withdraw(_user, amount, employeeSalary[_user].unrealizedSalary, isOfframp, employeeSalary[_user].startStream);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOrganization {
    //** READ */
    function owner() external view returns (address);
    function token() external view returns (address);
    function factory() external view returns (address);
    function periodTime() external view returns (uint256);
    function employees(uint256 index) external view returns (address);
    function employeeSalary(address _employee) external view returns (uint256, uint256, bool);
    function userEarn(address _user, uint256 index) external view returns (address, uint256);
    //** WRITE */
    function setEmployeeSalary(string memory _name, address _employee, uint256 _salary) external;
    function setEmployeeStatus(address _employee, bool _status) external;
    function setPeriodTime(uint256 _periodTime) external;
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount, bool isOfframp) external;
    function withdrawAll(bool isOfframp) external;
    function earn(address _protocol, uint256 _amount) external returns (uint256);
    function withdrawEarn(address _protocol, uint256 _shares, bool isOfframp) external;
}

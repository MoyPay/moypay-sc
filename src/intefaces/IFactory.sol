// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFactory {
    //** READ */
    function earnStandard() external view returns (address);
    //** WRITE */
    function isEarnProtocol(address _earnProtocol) external view returns (bool);
    function createOrganization(address _token) external returns (address);
    function addEarnProtocol(address _earnProtocol) external;
    function removeEarnProtocol(address _earnProtocol) external;
    function setEarnStandard(address _earnStandard) external;
}

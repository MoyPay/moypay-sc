// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFactory {
    function isEarnProtocol(address _earnProtocol) external view returns (bool);
    function createOrganization(address _token) external;
    function addEarnProtocol(address _earnProtocol) external;
    function removeEarnProtocol(address _earnProtocol) external;
    function setEarn(address _earn) external;
}
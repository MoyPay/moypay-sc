// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Organization} from "./Organization.sol";

contract Factory {
    // Events
    event OrganizationCreated(address indexed owner, address indexed organization, address token);
    event EarnProtocolAdded(address indexed earnProtocol);
    event EarnProtocolRemoved(address indexed earnProtocol);
    event EarnStandardSet(address indexed earnStandard);

    address public owner;
    mapping(address => address[]) public organizations;
    address public earnStandard;
    address[] public earnProtocol;
    mapping(address => bool) public isEarnProtocol;

    constructor() {
        owner = msg.sender;
    }

    function createOrganization(address _token, string memory _name) public returns (address) {
        Organization organization = new Organization(_token, address(this), msg.sender, _name);
        organizations[msg.sender].push(address(organization));
        emit OrganizationCreated(msg.sender, address(organization), _token);
        return address(organization);
    }

    function addEarnProtocol(address _earnProtocol) public {
        earnProtocol.push(_earnProtocol);
        isEarnProtocol[_earnProtocol] = true;
        emit EarnProtocolAdded(_earnProtocol);
    }

    function removeEarnProtocol(address _earnProtocol) public {
        for (uint256 i = 0; i < earnProtocol.length; i++) {
            if (earnProtocol[i] == _earnProtocol) {
                earnProtocol[i] = earnProtocol[earnProtocol.length - 1];
                earnProtocol.pop();
                isEarnProtocol[_earnProtocol] = false;
                break;
            }
        }
        emit EarnProtocolRemoved(_earnProtocol);
    }

    function setEarnStandard(address _earnStandard) public {
        earnStandard = _earnStandard;
        emit EarnStandardSet(_earnStandard);
    }
}

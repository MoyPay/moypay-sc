// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Organization} from "./Organization.sol";

contract Factory {
    address public owner;
    mapping(address => address[]) public organizations;
    address public earn;
    address[] public earnProtocol;
    mapping(address => bool) public isEarnProtocol;

    constructor() {
        owner = msg.sender;
    }

    function createOrganization(address _token) public {
        Organization organization = new Organization(_token, address(this));
        organizations[msg.sender].push(address(organization));
    }

    function addEarnProtocol(address _earnProtocol) public {
        earnProtocol.push(_earnProtocol);
        isEarnProtocol[_earnProtocol] = true;
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
    }

    function setEarn(address _earn) public {
        earn = _earn;
    }
}

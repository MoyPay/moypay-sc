// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OrganizationDeployer} from "./OrganizationDeployer.sol";

contract Factory {
    // Events
    event OrganizationCreated(address indexed owner, address indexed organization, address token, string name);
    event EarnProtocolAdded(address indexed earnProtocol);
    event EarnProtocolRemoved(address indexed earnProtocol);
    event EarnStandardSet(address indexed earnStandard);

    address public owner;
    mapping(address => address[]) public organizations;
    address public earnStandard;
    address[] public earnProtocol;
    mapping(address => bool) public isEarnProtocol;
    OrganizationDeployer public organizationDeployer;

    constructor() {
        owner = msg.sender;
        organizationDeployer = new OrganizationDeployer();
    }

    function createOrganization(address _token, string memory _name) public returns (address) {
        address organization = organizationDeployer.deployOrganization(_token, address(this), msg.sender, _name);
        organizations[msg.sender].push(organization);
        emit OrganizationCreated(msg.sender, organization, _token, _name);
        return organization;
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

    function setOrganizationDeployer(address _organizationDeployer) public {
        require(msg.sender == owner, "Only owner can set deployer");
        organizationDeployer = OrganizationDeployer(_organizationDeployer);
    }
}

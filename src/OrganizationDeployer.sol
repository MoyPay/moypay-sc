// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Organization} from "./Organization.sol";

contract OrganizationDeployer {
    /**
     * @dev Deploys a new Organization contract
     * @param _token The token address for the organization
     * @param _factory The factory contract address
     * @param _owner The owner of the organization
     * @param _name The name of the organization
     * @return The address of the deployed Organization contract
     */
    function deployOrganization(
        address _token,
        address _factory,
        address _owner,
        string memory _name
    ) external returns (address) {
        Organization organization = new Organization(_token, _factory, _owner, _name);
        return address(organization);
    }
}

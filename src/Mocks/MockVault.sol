// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;
    address public token;

    mapping(address => uint256) public shares;

    constructor() {
        owner = msg.sender;
    }

    function deposit(uint256 _amount, address _user) public nonReentrant returns (uint256) {
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        shares[_user] += _amount;
        return shares[_user];
    }

    function withdraw(uint256 _shares, address _user) public nonReentrant returns (uint256) {
        IERC20(token).transfer(msg.sender, _shares);
        shares[_user] -= _shares;
        return shares[_user]; // return shares
    }
}

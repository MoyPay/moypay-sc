// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;

    mapping(address => uint256) public userShares;
    mapping(address => uint256) public totalShares; // token => totalShares

    constructor() {
        owner = msg.sender;
    }

    function deposit(address _token, uint256 _amount, address _user) public nonReentrant returns (uint256) {
        uint256 totalSupplyAssets = IERC20(_token).balanceOf(address(this));
        uint256 shares = 0;
        if (totalSupplyAssets == 0) {
            shares += _amount;
        } else {
            shares = (_amount * totalShares[_token]) / totalSupplyAssets;
        }
        userShares[_user] += shares;
        totalShares[_token] += shares;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        return shares;
    }

    function withdraw(address _token, uint256 _shares, address _user) public nonReentrant returns (uint256) {
        uint256 totalSupplyAssets = IERC20(_token).balanceOf(address(this));
        uint256 amount = (_shares * totalSupplyAssets) / totalShares[_token];
        IERC20(_token).safeTransfer(msg.sender, amount);
        userShares[_user] -= _shares;
        totalShares[_token] -= _shares;
        return userShares[_user]; // return shares
    }

    function distributeReward(address _token, uint256 _amount) public nonReentrant {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }
}

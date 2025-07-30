// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMint} from "../intefaces/IMint.sol";

contract MockVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Events
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, address indexed token, uint256 shares, uint256 amount);
    event RewardDistributed(address indexed token, uint256 amount);
    event SetVaultName(string name);

    error InsufficientShares();
    error InvalidAmount();

    address public owner;

    string public name;

    mapping(address => uint256) public userShares;
    mapping(address => uint256) public totalShares; // token => totalShares

    constructor(string memory _name) {
        owner = msg.sender;
        setName(_name);
    }

    function deposit(address _token, uint256 _amount, address _user) public nonReentrant returns (uint256) {
        if (_amount == 0) revert InvalidAmount();

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
        IMint(_token).mint(address(this), _amount * 1 / 100);
        emit Deposit(_user, _token, _amount, shares);
        return shares;
    }

    function withdraw(address _token, uint256 _shares, address _user) public nonReentrant returns (uint256) {
        if (_shares == 0) revert InvalidAmount();
        if (userShares[_user] < _shares) revert InsufficientShares();

        uint256 totalSupplyAssets = IERC20(_token).balanceOf(address(this));
        uint256 amount = (_shares * totalSupplyAssets) / totalShares[_token];

        // IERC20(_token).approve(msg.sender, amount);
        IERC20(_token).safeTransfer(msg.sender, amount);
        userShares[_user] -= _shares;
        totalShares[_token] -= _shares;
        IMint(_token).mint(address(this), _shares * 1 / 100);
        emit Withdraw(_user, _token, _shares, amount);
        return amount; // return shares
    }

    function distributeReward(address _token, uint256 _amount) public nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IMint(_token).mint(address(this), _amount * 1 / 100);
        emit RewardDistributed(_token, _amount);
    }

    function setName(string memory _name) public {
        name = _name;
        emit SetVaultName(_name);
    }
}

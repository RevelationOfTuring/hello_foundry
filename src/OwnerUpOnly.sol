// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract OwnerUpOnly {
    error Unauthorized();

    address public immutable owner;
    uint256 public count;

    constructor() {
        owner = msg.sender;
    }

    function increment() external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        count++;
    }
}

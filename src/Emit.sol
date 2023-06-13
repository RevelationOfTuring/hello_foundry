// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Emit {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function emitEvent() public {
        emit Transfer(msg.sender, address(1024), 2048);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract Cheatcode is Test {
    function TxGasPrice() external {
        console2.log("current tx gas price: %d", block.chainid);
        vm.txGasPrice(1024);
        console2.log("current tx gas price: %d", block.chainid);
    }

    function test_ChainId() external {
        console2.log("current chainId: %d", block.chainid);
        vm.chainId(1024);
        console2.log("current chainId: %d", block.chainid);
    }

    function test_Warp() external {
        console2.log("current timestamp: %d", block.timestamp);
        vm.warp(1024);
        console2.log("current timestamp: %d", block.timestamp);
    }

    function test_Roll() external {
        console2.log("current block number: %d", block.number);
        vm.roll(1024);
        console2.log("current block number: %d", block.number);
    }

    function test_Fee() external {
        console2.log("current base fee: %d", block.basefee);
        vm.fee(1024 gwei);
        console2.log("current base fee: %d", block.basefee);
    }

//    function testFail_Difficulty() external {
//        // difficulty在Paris升级后已经被遗弃，在其之前的EVM版本可以使用
//        // Paris升级后换做使用block.prevrandao
//        console2.log("current difficulty: %d", block.difficulty);
//        vm.difficulty(1024);
//        console2.log("current difficulty: %d", block.difficulty);
//    }

    function test_Prevrandao() external {
        console2.log("current prevrandao: %d", block.prevrandao);
        vm.prevrandao(bytes32(uint(1024)));
        console2.log("current prevrandao: %d", block.prevrandao);
    }
}

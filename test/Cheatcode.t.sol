// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract Demo {
    uint public varSlot0 = 1;
    // private
    uint  varSlot1 = 2;
}

contract Cheatcode is Test {
    function test_SetAndGetNonce() external {
        assertEq(vm.getNonce(address(0)), 0);
        vm.setNonce(address(0), 1024);
        assertEq(vm.getNonce(address(0)), 1024);
        // 对于同一个地址，只能set同当前相等或者更大的nonce
        vm.expectRevert(bytes("New nonce (1023) must be strictly equal to or higher than the account's current nonce (1024)."));
        vm.setNonce(address(0), 1024 - 1);

        // 对于同一个地址，如果想随意设置nonce，请使用vm.setNonceUnsafe()
        vm.setNonceUnsafe(address(0), 1024 - 1);
        assertEq(vm.getNonce(address(0)), 1024 - 1);

        // eoa地址的nonce归0，合约地址nonce归1。使用vm.resetNonce()
        // eoa
        vm.resetNonce(address(0));
        assertEq(vm.getNonce(address(0)), 0);

        // contract
        Demo demo = new Demo();
        assertEq(vm.getNonce(address(demo)), 0);
        vm.resetNonce(address(demo));
        assertEq(vm.getNonce(address(demo)), 1);
    }

    function test_StoreAndLoad() external {
        Demo demo = new Demo();
        assertEq(demo.varSlot0(), 1);
        // 指定合约地址和slot位置，设置里面的值
        // slot 0
        vm.store(address(demo), bytes32(uint(0)), bytes32(uint(1024)));
        assertEq(demo.varSlot0(), 1024);

        // 读取private变量值
        bytes32 value = vm.load(address(demo), bytes32(uint(1)));
        assertEq(uint(value), 2);
    }

    function test_TxGasPrice() external {
        // 设置tx.gasprice
        assertEq(tx.gasprice, 0);
        vm.txGasPrice(1 gwei);
        assertEq(tx.gasprice, 1 gwei);

        uint gasBegin1 = gasleft();
        uint a = 1;
        a++;
        uint gasFeeUsedFee1 = (gasBegin1 - gasleft()) * tx.gasprice;

        vm.txGasPrice(2 gwei);
        uint gasBegin2 = gasleft();
        uint b = 2;
        b++;
        uint gasFeeUsedFee2 = (gasBegin2 - gasleft()) * tx.gasprice;
        // 两次操作的gas fee正好是2倍关系
        assertEq(gasFeeUsedFee2 / gasFeeUsedFee1, 2);
        assertEq(gasFeeUsedFee2 % gasFeeUsedFee1, 0);
    }

    function test_ChainId() external {
        assertEq(block.chainid, 31337);
        vm.chainId(1024);
        assertEq(block.chainid, 1024);
    }

    function test_Warp() external {
        assertEq(block.timestamp, 1);
        vm.warp(1024);
        assertEq(block.timestamp, 1024);
    }

    function test_Roll() external {
        assertEq(block.number, 1);
        vm.roll(1024);
        assertEq(block.number, 1024);
    }

    function test_Fee() external {
        assertEq(block.basefee, 0);
        vm.fee(1024 gwei);
        assertEq(block.basefee, 1024 gwei);
    }

    //    function testFail_Difficulty() external {
    //        // difficulty在Paris升级后已经被遗弃，在其之前的EVM版本可以使用
    //        // Paris升级后换做使用block.prevrandao
    //        console2.log("current difficulty: %d", block.difficulty);
    //        vm.difficulty(1024);
    //        console2.log("current difficulty: %d", block.difficulty);
    //    }

    function test_Prevrandao() external {
        assertEq(block.prevrandao, 0);
        vm.prevrandao(bytes32(uint(1024)));
        assertEq(block.prevrandao, 1024);
    }
}

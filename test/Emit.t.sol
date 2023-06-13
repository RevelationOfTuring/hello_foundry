// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Emit.sol";

contract EmitTest is Test {
    // 定义一个与被测试合约的event一样的event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function test_ExpectEmit() public {
        Emit e = new Emit();
        // 表示我们要对Topic1,Topic2（两个index修饰的变量）以及Data中的信息（不被index修饰）进行比对
        // 由于Emit.Transfer中只有两个被index修饰的变量，所以无须关注Topic3——vm.expectEmit的第三个参数置为false
        vm.expectEmit(true, true, false, true);
        // 我们期望抛出的event
        emit Transfer(address(this), address(1024), 2048);
        // 调用被测试合约的方法，抛出event
        e.emitEvent();
    }

    function test_ExpectEmit_DoNotCheckData() public {
        Emit e = new Emit();
        // 这里我们只关注Topic 1和Topic 2，并不关注data中的数据(不带index的)
        vm.expectEmit(true, true, false, false);
        // 不带index的参数随便写个0
        emit Transfer(address(this), address(1024), 0);
        // 调用被测试合约的方法，抛出event
        e.emitEvent();
    }
}

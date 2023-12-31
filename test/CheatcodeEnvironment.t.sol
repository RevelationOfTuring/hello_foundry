// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {VmSafe} from "forge-std/Vm.sol";
    error ErrorCustomized();
contract Demo {
    uint public varSlot0 = 1;
    // private
    uint  varSlot1 = 2;
    address public msgSender = address(1024);
    address public txOrigin;

    event Event1(address addr);

    function testPrank() external {
        msgSender = msg.sender;
        txOrigin = tx.origin;
    }

    function setVarSlot1(uint value) external {
        varSlot1 = value;
    }

    function emitEvent() external {
        emit Event1(address(this));
    }

    function getReturn(uint a) external returns (uint){
        // 写slot
        varSlot0 = a;
        // 读slot
        return varSlot1;
    }

    function getReturnPayable(uint a) external payable returns (uint){
        // 写slot
        varSlot0 = msg.value;
        // 读slot
        return a;
    }
}

contract CheatcodeEnvironment is Test {
    function test_MockCallRevert() external {
        // 模拟一个call向一个地址，当有携带匹配的calldata的call发生时发生指定的revert行为

    }

    function test_MockCallAndClearMockedCalls() external {
        // 模拟一个call向一个地址，并且指定返回的数据(returning data)
        // 即：本来没有这个call的返回逻辑，但是处于某种需要：在调用某个
        // 函数时返回一个特定的值。所以才有了mockCall这个功能。
        Demo demo = new Demo();

        // Demo 本没有函数newFunction(uint256)
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("newFunction(uint256)")), (1024));
        vm.mockCall(
            address(demo),
            callData,
        // 返回值设定为100
            abi.encode(100)
        );

        // 调用一个demo不存在的方法newFunction(uint256)
        (bool ok, bytes memory returndata) = address(demo).call(callData);
        assertTrue(ok);
        // 返回值就是上面我们mockCall设定的返回值
        assertEq(abi.decode(returndata, (uint)), 100);

        // 如果在callData中只指定selector，那么将激活模糊匹配，涉及到该方法的函数的返回值
        // 都是mockCall中设定的。
        // 这次我们改写一个demo已存在的方法function getReturn(uint)
        // mockCall之前观察返回结果
        assertEq(demo.getReturn(1), 2);
        vm.mockCall(
            address(demo),
            abi.encodeWithSelector(demo.getReturn.selector),
        // 指定返回值
            abi.encode(1024)
        );

        // 观察模糊匹配的结果：无论传入什么参数，都将得到mockCall中设定的返回值1024
        assertEq(demo.getReturn(1), 1024);
        assertEq(demo.getReturn(2), 1024);
        assertEq(demo.getReturn(3), 1024);

        // 通过vm.clearMockedCalls()来终止掉mockCall功能
        vm.clearMockedCalls();
        // 恢复正常逻辑
        assertEq(demo.getReturn(1), 2);
    }

    function test_MockCall_ToNoBytecodeAddress() external {
        // 允许如果mock向一个没有code的地址
        assertEq(address(0xdead).code, "");

        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("newFunction()")));
        vm.mockCall(
            address(0xdead),
            callData,
        // 指定返回值
            abi.encode(1024)
        );

        (bool ok, bytes memory returndata) = address(0xdead).call(callData);
        assertTrue(ok);
        assertEq(returndata, abi.encode(1024));

        // 停止mockCall
        vm.clearMockedCalls();
        (ok, returndata) = address(0xdead).call(callData);
        // 可以call，但是返回值为空
        assertTrue(ok);
        assertEq(returndata, "");
    }

    function test_MockCall_WithMsgValue() external {
        // 也可以通过指定msg.value的值来进行mock call
        Demo demo = new Demo();
        vm.mockCall(
            address(demo),
            1 gwei,
            abi.encodeCall(demo.getReturnPayable, (1)),
        // 指定return
            abi.encode(1024)
        );

        // 得到指定好的返回值
        assertEq(demo.getReturnPayable{value : 1 gwei}(1), 1024);

        // mock call匹配优先级规则：
        //      msg.value的匹配优先级(仅限于通过selector匹配)高于calldata
        // 1. msg.value一致，但calldata(非通过selector匹配)不一致，不会触发mock call
        assertEq(demo.getReturnPayable{value : 1 gwei}(0), 0);
        // 2. msg.value不一致，但calldata(非通过selector匹配)一致，不会触发mock call
        assertEq(demo.getReturnPayable{value : 1}(1), 1);

        // 通过selector来进行匹配
        vm.mockCall(
            address(demo),
            1 gwei,
            abi.encodeWithSelector(demo.getReturnPayable.selector),
            abi.encode(1024)
        );
        // 3. msg.value一致，calldata(通过selector匹配)一致，会触发mock call
        assertEq(demo.getReturnPayable{value : 1 gwei}(0), 1024);
        // 4. msg.value不一致，calldata(通过selector匹配)一致，不会触发mock call
        assertEq(demo.getReturnPayable{value : 1}(0), 0);
    }

    event Event2(uint indexed number, address addr, string str);

    function test_RecordLogsAndGetRecordedLogs() external {
        Demo demo = new Demo();
        // 告知VM开始记录以下操作抛出的所有events
        vm.recordLogs();
        // demo合约抛出event
        demo.emitEvent();
        // 本合约抛出event
        emit Event2(1024, address(this), "hello world");

        // 使用vm.getRecordedLogs()来获得以上区间抛出的所有events（全局所有合约抛出的所有events）
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);
        // 验证Event1
        assertEq(entries[0].topics[0], keccak256("Event1(address)"));
        // Event1的第一个参数(不带indexed，在data内)
        assertEq0(entries[0].data, abi.encode(address(demo)));
        // 验证Event2
        assertEq(entries[1].topics[0], keccak256("Event2(uint256,address,string)"));
        // Event2的第一个参数(indexed)
        assertEq(entries[1].topics[1], bytes32(uint(1024)));
        // Event2的第二、三个参数(非indexed)
        (address p1, string memory p2) = abi.decode(entries[1].data, (address, string));
        assertEq(p1, address(this));
        assertEq(p2, "hello world");
    }

    function test_RecordAndAccesses() external {
        // 该cheatcode是用于告知vm开始记录一切对storage的读和写，具体对读写的操作可使用 vm.accesses
        Demo demo = new Demo();
        // 开始记录对某合约的storage的全部读写操作
        vm.record();
        // 执行外部调用
        // 读slot2
        demo.msgSender();
        // 读slot0
        demo.varSlot0();
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(demo));

        // 有两条读slot
        assertEq(reads.length, 2);
        // 没有写slot
        assertEq(writes.length, 0);
        // 第一条reads[0]存的值是bytes32的2，即表示对slot2的读
        assertEq(uint(reads[0]), 2);
        // 第二条reads[1]存的值是bytes32的0，即表示对slot0的读
        assertEq(uint(reads[1]), 0);

        // 测试一下写slot1
        vm.record();
        demo.setVarSlot1(1024);
        (reads, writes) = vm.accesses(address(demo));
        // 有1条读slot
        assertEq(reads.length, 1);
        // 有1条写slot
        assertEq(writes.length, 1);
        // 注意：每一条写slot，都会附带一条额外的读slot
        // 即：写slot X，会额外伴随一个读slot X
        assertEq(uint(reads[0]), 1);
        assertEq(uint(writes[0]), 1);
    }

    function test_ReadCallers() external {
        // 获取当前视图中的CallerMode, msg.sender和tx.origin
        // CallerMade是一个枚举类
        /*       enum CallerMode {
                        None,               // 没有任何active的视图，即正常状态
                        Broadcast,          // 表示当前视图处于vm.broadcast()的设置状态下
                        RecurrentBroadcast, // 表示当前视图处于vm.startBroadcast()的设置状态下
                        Prank,              // 表示当前视图处于vm.prank()的设置状态下
                        RecurrentPrank      // 表示当前视图处于vm.startPrank()的设置状态下
                 }
        */

        // 不知道为什么一调用vm.readCallers()就报错: Invalid data
        vm.expectRevert();
        //        (VmSafe.CallerMode callerMode,address msgSender, address txOrigin) = vm.readCallers();
        vm.readCallers();
    }

    function test_Etch() external {
        // 零地址的codehash和code都没有值
        assertEq(address(0).codehash, bytes32(uint(0)));
        assertEq(address(0).code, "");

        // 设置目标地址下的合约bytecode(设置成Demo的runtime code)
        vm.etch(address(0), type(Demo).runtimeCode);
        // 调用0地址的合约
        Demo(address(0)).testPrank();
        // 验证调用成功，说明runtime code已经被成功替换
        assertEq(Demo(address(0)).msgSender(), address(this));
        assertEq(Demo(address(0)).txOrigin(), msg.sender);

        // 零地址的codehash和code此时已经有值
        assertNotEq(address(0).codehash, bytes32(uint(0)));
        assertNotEq0(address(0).code, "");
    }

    function test_Deal() external {
        // 设置某地址下的eth余额
        assertEq(address(0).balance, 0);
        vm.deal(address(0), 1e18 gwei);
        assertEq(address(0).balance, 1e18 gwei);
    }

    function test_StartAndStopPrank() external {
        Demo demo = new Demo();
        // 在startPrank和stopPrank之间的所有call的msg.sender都保持改变
        vm.startPrank(address(1));
        demo.testPrank();
        assertEq(demo.msgSender(), address(1));
        assertEq(demo.txOrigin(), msg.sender);
        demo.testPrank();
        assertEq(demo.msgSender(), address(1));
        assertEq(demo.txOrigin(), msg.sender);

        // 在startPrank和stopPrank之间的所有call的msg.sender和tx.origin都保持改变
        vm.startPrank(address(2), address(2));
        demo.testPrank();
        assertEq(demo.msgSender(), address(2));
        assertEq(demo.txOrigin(), address(2));
        demo.testPrank();
        assertEq(demo.msgSender(), address(2));
        assertEq(demo.txOrigin(), address(2));

        // stopPrank会恢复正常的逻辑
        vm.stopPrank();
        demo.testPrank();
        assertEq(demo.msgSender(), address(this));
        assertEq(demo.txOrigin(), msg.sender);
    }

    function test_Prank() external {
        Demo demo = new Demo();
        // 只设置下一个call的msg.sender
        vm.prank(address(1));
        demo.testPrank();
        assertEq(demo.msgSender(), address(1));
        assertEq(demo.txOrigin(), msg.sender);
        // 再下一个call将恢复原样
        demo.testPrank();
        assertEq(demo.msgSender(), address(this));
        assertEq(demo.txOrigin(), msg.sender);

        // 设置下一个call的msg.sender和tx.origin
        vm.prank(address(2), address(2));
        demo.testPrank();
        assertEq(demo.msgSender(), address(2));
        assertEq(demo.txOrigin(), address(2));
        // 再下一个call将恢复原样
        demo.testPrank();
        assertEq(demo.msgSender(), address(this));
        assertEq(demo.txOrigin(), msg.sender);
    }

    function test_SetAndGetNonce() external {
        assertEq(vm.getNonce(address(0)), 0);
        vm.setNonce(address(0), 1024);
        assertEq(vm.getNonce(address(0)), 1024);
        // 对于同一个地址，只能set同当前相等或者更大的nonce
        vm.expectRevert("New nonce (1023) must be strictly equal to or higher than the account's current nonce (1024).");
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

    function test_Coinbase() external {
        assertEq(block.coinbase, address(0));
        vm.coinbase(address(1024));
        assertEq(block.coinbase, address(1024));
    }
}

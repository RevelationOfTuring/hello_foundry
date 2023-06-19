// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

    error ErrorCustomized();
contract Demo {
    address _varAddress;
    uint _varUint;

    event Event1(address indexed from, address indexed to, uint amount);
    event Event2(address indexed from, address indexed to, uint indexed amount);

    function revertCall(uint flag) pure external {
        require(flag > 0, "require revert msg");
        if (flag == 1) {
            revert();
        } else if (flag == 2) {
            revert ErrorCustomized();
        } else {
            revert("revert msg");
        }
    }

    function emitEvents(address demoOtherAddr) external {
        emit Event1(address(1), address(1), 1);
        // emit events from other contract
        DemoOther(demoOtherAddr).EmitEvent();
        emit Event2(address(2), address(2), 2);
    }

    function makeCall(uint i, address addr) public {
        _varAddress = addr;
        _varUint = i;
    }

    function makeCallPayable(uint i) payable external {
        _varUint = i + msg.value;
    }
}

contract DemoOther {
    event Event3(address indexed from, address to, uint amount, bytes signature);

    function EmitEvent() external {
        emit Event3(address(3), address(3), 3, "signature");
    }
}

contract CheatcodeAssertion is Test {
    Demo demo;
    DemoOther demoOther;

    // copy the event ourselves with an identical event signature
    event Event1(address indexed from, address indexed to, uint amount);
    event Event2(address indexed from, address indexed to, uint indexed amount);
    event Event3(address indexed from, address to, uint amount, bytes signature);

    function setUp() external {
        demo = new Demo();
        demoOther = new DemoOther();
    }

    function test_ExpectCall() external {
        // 1. expectCall用于检测下面的操作中是否存在具体对一个地址的call操作，并且可以指定calldata
        vm.expectCall(
        // call address
            address(demo),
        // calldata
            abi.encodeCall(demo.makeCall, (1, address(1)))
        );

        // 调用
        demo.makeCall(1, address(1));

        // 2. vm.expectCall可以检测到函数内部对外面的call的调用
        // demo.emitEvents方法中包含了对demoOther.EmitEvent()的调用
        vm.expectCall(
        // target address
            address(demoOther),
        // calldata
            abi.encodeCall(demoOther.EmitEvent, ())
        );

        demo.emitEvents(address(demoOther));
    }

    function test_ExpectCall_WithCount() external {
        // 1. vm.expectCall可以设置目标call期待出现调用次数
        vm.expectCall(
        // target address
            address(demoOther),
        // calldata
            abi.encodeCall(demoOther.EmitEvent, ()),
        // 至少有2次这样的call
            2
        );

        // 第1次
        demo.emitEvents(address(demoOther));
        // 第2次
        demoOther.EmitEvent();
    }

    function testFail_ExpectCall_WithCount0() external {
        // 指定vm.expectCall的count为0，表示以下call中不包含目标call
        // 如果以下call中包含了目标call，那么revert
        vm.expectCall(
            address(demoOther),
            abi.encodeCall(demoOther.EmitEvent, ()),
            0
        );

        // 调用了目标call，用例revert
        demo.emitEvents(address(demoOther));
    }

    function test_ExpectCall_CallTheSameCheatcodeTwice() external {
        vm.expectCall(
            address(demo),
            abi.encodeCall(demo.makeCall, (1, address(1))),
            2
        );

        // 调用了2次
        demo.makeCall(1, address(1));
        demo.makeCall(1, address(1));


        vm.expectRevert("Counted expected calls can only bet set once.");
        // 再一次调用完全相同的Cheatcode(目标地址和calldata都一样)，revert
        vm.expectCall(
            address(demo),
            abi.encodeCall(demo.makeCall, (1, address(1))),
            3
        );
    }

    function test_ExpectCall_LooselyMatch() external {
        // 如果制制定了目标call，那么首先会精确检查以下call所有传参是否匹配
        // 如果一旦没有拼配，那么会做loosely match，即检查calldata的第一个
        // 字节的匹配（即方法selector）。这个特性可以用于检查对于某个合约的
        // 方法的调用次数（不去匹配对应参数）
        vm.expectCall(
            address(demo),
            abi.encodeWithSelector(demo.makeCall.selector),
            2
        );

        // 第1次
        demo.makeCall(2, address(2));
        // 第2次
        demo.makeCall(1, address(1));
    }

    function test_ExpectCall_WithMsgValue() external {
        // 用法囊括了上面介绍的expectCall的全部，同时多出一个参数用于检测
        // 调用call时候的msg.value
        vm.expectCall(
            address(demo),
            1 gwei,
            abi.encodeCall(demo.makeCallPayable, (1024))
        );

        // 带msg.value调用
        demo.makeCallPayable{value : 1 gwei}(1024);
    }

    function test_ExpectCall_WithMsgValueAndCount() external {
        // 期待指定目标call的次数
        vm.expectCall(
            address(demo),
            2 gwei,
            abi.encodeCall(demo.makeCallPayable, (1024)),
            3
        );

        // 3次调用
        demo.makeCallPayable{value : 2 gwei}(1024);
        demo.makeCallPayable{value : 2 gwei}(1024);
        demo.makeCallPayable{value : 2 gwei}(1024);
    }

    function test_ExpectCall_WithMsgValueAndGasAndCount() external {
        // 期待指定目标call的次数,msg.value和传入的gas
        uint64 gasExpected = 30000;
        vm.expectCall(
            address(demo),
            2 gwei,
            gasExpected,
            abi.encodeCall(demo.makeCallPayable, (1024)),
            2
        );

        // 2次调用
        // NOTE:如果传入的gas不一致，则不会计入统计
        demo.makeCallPayable{value : 2 gwei, gas : gasExpected}(1024);
        demo.makeCallPayable{value : 2 gwei, gas : gasExpected}(1024);
    }

    function test_expectCallMinGas_WithMsgValueAndGasAndCount() external {
        // 期待指定目标call的次数,msg.value和传入的最低的gas下限
        uint64 gasMin = 30000;
        vm.expectCallMinGas(
            address(demo),
            2 gwei,
            gasMin,
            abi.encodeCall(demo.makeCallPayable, (1024)),
            2
        );

        // 3次调用，2次符合预期，1次不符合预期
        // 传入gas正好等于gasMin（符合预期）
        demo.makeCallPayable{value : 2 gwei, gas : gasMin}(1024);
        // 传入gas大于gasMin（符合预期）
        demo.makeCallPayable{value : 2 gwei, gas : gasMin + 1}(1024);
        // 传入gas下图gasMin（不符合预期）
        demo.makeCallPayable{value : 2 gwei, gas : gasMin - 1}(1024);
    }

    function test_ExpectRevert() external {
        // check require revert msg
        vm.expectRevert("require revert msg");
        demo.revertCall(0);

        // check revert
        vm.expectRevert();
        demo.revertCall(1);

        // check revert with error
        vm.expectRevert(ErrorCustomized.selector);
        demo.revertCall(2);

        // check revert with msg
        vm.expectRevert("revert msg");
        demo.revertCall(3);
    }

    function test_ExpectEmit_WithoutEmittingAddress() external {
        // 对于多个events：按照抛出顺序抛出期望的events及参数
        vm.expectEmit();
        emit Event1(address(1), address(1), 1);
        vm.expectEmit();
        emit Event3(address(3), address(3), 3, "signature");
        vm.expectEmit();
        emit Event2(address(2), address(2), 2);
        // 调用被测试函数
        demo.emitEvents(address(demoOther));

        // 对于多个events：也可以只检验我们关注的个别events。
        // 需要按照抛出顺序来定义期望的events
        vm.expectEmit();
        emit Event1(address(1), address(1), 1);
        vm.expectEmit();
        emit Event2(address(2), address(2), 2);
        demo.emitEvents(address(demoOther));

        // 如果测试中只想关注event中的个别参数的一致性
        // 只关注Topic1和Data的数据，并不关注Topic2，所以第二个参数设为false
        vm.expectEmit(true, false, false, true);
        // 以上表示要对Topic1,Topic2（两个indexed修饰的变量）以及Data中的信息（不被indexed修饰的变量）
        // 进行比对。由于Event1中只有两个被indexed修饰的变量，所以无须关注Topic3，即vm.expectEmit的第三个参数置为false
        emit Event1(address(1), address(1e18), 1);
        demo.emitEvents(address(demoOther));

        // event中有多个不被indexed修饰的参数
        vm.expectEmit(false, true, false, true);
        emit Event3(address(3e18), address(3), 3, "signature");
        demo.emitEvents(address(demoOther));
    }

    function testFail_ExpectEmit_WithoutEmittingAddress_OutOfOrder() external {
        // 对于多个events：如果不按照抛出顺序抛出期望的events及参数，测试用例会fail
        vm.expectEmit();
        emit Event1(address(1), address(1), 1);
        vm.expectEmit();
        emit Event2(address(2), address(2), 2);
        // 期待Event3与Event2的顺序与被测试函数抛出events顺序不一致
        vm.expectEmit();
        emit Event3(address(3), address(3), 3, "signature");

        // 调用被测试函数
        demo.emitEvents(address(demoOther));
    }


    function test_ExpectEmit_WithEmittingAddress() external {
        // 一次调用可能导致不同合约抛出不同的events，可以指定对应的合约地址
        // 进行更细粒度的event检查
        vm.expectEmit(address(demo));
        emit Event1(address(1), address(1), 1);
        vm.expectEmit(address(demoOther));
        emit Event3(address(3), address(3), 3, "signature");
        vm.expectEmit(address(demo));
        emit Event2(address(2), address(2), 2);
        demo.emitEvents(address(demoOther));

        // 可以携带抛出event合约地址的个别event参数的检验
        // 使用：function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter) external
        vm.expectEmit(false, false, false, true, address(demoOther));
        // 以上表示要对Topic1,Topic2（两个indexed修饰的变量）以及Data中的信息（不被indexed修饰的变量）
        // 进行比对。由于Event1中只有两个被indexed修饰的变量，所以无须关注Topic3，即vm.expectEmit的第三个参数置为false
        emit Event3(address(3e18), address(3), 3, "signature");
        demo.emitEvents(address(demoOther));
    }

    function testFail_ExpectEmit_WithEmittingAddress_OutOfOrderAndWrongEmittingAddress() external {
        // 对于多个events：如果不按照抛出顺序抛出期望的events及参数，测试用例会fail
        vm.expectEmit(address(demo));
        emit Event2(address(2), address(2), 2);
        // 期待的Event3和Event2的顺序与被测试函数抛出events顺序不一致
        vm.expectEmit(address(demoOther));
        emit Event3(address(3), address(3), 3, "signature");

        // 调用被测试函数
        demo.emitEvents(address(demoOther));
    }
}

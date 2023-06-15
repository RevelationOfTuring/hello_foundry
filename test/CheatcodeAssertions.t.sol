// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

    error ErrorCustomized();
contract Demo {
    event Event1(address indexed from, address indexed to, uint amount);
    event Event2(address indexed from, address indexed to, uint indexed amount);

    function Revert(uint flag) pure external {
        require(flag > 0, "require revert msg");
        if (flag == 1) {
            revert();
        } else if (flag == 2) {
            revert ErrorCustomized();
        } else {
            revert("revert msg");
        }
    }

    function EmitEvents(address demoOtherAddr) external {
        emit Event1(address(1), address(1), 1);
        // emit events from other contract
        DemoOther(demoOtherAddr).EmitEvent();
        emit Event2(address(2), address(2), 2);
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

    function test_ExpectRevert() external {
        // check require revert msg
        vm.expectRevert("require revert msg");
        demo.Revert(0);

        // check revert
        vm.expectRevert();
        demo.Revert(1);

        // check revert with error
        vm.expectRevert(ErrorCustomized.selector);
        demo.Revert(2);

        // check revert with msg
        vm.expectRevert("revert msg");
        demo.Revert(3);
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
        demo.EmitEvents(address(demoOther));

        // 对于多个events：也可以只检验我们关注的个别events。
        // 需要按照抛出顺序来定义期望的events
        vm.expectEmit();
        emit Event1(address(1), address(1), 1);
        vm.expectEmit();
        emit Event2(address(2), address(2), 2);
        demo.EmitEvents(address(demoOther));

        // 如果测试中只想关注event中的个别参数的一致性
        // 只关注Topic1和Data的数据，并不关注Topic2，所以第二个参数设为false
        vm.expectEmit(true, false, false, true);
        // 以上表示要对Topic1,Topic2（两个indexed修饰的变量）以及Data中的信息（不被indexed修饰的变量）
        // 进行比对。由于Event1中只有两个被indexed修饰的变量，所以无须关注Topic3，即vm.expectEmit的第三个参数置为false
        emit Event1(address(1), address(1e18), 1);
        demo.EmitEvents(address(demoOther));

        // event中有多个不被indexed修饰的参数
        vm.expectEmit(false, true, false, true);
        emit Event3(address(3e18), address(3), 3, "signature");
        demo.EmitEvents(address(demoOther));
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
        demo.EmitEvents(address(demoOther));
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
        demo.EmitEvents(address(demoOther));

        // 可以携带抛出event合约地址的个别event参数的检验
        // 使用：function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter) external
        vm.expectEmit(false, false, false, true, address(demoOther));
        // 以上表示要对Topic1,Topic2（两个indexed修饰的变量）以及Data中的信息（不被indexed修饰的变量）
        // 进行比对。由于Event1中只有两个被indexed修饰的变量，所以无须关注Topic3，即vm.expectEmit的第三个参数置为false
        emit Event3(address(3e18), address(3), 3, "signature");
        demo.EmitEvents(address(demoOther));
    }

    function testFail_ExpectEmit_WithEmittingAddress_OutOfOrderAndWrongEmittingAddress() external {
        // 对于多个events：如果不按照抛出顺序抛出期望的events及参数，测试用例会fail
        vm.expectEmit(address(demo));
        emit Event2(address(2), address(2), 2);
        // 期待Event3与Event2的顺序与被测试函数抛出events顺序不一致
        vm.expectEmit(address(demoOther));
        emit Event3(address(3), address(3), 3, "signature");

        // 调用被测试函数
        demo.EmitEvents(address(demoOther));
    }
}

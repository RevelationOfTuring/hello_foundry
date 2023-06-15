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
    event Event3(address indexed from, address to, uint amount);

    function EmitEvent() external {
        emit Event3(address(3), address(3), 3);
    }

}

contract CheatcodeAssertion is Test {
    Demo demo;
    DemoOther demoOther;

    function setup() external {
        demo = new Demo();
        demoOther = new DemoOther();
    }

    function test_ExpectEmit() external {

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
}

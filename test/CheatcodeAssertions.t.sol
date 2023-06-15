// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

    error ErrorCustomized();
contract Demo {
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
}

contract CheatcodeEnvironment is Test {

    function test_ExpectEmit() external {

    }

    function test_ExpectRevert() external {
        Demo demo = new Demo();
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

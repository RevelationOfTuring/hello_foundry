// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OwnerUpOnly.sol";

contract OwnerUpOnlyTest is Test {
    OwnerUpOnly public ownerUpOnly;

    function setUp() public {
        ownerUpOnly = new OwnerUpOnly();
    }

    function test_IncrementAsOwner() public {
        assertEq(ownerUpOnly.count(), 0);
        ownerUpOnly.increment();
        assertEq(ownerUpOnly.count(), 1);
    }

    function testFail_IncrementAsNotOwner() external {
        vm.prank(address(1024));
        ownerUpOnly.increment();
    }

    function test_RevertWhen_CallerIsNotOwner() external {
        vm.expectRevert(OwnerUpOnly.Unauthorized.selector);
        vm.prank(address(0));
        ownerUpOnly.increment();
    }
}


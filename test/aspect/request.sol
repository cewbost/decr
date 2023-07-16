// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";

contract TestAspectRequest is AspectTestBase {

  function testTrivial() external {
    Assert.isTrue(true, "should be true");
  }
}

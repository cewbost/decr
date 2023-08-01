// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "truffle/Assert.sol";
import "./base.sol";
import "../../contracts/Bitset.sol";

using { getBit } for bytes;

contract TestAspectApprove is AspectTestBase {

  function afterEach() external {
    purgeApprovers();
    purgeGenerations();
  }
}

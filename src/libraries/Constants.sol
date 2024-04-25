// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

library Constants {
    uint256 internal constant PERCENT_100 = 10000;

    uint256 internal constant PROTOCOL_FEE_TYPE_WITHDRAW = 1;
    uint256 internal constant PROTOCOL_FEE_TYPE_LIQUIDATE = 2;
    uint256 internal constant PROTOCOL_FEE_TYPE_COMPOUND = 3;
    uint256 internal constant PROTOCOL_FEE_TYPE_RANGESTOP = 4;
}

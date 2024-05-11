//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console, console2} from "forge-std/Test.sol";
import {LendingPool} from "../src/lendingpool/LendingPool.sol";
import {StakingRewards} from "../src/lendingpool/StakingRewards.sol";
import {ExtraInterestBearingToken} from "../src/lendingpool/ExtraInterestBearingToken.sol";
import {ERC20Fake} from "./fakes/ERC20Fake.sol";
import {AddressRegistry} from "../src/AddressRegistry.sol";
import {WETH9} from "./mocks/WETH9.sol";
import {Errors} from "./helpers/Errors.sol";
import {DataTypes} from "../src/libraries/types/DataTypes.sol";
import {ReserveGetter} from "./helpers/ReserveGetter.sol";
import {IERC20} from "../src/external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LendingPoolHandler} from "../src/handler/LendingPoolHandler.sol";

contract LendingPoolTestInvariant is Test, Errors {
    using ReserveGetter for LendingPool;
    LendingPoolHandler handler;

    address treasury = makeAddr("Treasury");
    AddressRegistry public address_registery;
    ERC20Fake public btc;
    WETH9 public weth9;

    function setUp() public {
        btc = new ERC20Fake();
        weth9 = new WETH9();
        address_registery = new AddressRegistry(address(weth9));
        address_registery.setAddress(11, treasury);
        handler = new LendingPoolHandler(
            address(address_registery),
            address(weth9),
            btc
        );
        //only using handler now
        targetContract(address(handler));
    }

    //note totalBorrows = sum of all borrows
    function invariant_sumOfBorrowsEqualToTotalBorrow() public view {
        assertLe(handler.getBorrowSums(), handler.getTotalBorrowed());
        // assertGe(handler.getLatestBorrowingIndex(), 0);
    }
}

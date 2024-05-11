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

contract LendingPoolTest is Test, Errors {
    using ReserveGetter for LendingPool;

    address treasury = makeAddr("Treasury");
    AddressRegistry public address_registery;
    LendingPool public lending_pool;
    ERC20Fake public btc;
    WETH9 public weth9;

    function setUp() public virtual {
        btc = new ERC20Fake();
        btc.mint(address(this), 1e30);
        weth9 = new WETH9();
        address_registery = new AddressRegistry(address(weth9));
        lending_pool = new LendingPool(
            address(address_registery),
            address(weth9)
        );
        address_registery.setAddress(11, treasury);
    }
}

contract Contructor is LendingPoolTest {
    function test_setsTheWETH9AndAddressRegisteryCorrectly() public {
        assertEq(lending_pool.addressRegistry(), address(address_registery));
        assertEq(lending_pool.WETH9(), address(weth9));
    }

    function testFuzz_setsAddressRegisteryAndWETH9Correctly(
        address _registery,
        address _weth9
    ) public {
        vm.assume(_registery != address(0));
        vm.assume(_weth9 != address(0));
        LendingPool _lp = new LendingPool(_registery, _weth9);
        assertEq(_lp.addressRegistry(), address(_registery));
        assertEq(_lp.WETH9(), address(_weth9));
    }
}

contract InitReserve is LendingPoolTest {
    function test_cantInitWhenPaused() public {
        //emergency pause all
        lending_pool.emergencyPauseAll();

        //should not work because paused
        vm.expectRevert(abi.encodePacked(LP_IS_PAUSED));
        lending_pool.initReserve(address(btc));

        //then unpause
        lending_pool.unPauseAll();
        lending_pool.initReserve(address(btc));
    }

    function test_cantInitWhenNotOwner() public {
        vm.startPrank(makeAddr("Alice"));
        vm.expectRevert("Ownable: caller is not the owner");
        lending_pool.initReserve(address(btc));
        vm.stopPrank();
    }

    function test_increasesTheReserveId() public {
        uint pr_id = lending_pool.nextReserveId();
        lending_pool.initReserve(address(btc));
        uint nx_id = lending_pool.nextReserveId();
        assertEq(nx_id, pr_id + 1);
    }

    function test_setsReserveData() public {
        uint pr_id = lending_pool.nextReserveId();
        lending_pool.initReserve(address(btc));

        assertEq(ReserveGetter.getId(lending_pool, pr_id), 1);
        assertEq(ReserveGetter.getBorrowingEnabled(lending_pool, pr_id), true);
        assertEq(ReserveGetter.getIsActive(lending_pool, pr_id), true);
        assertEq(ReserveGetter.getIsFrozen(lending_pool, pr_id), false);
        assertEq(
            ReserveGetter.getReserveUnderlyingAsset(lending_pool, pr_id),
            address(btc)
        );
        assertEq(ReserveGetter.getBorrowingIndex(lending_pool, pr_id), 1e18);
        assertEq(ReserveGetter.getCurrentBorrowingRate(lending_pool, pr_id), 0);
        // 8000, 2000, 9000, 5000, 15000
        assertEq(
            ReserveGetter.getUtilizationRateA(lending_pool, pr_id),
            8000e14
        );
        assertEq(
            ReserveGetter.getUtilizationRateB(lending_pool, pr_id),
            9000e14
        );
        assertEq(ReserveGetter.getBorrowingRateA(lending_pool, pr_id), 2000e14);
        assertEq(ReserveGetter.getBorrowingRateB(lending_pool, pr_id), 5000e14);
        assertEq(
            ReserveGetter.getMaxBorrowingRate(lending_pool, pr_id),
            15000e14
        );
        assertEq(
            ReserveGetter.getStakingAddress(lending_pool, pr_id) != address(0),
            true
        );
    }

    // function test_scenario() public {
    //     lending_pool.deposit(1, 1, address(this), 0);
    // }
}

contract ReserveDeposit is LendingPoolTest {
    /**
     * @dev 2 ways to deposit into a reserve:
     * 1- use LendingPool::deposit => receive eToken
     * 2- use LendingPool::depositAndStake => receive eToken but stake them
     * 3- directly send tokens to eToken => doesnt receive any eToken
     */
    uint reserveId;
    ExtraInterestBearingToken eToken;

    function setUp() public virtual override {
        super.setUp();
        reserveId = lending_pool.nextReserveId();
        lending_pool.initReserve(address(btc));
        eToken = ExtraInterestBearingToken(
            ReserveGetter.getETokenAddress(lending_pool, reserveId)
        );
    }

    function testInitReserveThenNewDebt() public {
        //new debt which setts borrowingRate to zero
        lending_pool.newDebtPosition(reserveId);
        btc.approve(address(lending_pool), ~uint256(0));
        //then deposit
        lending_pool.deposit(reserveId, 100 ether, address(this), 0);
        assertEq(
            ReserveGetter.getCurrentBorrowingRate(lending_pool, reserveId),
            0
        );

        lending_pool.setCreditsOfVault(address(this), reserveId, ~uint256(0));

        //borrowing
        lending_pool.borrow(address(this), reserveId, 50 ether);
    }

    function testDepositToReserve() public {
        btc.approve(address(lending_pool), ~uint256(0));
        uint b0 = eToken.balanceOf(address(this));
        lending_pool.deposit(reserveId, 100 ether, address(this), 0);
        uint b1 = eToken.balanceOf(address(this));
        console.log(b1 - b0);
    }

    function testFuzz_DepositToReserve(
        uint _depositAmount,
        address _onBehalf
    ) public {
        vm.assume(_depositAmount > 0);
        vm.assume(_depositAmount < 1_000_000_000 ether);
        vm.assume(_onBehalf != address(0));
        btc.mint(address(this), _depositAmount);
        btc.approve(address(lending_pool), _depositAmount);
        lending_pool.deposit(reserveId, _depositAmount, _onBehalf, 0);

        uint eTokenToReserve = lending_pool.exchangeRateOfReserve(reserveId);

        assertEq(btc.balanceOf(address(eToken)), _depositAmount);
        // assertEq(
        //     (eTokenToReserve * _depositAmount) / 1 ether,
        //     eToken.totalSupply()
        // );
    }
}

contract ReserveWithdraw is ReserveDeposit {
    /**
     * @dev 2 ways to withdraw from a reserve:
     * 1- use LendingPool::unstakeAndWithdraw if staked before
     * 2- use LendingPool::redeem
     */
    function setUp() public override {
        super.setUp();
    }

    function testDepositAndWithdraw() public {
        testDepositToReserve();
        //received 100 ether of eToken
        eToken.approve(address(lending_pool), eToken.balanceOf(address(this)));
        lending_pool.redeem(
            reserveId,
            eToken.balanceOf(address(this)),
            address(this),
            false
        );
        assertEq(eToken.totalSupply(), 0);
        assertEq(eToken.balanceOf(address(this)), 0);
    }

    function testDepositStakeAndWithdraw() public {
        assertEq(eToken.balanceOf(address(this)), 0);

        btc.approve(address(lending_pool), ~uint256(0));
        lending_pool.depositAndStake(reserveId, 100 ether, address(this), 0);

        assertEq(eToken.balanceOf(address(this)), 0);

        //received 100 ether of eToken
        lending_pool.unStakeAndWithdraw(
            reserveId,
            100 ether,
            address(this),
            false
        );

        assertEq(eToken.totalSupply(), 0);
        assertEq(eToken.balanceOf(address(this)), 0);
    }

    function testDepositAndWithdrawNext() public {
        assertEq(eToken.balanceOf(address(this)), 0);
        btc.mint(address(lending_pool), 50 ether);

        btc.approve(address(lending_pool), ~uint256(0));
        eToken.approve(address(lending_pool), ~uint256(0));

        uint b0 = btc.balanceOf(address(this));
        lending_pool.deposit(reserveId, 100 ether, address(this), 0);
        lending_pool.redeem(
            reserveId,
            eToken.balanceOf(address(this)),
            address(this),
            false
        );
        uint b1 = btc.balanceOf(address(this));
        console.log(b1);
        console.log(b0);
        assertLe(b1, b0);
    }
}

contract BorrowingTest is ReserveDeposit {
    uint positionId;

    function setUp() public override {
        super.setUp();
        btc.approve(address(lending_pool), ~uint256(0));
        lending_pool.deposit(reserveId, 100 ether, address(this), 0);
        lending_pool.setCreditsOfVault(address(this), reserveId, 100 ether);
        positionId = lending_pool.newDebtPosition(reserveId);
    }

    function testBorrow() public {
        uint borrowAmount = 80 ether;

        uint c0 = lending_pool.credits(reserveId, address(this));
        uint b0 = btc.balanceOf(address(this));
        lending_pool.borrow(address(this), positionId, borrowAmount);
        uint c1 = lending_pool.credits(reserveId, address(this));
        uint b1 = btc.balanceOf(address(this));

        //decreases the borrow cap
        assertEq(c0 - c1, borrowAmount);

        //receives the tokens
        assertEq(b1 - b0, borrowAmount);

        //treasury did not receive any tokens yet
        assertEq(eToken.balanceOf(treasury), 0);
    }

    //note just to figure out how things work
    function testBorrowByInterest() public {
        uint borrowAmount = 80 ether;

        uint c0 = lending_pool.credits(reserveId, address(this));
        uint b0 = btc.balanceOf(address(this));
        lending_pool.borrow(address(this), positionId, borrowAmount);
        uint c1 = lending_pool.credits(reserveId, address(this));
        uint b1 = btc.balanceOf(address(this));

        //decreases the borrow cap
        assertEq(c0 - c1, borrowAmount);

        //receives the tokens
        assertEq(b1 - b0, borrowAmount);

        //utilization rate A = 80% = 8e17
        //utilization rate B = 90% = 9e17
        //borrowing rate A = 20% = 2e17
        //borrowing rate B = 50% = 5e17
        assertEq(lending_pool.utilizationRateOfReserve(reserveId), 8e17);

        //since we are at 80% utilization rate, then 100% of borrowing rate A
        assertEq(lending_pool.borrowingRateOfReserve(reserveId), 2e17);

        //6341958396
        uint interestPerSecond = uint256(2e17) / (365 days);
        uint newRate = 1e18 + (interestPerSecond * 2 + 40);

        console.log((newRate * 80 ether) / 1 ether);

        console.log((interestPerSecond * interestPerSecond) / 1e18);
        /**
         * utilization ratio is 80%
         */
        //1 second passed
        //etner udpateState
        vm.warp(block.timestamp + 2);

        //setting fee rate to zero
        // lending_pool.setReserveFeeRate(reserveId, 0);

        // uint approximateBorrowingIndex = 1e18 + 634000000000;
        uint totalBorrows0 = ReserveGetter.getTotalBorrows(
            lending_pool,
            reserveId
        );
        lending_pool.borrow(address(this), positionId, 0 ether);
        uint totalBorrows1 = ReserveGetter.getTotalBorrows(
            lending_pool,
            reserveId
        );
        console.log(totalBorrows1 - totalBorrows0);

        // //treasury did not receive any tokens yet
        // assertEq(eToken.balanceOf(treasury), 0);
    }

    function testBorrowAndRepay_utilizationRateA() public {
        uint borrowAmount = 50 ether;
        btc.approve(address(lending_pool), ~uint256(0));
        lending_pool.borrow(address(this), positionId, borrowAmount);

        //100 seconds passed
        // vm.warp(block.timestamp + 100);

        //calculate the expected interests?
        uint utilizationRatio = (borrowAmount * 1e18) /
            (ReserveGetter.getTotalBorrows(lending_pool, reserveId) +
                btc.balanceOf(address(eToken)));

        uint borrowingRate = (utilizationRatio * 2e17) / 8e17;

        //update indexes
        lending_pool.borrow(address(this), positionId, 0);

        //assert
        assertEq(
            borrowingRate,
            ReserveGetter.getCurrentBorrowingRate(lending_pool, reserveId)
        );

        //100 seconds passed
        vm.warp(block.timestamp + 100);

        //update indexes
        uint b0 = ReserveGetter.getTotalBorrows(lending_pool, reserveId);
        lending_pool.borrow(address(this), positionId, 0);
        uint b1 = ReserveGetter.getTotalBorrows(lending_pool, reserveId);

        assertGt(
            ReserveGetter.getTotalBorrows(lending_pool, reserveId),
            borrowAmount
        );

        //repay
        lending_pool.repay(address(this), positionId, borrowAmount + (b1 - b0));

        assertEq(ReserveGetter.getTotalBorrows(lending_pool, reserveId), 0);
        console.log(eToken.totalSupply());
    }
}

contract BorrowRates is LendingPoolTest {

    function testBorrowMultiple() public {
        address alice;
        address bob;
        
    }
}

/**
 * borrow or redeem:
 *  - updateState (update totalBorrows) and mint fees to treasury
 *  - update position data (totalBorrowed, apply interests)
 *  - udpate interest rates
 *
 */

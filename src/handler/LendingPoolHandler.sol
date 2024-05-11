//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {LendingPool} from "../lendingpool/LendingPool.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReserveGetter} from "../../test/helpers/ReserveGetter.sol";
import {ERC20Fake} from "../../test/fakes/ERC20Fake.sol";

//used to interact with lending_pool in an isolated environment
//we wan to only work with one reserve to be able to check invariants
//like totalBorrows = sum(user.totoalBorrowed)

//note Invariants
//[*] totalBorrows == sum(user.totalBorrowed)
//[*]
contract LendingPoolHandler is Test {
    LendingPool public lending_pool;
    uint public immutable reserveId;
    ERC20Fake public immutable asset;
    IERC20 public immutable eToken;
    mapping(address => uint) public debtIds;
    uint[] public debts;
    uint public timestamp;

    constructor(address _registery, address _weth9, ERC20Fake _asset) {
        lending_pool = new LendingPool(_registery, _weth9);
        asset = _asset;
        reserveId = lending_pool.nextReserveId();
        lending_pool.initReserve(address(asset));
        eToken = IERC20(lending_pool.getETokenAddress(reserveId));
        asset.approve(address(lending_pool), ~uint256(0));
        timestamp = 20 weeks;
    }

    function firstMint(address _receiver, uint _amount) internal {
        if (asset.balanceOf(_receiver) < _amount) {
            asset.mint(_receiver, _amount - asset.balanceOf(_receiver));
        }
    }

    modifier useTimestamp() {
        vm.warp(timestamp);
        _;
        timestamp += 10 minutes;
    }

    function deposit(address _user, uint _amount) public useTimestamp {
        _amount = bound(_amount, 0, 100 ether);
        firstMint(_user, _amount);
        vm.startPrank(_user);
        asset.approve(address(lending_pool), _amount);
        lending_pool.deposit(reserveId, _amount, _user, 0);
        vm.stopPrank();
    }

    // function depositAndStake(
    //     address _user,
    //     uint _amount
    // ) public firstMint(_user, _amount) useTimestamp {
    //     _amount = bound(_amount, 0, 100 ether);
    //     vm.startPrank(_user);
    //     asset.approve(address(lending_pool), _amount);
    //     lending_pool.depositAndStake(reserveId, _amount, _user, 0);
    //     vm.stopPrank();
    // }

    // function unstakeAndWithdraw(address _user, uint _amount) public useTimestamp {
    //     require(_amount <= )
    //     _amount = bound(_amount, 0, 100 ether);
    //     vm.startPrank(_user);
    //     eToken.approve(address(lending_pool), _amount);
    //     lending_pool.unStakeAndWithdraw(reserveId, _amount, _user, false);
    //     vm.stopPrank();
    // }

    function redeem(address _user, uint _amount) public useTimestamp {
        _amount = bound(_amount, 0, 100 ether);
        if (_amount > eToken.balanceOf(_user)) return;
        vm.startPrank(_user);
        eToken.approve(address(lending_pool), _amount);
        lending_pool.redeem(reserveId, _amount, _user, false);
        vm.stopPrank();
    }

    function borrow(address _user, uint _borrowAmount) public useTimestamp {
        _borrowAmount = bound(_borrowAmount, 0, 100 ether);

        vm.startPrank(address(this));
        if (debtIds[_user] == 0) {
            debtIds[_user] = lending_pool.newDebtPosition(reserveId);
            debts.push(debtIds[_user]);
        }
        if (_borrowAmount > asset.balanceOf(address(eToken))) return;
        // asset.mint(address(eToken), _borrowAmount);
        lending_pool.setCreditsOfVault(address(this), reserveId, _borrowAmount);
        lending_pool.borrow(_user, debtIds[_user], _borrowAmount);
        vm.stopPrank();
    }

    function repay(address _user, uint _repayAmount) public useTimestamp {
        _repayAmount = bound(_repayAmount, 0, 100 ether);
        firstMint(_user, _repayAmount);
        vm.startPrank(address(this));
        if (debtIds[_user] == 0) {
            debtIds[_user] = lending_pool.newDebtPosition(reserveId);
            debts.push(debtIds[_user]);
        }
        vm.stopPrank();
        (uint maximumRepay, ) = lending_pool.getCurrentDebt(debtIds[_user]);

        if (_repayAmount > maximumRepay) {
            return;
        }
        //send tokens to handler contract

        vm.startPrank(_user);
        asset.transfer(address(this), _repayAmount);
        vm.stopPrank();

        //repay
        vm.startPrank(address(this));
        lending_pool.repay(_user, debtIds[_user], _repayAmount);
        vm.stopPrank();
    }

    function getBorrowSums() public view returns (uint totalBorrows) {
        for (uint i; i < debts.length; i++) {
            (uint borrowed, ) = lending_pool.getCurrentDebt(debts[i]);
            totalBorrows += borrowed;
        }
    }

    function getTotalBorrowed() public view returns (uint totalBorrowed) {
        return lending_pool.getTotalBorrwedReserve(reserveId);
    }

    function getTotalAvailable() public view returns (uint totalBorrowed) {
        return lending_pool.getTotalAvailableReserve(reserveId);
    }

    function getLatestBorrowingIndex() public view returns (uint) {
        return lending_pool.getLatestBorrowingIndex(reserveId);
    }
}

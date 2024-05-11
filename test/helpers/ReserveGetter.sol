//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {LendingPool} from "../../src/lendingpool/LendingPool.sol";
import {DataTypes} from "../../src/libraries/types/DataTypes.sol";

library ReserveGetter {
    function getBorrowingIndex(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint borrowingIndex) {
        (borrowingIndex, , , , , , , , , , , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getCurrentBorrowingRate(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint currentBorrowingRate) {
        (, currentBorrowingRate, , , , , , , , , , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getTotalBorrows(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint totalBorrows) {
        (, , totalBorrows, , , , , , , , , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getReserveUnderlyingAsset(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (address underlyingAsset) {
        (, , , underlyingAsset, , , , , , , , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getETokenAddress(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (address eTokenAddress) {
        (, , , , eTokenAddress, , , , , , , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getStakingAddress(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (address stakingAddress) {
        (, , , , , stakingAddress, , , , , , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getReserveCapacity(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint capacity) {
        (, , , , , , capacity, , , , , ) = lending_pool.reserves(_reserveId);
    }

    function getBorrowingRateConfig(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (DataTypes.InterestRateConfig memory config) {
        (, , , , , , , config, , , , ) = lending_pool.reserves(_reserveId);
    }

    function getId(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint id) {
        (, , , , , , , , id, , , ) = lending_pool.reserves(_reserveId);
    }

    function getReserveFeeRate(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint reserveFeeRate) {
        (, , , , , , , , , , reserveFeeRate, ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getLastUpdateTimestamp(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint lastUpdateTimestamp) {
        (, , , , , , , , , lastUpdateTimestamp, , ) = lending_pool.reserves(
            _reserveId
        );
    }

    function getIsActive(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (bool isActive) {
        (, , , , , , , , , , , DataTypes.Flags memory flags) = lending_pool
            .reserves(_reserveId);
        return flags.isActive;
    }

    function getIsFrozen(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (bool isActive) {
        (, , , , , , , , , , , DataTypes.Flags memory flags) = lending_pool
            .reserves(_reserveId);
        return flags.frozen;
    }

    function getBorrowingEnabled(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (bool borrowingEnabled) {
        (, , , , , , , , , , , DataTypes.Flags memory flags) = lending_pool
            .reserves(_reserveId);
        return flags.borrowingEnabled;
    }

    function getUtilizationRateA(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypes.InterestRateConfig memory config,
            ,
            ,
            ,

        ) = lending_pool.reserves(_reserveId);

        return config.utilizationA;
    }

    function getUtilizationRateB(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypes.InterestRateConfig memory config,
            ,
            ,
            ,

        ) = lending_pool.reserves(_reserveId);

        return config.utilizationB;
    }

    function getBorrowingRateA(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypes.InterestRateConfig memory config,
            ,
            ,
            ,

        ) = lending_pool.reserves(_reserveId);

        return config.borrowingRateA;
    }

    function getBorrowingRateB(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypes.InterestRateConfig memory config,
            ,
            ,
            ,

        ) = lending_pool.reserves(_reserveId);

        return config.borrowingRateB;
    }

    function getMaxBorrowingRate(
        LendingPool lending_pool,
        uint _reserveId
    ) public view returns (uint) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypes.InterestRateConfig memory config,
            ,
            ,
            ,

        ) = lending_pool.reserves(_reserveId);

        return config.maxBorrowingRate;
    }
}

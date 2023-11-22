// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library PresaleEvents {
    // Events
    event NewInvestment(
        address investor,
        uint256 capital,
        uint256 allocation
    );

    event RoundFinished();

    /**
     * @dev Emitted when vested Zurf tokens are distributed to investors during a drop event.
     * @param allocation The total amount of Zurf tokens dropped to investors during this execution.
     */
    event zurfDropVesting__DropExecuted(
        uint256 allocation
    );

    event zurfDropVesting__dataLoaded(uint256 investorCount);

}
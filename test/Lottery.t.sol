// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    address owner = address(this);
    address alice = address(0xA);
    address bob = address(0xB);
    address carol = address(0xC);

    function setUp() public {
        lottery = new Lottery();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(carol, 1 ether);
    }

    function test_InitialRound() public view {
        Lottery.Round memory r = lottery.getCurrentRound();
        assertEq(r.id, 0);
        assertFalse(r.drawn);
    }

    function test_BuyTicket() public {
        vm.prank(alice);
        lottery.buyTickets{value: 0.001 ether}(1);
        assertEq(lottery.ticketsByRound(0, alice), 1);
    }

    function test_BuyMultipleTickets() public {
        vm.prank(alice);
        lottery.buyTickets{value: 0.003 ether}(3);
        assertEq(lottery.ticketsByRound(0, alice), 3);
    }

    function test_WrongAmountReverts() public {
        vm.prank(alice);
        vm.expectRevert(Lottery.WrongAmount.selector);
        lottery.buyTickets{value: 0.002 ether}(1);
    }

    function test_DrawWinner() public {
        vm.prank(alice);
        lottery.buyTickets{value: 0.001 ether}(1);
        vm.prank(bob);
        lottery.buyTickets{value: 0.001 ether}(1);

        vm.warp(block.timestamp + 7 days + 1);
        lottery.drawWinner();

        Lottery.Round memory r = lottery.getRound(0);
        assertTrue(r.drawn);
        assertTrue(r.winner == alice || r.winner == bob);
        assertGt(r.prize, 0);
    }

    function test_CannotDrawBeforeEnd() public {
        vm.prank(alice);
        lottery.buyTickets{value: 0.001 ether}(1);
        vm.expectRevert(Lottery.RoundNotOver.selector);
        lottery.drawWinner();
    }

    function test_NewRoundStartsAfterDraw() public {
        vm.prank(alice);
        lottery.buyTickets{value: 0.001 ether}(1);
        vm.warp(block.timestamp + 7 days + 1);
        lottery.drawWinner();
        assertEq(lottery.totalRounds(), 2);
    }
}

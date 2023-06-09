// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "../src/ImpactCards.sol";

contract ImpactCardTest is Test {
    ImpactCards_Gen1 cards;

    // addresses of payees
    address public ag; // Autstin Griffith
    uint256 public agKeys = 0xA0A01;
    address public er; // Eth Rank
    uint256 public erKeys = 0xA0A012;
    address public jl; // Joseph Lubin
    uint256 public jlKeys = 0xA0A02;
    address public jb; // Juan Benet
    uint256 public jbKeys = 0xA0A03;
    address public ko; // Kevin Owocki
    uint256 public koKeys = 0xA0A04;
    address public sn; // Satoshi Nakamoto
    uint256 public snKeys = 0xA0A05;
    address public gt; // Guild XYZ Team
    uint256 public gtKeys = 0xA0A06;
    address public fv; // Futureverse
    uint256 public fvKeys = 0xA0A07;
    address public op; // Optimism
    uint256 public opKeys = 0xA0A08;
    address public zx; // ZachXBT
    uint256 public zxKeys = 0xA0A09;
    address public sc; // Stephen Chavez
    uint256 public scKeys = 0xA0A10;
    address public rb; // Rommel Brito
    uint256 public rbKeys = 0xA0A11;
    address public ed; // Ethereum Denver
    uint256 public edKeys = 0xA0A12;
    address public ef; // Ethereum Foundation
    uint256 public efKeys = 0xA0A13;
    address public pc; // Patrick Collins
    uint256 public pcKeys = 0xA0A14;
    address dAgoraTreasury;

    // addresses of random users
    address public alice;
    address public bob;
    address public carol;
    address public dave;
    address public eve;
    uint256 public aliceKeys = 0xA0A;
    uint256 public bobsKeys = 0xB0B;
    uint256 public carolsKeys = 0xC0C;
    uint256 public daveKeys = 0xD0D;
    uint256 public evesKeys = 0xE0E;

    function setUp() public {
        ag = vm.addr(agKeys);
        er = vm.addr(erKeys);
        jl = vm.addr(jlKeys);
        jb = vm.addr(jbKeys);
        ko = vm.addr(koKeys);
        sn = vm.addr(snKeys);
        gt = vm.addr(gtKeys);
        fv = vm.addr(fvKeys);
        op = vm.addr(opKeys);
        zx = vm.addr(zxKeys);
        sc = vm.addr(scKeys);
        rb = vm.addr(rbKeys);
        ed = vm.addr(edKeys);
        ef = vm.addr(efKeys);
        pc = vm.addr(pcKeys);

        alice = vm.addr(aliceKeys);
        bob = vm.addr(bobsKeys);
        carol = vm.addr(carolsKeys);
        dave = vm.addr(daveKeys);
        eve = vm.addr(evesKeys);

        dAgoraTreasury = vm.addr(0xA0A15);

        vm.startPrank(dAgoraTreasury);
        cards = new ImpactCards_Gen1();

        // Set Payees for season one of Impact Cards
        for (uint256 i = 1; i <= 15; i++) {
            address[15] memory allPayees = [ag, er, jl, jb, ko, sn, gt, fv, op, zx, sc, rb, ed, ef, pc];
            cards.setPayees(i, [dAgoraTreasury, allPayees[i - 1]], [uint256(50), uint256(50)]);
        }
        // assert that the payees are set correctly
        for (uint256 i = 1; i <= 15; i++) {
            address[15] memory allPayees = [ag, er, jl, jb, ko, sn, gt, fv, op, zx, sc, rb, ed, ef, pc];
            address[2] memory payees = cards.getPayees(i);
            uint256[2] memory shares = cards.getShares(i);
            assertEq(payees[0], dAgoraTreasury);
            assertEq(payees[1], allPayees[i - 1]);
            assertEq(shares[0], 50);
            assertEq(shares[1], 50);
        }
        vm.stopPrank();

        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(carol, 1000 ether);
        vm.deal(dave, 1000 ether);
    }

    function testFailMintSingleCardPaused() public {
        vm.startPrank(alice);
        uint256 id = 1;
        uint256 amount = 1;
        uint256 cost = amount * 0.005 ether;

        // Alice mints a single card
        cards.mint{value: cost}(id, amount);
        vm.expectRevert("Contract is paused");
        vm.stopPrank();
    }

    function testFailMintBatchCardsPaused() public {
        vm.startPrank(alice);
        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 5;
        ids[3] = 10;
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 6;
        amounts[1] = 3;
        amounts[2] = 4;
        amounts[3] = 2;

        uint256 pricePer = 0.005 ether;
        uint256 cost = (amounts[0] + amounts[1] + amounts[2] + amounts[3]) * pricePer;

        // Alice mints a single card
        cards.mintBatch{value: cost}(ids, amounts);
        vm.expectRevert("Contract is paused");
        vm.stopPrank();
    }

    function testFailTransferWhenPaused() public {
        vm.startPrank(dAgoraTreasury);
        cards.togglePaused();
        assertEq(cards.isPaused(), false);
        vm.stopPrank();
        vm.startPrank(alice);
        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 5;
        ids[3] = 10;
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 5;
        amounts[1] = 3;
        amounts[2] = 4;
        amounts[3] = 2;

        uint256 pricePer = 0.005 ether;
        uint256 cost = (amounts[0] + amounts[1] + amounts[2] + amounts[3]) * pricePer;

        // Alice mints a single card
        cards.mintBatch{value: cost}(ids, amounts);
        assertEq(cards.balanceOf(alice, ids[0]), amounts[0]);
        assertEq(cards.balanceOf(alice, ids[1]), amounts[1]);
        assertEq(cards.balanceOf(alice, ids[2]), amounts[2]);
        assertEq(cards.balanceOf(alice, ids[3]), amounts[3]);
        vm.stopPrank();

        vm.startPrank(dAgoraTreasury);
        cards.togglePaused();
        assertEq(cards.isPaused(), true);
        vm.stopPrank();

        vm.startPrank(alice);
        cards.safeTransferFrom(alice, bob, ids[0], 1, "");
        vm.expectRevert("Contract is paused");

        cards.safeBatchTransferFrom(alice, bob, ids, amounts, "");
        vm.expectRevert("Contract is paused");
        vm.stopPrank();
    }

    function testFailBatchTransferWhenPaused() public {
        vm.startPrank(dAgoraTreasury);
        cards.togglePaused();
        assertEq(cards.isPaused(), false);
        vm.stopPrank();
        vm.startPrank(alice);
        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 5;
        ids[3] = 10;
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 5;
        amounts[1] = 3;
        amounts[2] = 4;
        amounts[3] = 2;

        uint256 pricePer = 0.005 ether;
        uint256 cost = (amounts[0] + amounts[1] + amounts[2] + amounts[3]) * pricePer;

        // Alice mints a single card
        cards.mintBatch{value: cost}(ids, amounts);
        assertEq(cards.balanceOf(alice, ids[0]), amounts[0]);
        assertEq(cards.balanceOf(alice, ids[1]), amounts[1]);
        assertEq(cards.balanceOf(alice, ids[2]), amounts[2]);
        assertEq(cards.balanceOf(alice, ids[3]), amounts[3]);
        vm.stopPrank();

        vm.startPrank(dAgoraTreasury);
        cards.togglePaused();
        assertEq(cards.isPaused(), true);
        vm.stopPrank();

        vm.startPrank(alice);
        cards.safeBatchTransferFrom(alice, bob, ids, amounts, "");
        vm.expectRevert("Contract is paused");
        vm.stopPrank();
    }

    function testUri() public {
        vm.startPrank(dAgoraTreasury);
        cards.togglePaused();
        assertEq(cards.isPaused(), false);
        vm.stopPrank();
        vm.startPrank(alice);
        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 5;
        ids[3] = 10;
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 5;
        amounts[1] = 3;
        amounts[2] = 4;
        amounts[3] = 2;

        uint256 pricePer = 0.005 ether;
        uint256 cost = (amounts[0] + amounts[1] + amounts[2] + amounts[3]) * pricePer;

        // Alice mints a single card
        cards.mintBatch{value: cost}(ids, amounts);

        assertEq(cards.uri(ids[0]), "https://impactcards.io/api/cards/1.json");
        assertEq(cards.uri(ids[1]), "https://impactcards.io/api/cards/2.json");
        assertEq(cards.uri(ids[2]), "https://impactcards.io/api/cards/5.json");
        assertEq(cards.uri(ids[3]), "https://impactcards.io/api/cards/10.json");
        vm.stopPrank();
    }
}

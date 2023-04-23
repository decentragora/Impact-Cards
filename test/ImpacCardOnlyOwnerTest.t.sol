// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import '../src/ImpactCards.sol';

contract ImpactCardTest is Test {
    ImpactCards_Gen1 cards;

    // addresses of payees
    address public ag; // Autstin Griffith
    uint256 public agKeys = 0xA0A01;
    address public er; // Eth Rank
    uint256 public erKeys = 0xA0A012;
    address public jl;  // Joseph Lubin
    uint256 public jlKeys = 0xA0A02;
    address public jb;  // Juan Benet
    uint256 public jbKeys = 0xA0A03;
    address public ko;  // Kevin Owocki
    uint256 public koKeys = 0xA0A04;
    address public sn;  // Satoshi Nakamoto
    uint256 public snKeys = 0xA0A05;
    address public gt;  // Guild XYZ Team
    uint256 public gtKeys = 0xA0A06;
    address public fv;  // Futureverse
    uint256 public fvKeys = 0xA0A07;
    address public op;  // Optimism
    uint256 public opKeys = 0xA0A08;
    address public zx;  // ZachXBT
    uint256 public zxKeys = 0xA0A09;
    address public sc;  // Stephen Chavez
    uint256 public scKeys = 0xA0A10;
    address public rb;  // Rommel Brito
    uint256 public rbKeys = 0xA0A11;
    address public ed;  // Ethereum Denver
    uint256 public edKeys = 0xA0A12;
    address public ef;  // Ethereum Foundation
    uint256 public efKeys = 0xA0A13;
    address public pc;  // Patrick Collins
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
                address[15] memory allPayees = [ ag, er, jl, jb, ko, sn, gt, fv, op, zx, sc, rb, ed, ef, pc ];
                cards.setPayees(i, [dAgoraTreasury, allPayees[i-1]], [uint256(50), uint256(50)]);
            }
            //assert that the payees are set correctly
            for (uint256 i = 1; i <= 15; i++) {
                address[15] memory allPayees = [ ag, er, jl, jb, ko, sn, gt, fv, op, zx, sc, rb, ed, ef, pc ];
                address[2] memory payees = cards.getPayees(i);
                uint256[2] memory shares = cards.getShares(i);
                assertEq(payees[0], dAgoraTreasury);
                assertEq(payees[1], allPayees[i-1]);
                assertEq(shares[0], 50);
                assertEq(shares[1], 50);
            }

            // Toggle pause
            cards.togglePaused();
        vm.stopPrank();

        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(carol, 1000 ether);
        vm.deal(dave, 1000 ether);
    }


    function testSetupPayees() public {
        vm.startPrank(dAgoraTreasury);
            // Set Payees for season one of Impact Cards
            for (uint256 i = 1; i <= 15; i++) {
                address[15] memory allPayees = [ ag, er, jl, jb, ko, sn, gt, fv, op, zx, sc, rb, ed, ef, pc ];
                cards.setPayees(i, [dAgoraTreasury, allPayees[i-1]], [uint256(50), uint256(50)]);
            }

            for (uint256 i = 1; i <= 15; i++) {
                address[15] memory allPayees = [ ag, er, jl, jb, ko, sn, gt, fv, op, zx, sc, rb, ed, ef, pc ];
                address[2] memory payees = cards.getPayees(i);
                uint256[2] memory shares = cards.getShares(i);
                assertEq(payees[0], dAgoraTreasury);
                assertEq(payees[1], allPayees[i-1]);
                assertEq(shares[0], 50);
                assertEq(shares[1], 50);
            }
        vm.stopPrank();
    }

    function testFailSetupPayeesInvalidTokenId() public {
        vm.startPrank(dAgoraTreasury);
            cards.setPayees(0, [dAgoraTreasury, ag], [uint256(50), uint256(50)]);
            vm.expectRevert();
            cards.setPayees(61, [dAgoraTreasury, ag], [uint256(50), uint256(50)]);
            vm.expectRevert();
        vm.stopPrank();
    }

    function testFailSetupPayeesInvalidShares() public {
        vm.startPrank(dAgoraTreasury);
            cards.setPayees(1, [dAgoraTreasury, ag], [uint256(50), uint256(51)]);
            vm.expectRevert();
            cards.setPayees(1, [dAgoraTreasury, ag], [uint256(50), uint256(49)]);
            vm.expectRevert();
            cards.setPayees(1, [dAgoraTreasury, ag], [uint256(0), uint256(0)]);
            vm.expectRevert();
        vm.stopPrank();
    }

    function testFailSetupPayeesInvalidAddress() public {
        vm.startPrank(dAgoraTreasury);
            cards.setPayees(1, [dAgoraTreasury, address(0)], [uint256(50), uint256(50)]);
            vm.expectRevert();
            cards.setPayees(1, [address(0), ag], [uint256(50), uint256(50)]);
            vm.expectRevert();
        vm.stopPrank();
    }

    function testFailSetupPayeesSameAddress() public {
        vm.startPrank(dAgoraTreasury);
            cards.setPayees(1, [dAgoraTreasury, dAgoraTreasury], [uint256(50), uint256(50)]);
            vm.expectRevert();
        vm.stopPrank();
    }

    function testFailSetupPayeesInvalidSender() public {
        vm.startPrank(alice);
            cards.setPayees(1, [dAgoraTreasury, ag], [uint256(50), uint256(50)]);
            vm.expectRevert();
        vm.stopPrank();
    }

    function testNextSeason() public {
        vm.startPrank(dAgoraTreasury);
            cards.nextSeason();
            assertEq(cards.currentSeason(), 2);
            cards.nextSeason();
            assertEq(cards.currentSeason(), 3);
            cards.nextSeason();
            assertEq(cards.currentSeason(), 4);
        vm.stopPrank();
    }

    function testFailNextSeasonFiveSeasons() public {
        vm.startPrank(dAgoraTreasury);
            cards.nextSeason();
            assertEq(cards.currentSeason(), 2);
            cards.nextSeason();
            assertEq(cards.currentSeason(), 3);
            cards.nextSeason();
            assertEq(cards.currentSeason(), 4);
            cards.nextSeason();
            vm.expectRevert("All seasons have been activated");
        vm.stopPrank();
    }

    function testFailNextSeasonInvalidSender() public {
        vm.startPrank(alice);
            cards.nextSeason();
            vm.expectRevert('Ownable: caller is not the owner');
        vm.stopPrank();
    }

    function testSetMintPrice() public {
        vm.startPrank(dAgoraTreasury);
            cards.setMintPrice(1000);
            assertEq(cards.mintPrice(), 1000);
            cards.setMintPrice(2000);
            assertEq(cards.mintPrice(), 2000);
        vm.stopPrank();
    }

    function testFailSetMintPriceInvalidSender() public {
        vm.startPrank(alice);
            cards.setMintPrice(1000);
            vm.expectRevert('Ownable: caller is not the owner');
        vm.stopPrank();
    }


    function testSetBulkBuyLimit() public {
        vm.startPrank(dAgoraTreasury);
            cards.setBulkBuyLimit(10);
            assertEq(cards.bulkBuyLimit(), 10);
            cards.setBulkBuyLimit(20);
            assertEq(cards.bulkBuyLimit(), 20);
        vm.stopPrank();
    }

    function testFailSetBulkBuyLimitInvalidParams() public {
        vm.startPrank(dAgoraTreasury);
            cards.setBulkBuyLimit(0);
            vm.expectRevert('Limit cannot be zero');
            cards.setBulkBuyLimit(101);
            vm.expectRevert('Limit cannot be more than 100');
        vm.stopPrank();
    }

    function testFailSetBulkBuyLimitInvalidSender() public {
        vm.startPrank(alice);
            cards.setBulkBuyLimit(10);
            vm.expectRevert('Ownable: caller is not the owner');
        vm.stopPrank();
    }

    function testSetBaseURI() public {
        vm.startPrank(dAgoraTreasury);
            cards.setBaseURI('https://api.agora.cards/');
            assertEq(cards._uri(), 'https://api.agora.cards/');
            cards.setBaseURI('https://api.agora.cards/2/');
            assertEq(cards._uri(), 'https://api.agora.cards/2/');
        vm.stopPrank();
    }

    function testFailSetBaseURIInvalidSender() public {
        vm.startPrank(alice);
            cards.setBaseURI('https://api.agora.cards/');
            vm.expectRevert('Ownable: caller is not the owner');
        vm.stopPrank();
    }

    function testSetBaseExtension() public {
        vm.startPrank(dAgoraTreasury);
            cards.setBaseExtension('.json');
            assertEq(cards._baseExtension(), '.json');
            cards.setBaseExtension('.png');
            assertEq(cards._baseExtension(), '.png');
        vm.stopPrank();
    }

    function testFailSetBaseExtensionInvalidSender() public {
        vm.startPrank(alice);
            cards.setBaseExtension('.json');
            vm.expectRevert('Ownable: caller is not the owner');
        vm.stopPrank();
    }

    function testTogglePaused() public {
        vm.startPrank(dAgoraTreasury);
            cards.togglePaused();
            assertTrue(cards.isPaused());
            cards.togglePaused();
            assertTrue(!cards.isPaused());
        vm.stopPrank();
    }

    function testFailTogglePausedInvalidSender() public {
        vm.startPrank(alice);
            cards.togglePaused();
            vm.expectRevert('Ownable: caller is not the owner');
        vm.stopPrank();
    }

}
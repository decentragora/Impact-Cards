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
            // assert that the payees are set correctly
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



    function testMintSingleId() public {
        vm.startPrank(alice);
            uint256 id = 1;
            uint256 amount = 1;
            uint256 cost = amount * 0.005 ether;
            
            // Alice mints a single card
            cards.mint{value: cost}(id, amount);
            // Alice owns the card
            assertEq(cards.balanceOf(alice, id), amount);
            // Payees can receive the correct amount of ETH
            assertEq(cards.getAccumulatedFunds(id)[0], cost / 2);
            assertEq(cards.getAccumulatedFunds(id)[1], cost / 2);
        vm.stopPrank();
    }

    function testMintSingleIdBulkBuyLimit() public {
        vm.startPrank(alice);
            uint256 id = 1;
            uint256 amount = 5;
            uint256 cost = amount * 0.005 ether;
            
            // Alice mints a single card
            cards.mint{value: cost}(id, amount);
            // Alice owns the card
            assertEq(cards.balanceOf(alice, id), amount);
            // Payees can receive the correct amount of ETH
            assertEq(cards.getAccumulatedFunds(id)[0], cost / 2);
            assertEq(cards.getAccumulatedFunds(id)[1], cost / 2);
        vm.stopPrank();
    }

    function testFailMintSingleIdBulkBuyLimit() public {
        vm.startPrank(alice);
            uint256 id = 1;
            uint256 amount = 6;
            uint256 cost = amount * 0.005 ether;
            
            // Alice mints a single card
            cards.mint{value: cost}(id, amount);
            vm.expectRevert("Exceeds bulk buy limit");
        vm.stopPrank();
    }

    function testFailMintSingleIdInsufficientFunds() public {
        vm.startPrank(eve);
            uint256 id = 1;
            uint256 amount = 1;
            uint256 cost = amount * 0.005 ether;
            
            // Alice mints a single card
            cards.mint{value: cost - 1}(id, amount);
            vm.expectRevert("Insufficient payment");
        vm.stopPrank();
    }

    function testFailMintSingleInvalidTokenId() public {
        vm.startPrank(alice);
            uint256 id = 0;
            uint256 amount = 1;
            uint256 cost = amount * 0.005 ether;
            
            // Alice mints a single card
            cards.mint{value: cost}(id, amount);
            vm.expectRevert("Invalid tokenId");            
        vm.stopPrank();
        vm.stopPrank();
            id = 57;

            // Alice mints a single card
            cards.mint{value: cost}(id, amount);
            vm.expectRevert("Invalid tokenId");
        vm.stopPrank();

    }

    function testFailMintSingleInvalidSeason() public {
        vm.startPrank(alice);
            uint256 id = 16;
            uint256 amount = 1;
            uint256 cost = amount * 0.005 ether;
            
            // Alice mints a single card
            cards.mint{value: cost}(id, amount);
            vm.expectRevert("Token not mintable in the current season");
        vm.stopPrank();
    }

    function testMintBatchIds() public {
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
            // Alice owns the card
            assertEq(cards.balanceOf(alice, ids[0]), amounts[0]);
            assertEq(cards.balanceOf(alice, ids[1]), amounts[1]);
            assertEq(cards.balanceOf(alice, ids[2]), amounts[2]);
            assertEq(cards.balanceOf(alice, ids[3]), amounts[3]);
            // Payees can receive the correct amount of ETH
            assertEq(cards.getAccumulatedFunds(1)[0], amounts[0] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(1)[1], amounts[0] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(2)[0], amounts[1] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(2)[1], amounts[1] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(5)[0], amounts[2] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(5)[1], amounts[2] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(10)[0], amounts[3] * pricePer / 2);
            assertEq(cards.getAccumulatedFunds(10)[1], amounts[3] * pricePer / 2);
        vm.stopPrank();
    }

    function testMintBatchIdsBulkBuyLimit() public {
        vm.startPrank(alice);
            uint256[] memory ids = new uint256[](10);
            ids[0] = 1;
            ids[1] = 2;
            ids[2] = 3;
            ids[3] = 4;
            ids[4] = 5;
            ids[5] = 6;
            ids[6] = 7;
            ids[7] = 8;
            ids[8] = 9;
            ids[9] = 10;
            uint256[] memory amounts = new uint256[](10);
            amounts[0] = 5;
            amounts[1] = 5;
            amounts[2] = 5;
            amounts[3] = 5;
            amounts[4] = 5;
            amounts[5] = 5;
            amounts[6] = 5;
            amounts[7] = 5;
            amounts[8] = 5;
            amounts[9] = 5;

            uint256 pricePer = 0.005 ether;
            uint256 cost = (amounts[0] + amounts[1] + amounts[2] + amounts[3] + amounts[4] + amounts[5] + amounts[6] + amounts[7] + amounts[8] + amounts[9]) * pricePer;

            // Alice mints 5 cards of each id
            cards.mintBatch{value: cost}(ids, amounts);
            // Alice owns the card
            for (uint256 i = 0; i < ids.length; i++) {
                assertEq(cards.balanceOf(alice, ids[i]), amounts[i]);
            }

            // Payees can receive the correct amount of ETH
            for (uint256 i = 0; i < ids.length; i++) {
                assertEq(cards.getAccumulatedFunds(ids[i])[0], amounts[i] * pricePer / 2);
                assertEq(cards.getAccumulatedFunds(ids[i])[1], amounts[i] * pricePer / 2);
            }
        vm.stopPrank();
    }

    function testFailMintBatchIdsInsufficientFunds() public {
        vm.startPrank(eve);
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
            cards.mintBatch{value: cost - 1}(ids, amounts);
            vm.expectRevert("Insufficient payment");
        vm.stopPrank();
    }

    function testFailMintBatchIdsOverBulkBuyLimit() public {
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

            // Alice mints a batch of cards
            cards.mintBatch{value: cost + 1}(ids, amounts);
            vm.expectRevert("Exceeds bulk buy limit");
            assertEq(cards.balanceOf(alice, ids[0]), 0, 'Alice should have a balance of 0');
        vm.stopPrank();
    }

    function testFailMintBatchIdsInvalidTokenId() public {
        vm.startPrank(alice);
            uint256[] memory ids = new uint256[](4);
            ids[0] = 0;
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

            // Alice mints a batch of cards
            cards.mintBatch{value: cost}(ids, amounts);
            vm.expectRevert("Invalid tokenId");
            assertEq(cards.balanceOf(alice, ids[0]), 0, 'Alice should have a balance of 0');
        vm.stopPrank();
    }


    function testFailMintBatchInvalidSeason() public {
        vm.startPrank(alice);
            uint256[] memory ids = new uint256[](4);
            ids[0] = 1;
            ids[1] = 2;
            ids[2] = 5;
            ids[3] = 17;
            uint256[] memory amounts = new uint256[](4);
            amounts[0] = 6;
            amounts[1] = 3;
            amounts[2] = 4;
            amounts[3] = 2;

            uint256 pricePer = 0.005 ether;
            uint256 cost = (amounts[0] + amounts[1] + amounts[2] + amounts[3]) * pricePer;

            // Alice mints a batch of cards
            cards.mintBatch{value: cost}(ids, amounts);
            vm.expectRevert();
            assertEq(cards.balanceOf(alice, ids[0]), 0, 'Alice should have a balance of 0');
        vm.stopPrank();
    }
        
    function testTotalSupplyFunction() public {
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

            // Alice mints a batch of cards
            cards.mintBatch{value: cost}(ids, amounts);

            assertEq(cards.totalSupply(ids[0]), amounts[0]);
            assertEq(cards.totalSupply(ids[1]), amounts[1]);
            assertEq(cards.totalSupply(ids[2]), amounts[2]);
            assertEq(cards.totalSupply(ids[3]), amounts[3]);

        vm.stopPrank();
    }

    function testMaxSupply() public {
        vm.startPrank(dAgoraTreasury);
            cards.setBulkBuyLimit(100);
        vm.stopPrank();

        vm.startPrank(alice);
            uint256 totalSupply = cards.totalSupply(1);
            uint256 maxSupply = cards.MAX_SUPPLY();
            uint256 bulkBuyLimit = cards.bulkBuyLimit();
                        
            uint256 pricePer = 0.005 ether;
            uint256 cost = bulkBuyLimit * pricePer;
            for (uint256 i = 1; i <= 20; i++) {
                cards.mint{value: cost}(1, 100);
            }
            
            cost = 23 * pricePer;
            cards.mint{value: cost}(1, 23);

            totalSupply = cards.totalSupply(1);
            assertEq(cards.totalSupply(1), maxSupply);
            assertEq(cards.balanceOf(alice, 1), maxSupply);            
        vm.stopPrank();        
    }

    function testFailMintOverMaxSupply() public {
        vm.startPrank(dAgoraTreasury);
            cards.setBulkBuyLimit(100);
        vm.stopPrank();

        vm.startPrank(alice);
            uint256 totalSupply = cards.totalSupply(1);
            uint256 maxSupply = cards.MAX_SUPPLY();
            uint256 bulkBuyLimit = cards.bulkBuyLimit();
                        
            uint256 pricePer = 0.005 ether;
            uint256 cost = bulkBuyLimit * pricePer;
            for (uint256 i = 1; i <= 20; i++) {
                cards.mint{value: cost}(1, 100);
            }
            
            cost = 23 * pricePer;
            cards.mint{value: cost}(1, 23);

            totalSupply = cards.totalSupply(1);
            assertEq(cards.totalSupply(1), maxSupply);
            assertEq(cards.balanceOf(alice, 1), maxSupply);    
            
            cost = 1 * pricePer;
            cards.mint{value: cost}(1, 1);
            vm.expectRevert("Exceeds max supply");
        vm.stopPrank();        
    }

    function testIsMintableFunction() public {
        vm.startPrank(dAgoraTreasury);
            // Mintable cards during season 1
            for(uint256 i = 1; i<= 15; i++) {
                assertEq(cards.isMintable(i), true, 'Cards should be mintable');
            }
            // Hidden cards should always be mintable
            for(uint256 i = 57; i<= 60; i++) {
                assertEq(cards.isMintable(i), true, 'Hidden cards should always be mintable');
            }
            // Non-mintable cards
            for(uint256 i = 16; i<= 56; i++) {
                assertEq(cards.isMintable(i), false, 'Cards should not be mintable');
            }
            
            cards.nextSeason();

            // Mintable cards during season 2
            for(uint256 i = 1; i<= 29; i++) {
                assertEq(cards.isMintable(i), true, 'Cards should be mintable');
            }

            // Non-mintable cards
            for(uint256 i = 30; i<= 56; i++) {
                assertEq(cards.isMintable(i), false, 'Cards should not be mintable');
            }

            // Hidden cards should always be mintable
            for(uint256 i = 57; i<= 60; i++) {
                assertEq(cards.isMintable(i), true, 'Hidden cards should always be mintable');
            }

            cards.nextSeason();

            // Mintable cards during season 3
            for(uint256 i = 1; i<= 43; i++) {
                assertEq(cards.isMintable(i), true, 'Cards should be mintable');
            }

            // Non-mintable cards
            for(uint256 i = 46; i<= 56; i++) {
                assertEq(cards.isMintable(i), false, 'Cards should not be mintable');
            }

            // Hidden cards should always be mintable
            for(uint256 i = 57; i<= 60; i++) {
                assertEq(cards.isMintable(i), true, 'Hidden cards should always be mintable');
            }

            cards.nextSeason();

            // Mintable cards during season 4
            for(uint256 i = 1; i<= 56; i++) {
                assertEq(cards.isMintable(i), true, 'Cards should be mintable');
            }

            // Hidden cards should always be mintable
            for(uint256 i = 57; i<= 60; i++) {
                assertEq(cards.isMintable(i), true, 'Hidden cards should always be mintable');
            }

            assertEq(cards.isMintable(61), false, 'Cards should not be mintable');
        vm.stopPrank();
    }


}

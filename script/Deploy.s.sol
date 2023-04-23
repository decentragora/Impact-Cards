// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/ImpactCards.sol";
import "forge-std/console.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
            ImpactCards_Gen1 cards = new ImpactCards_Gen1();
            console.log("Deployed ImpactCards at address: ", address(cards));

            // addresses of payees
            address testPayee1 = 0x7c3bA47e39741B37F6093b1c2E534f1E84C0B36b;    // these are test payees.
            address testPayee2 = 0x59992E3626D6d5471D676f2de5A6e6dcF0e06De7;    // these are test payees.

            // add payees for first season tokenIds.
            address[2] memory payees = [testPayee1, testPayee2];
            uint256[2] memory shares = [uint256(50), uint256(50)];

            for (uint256 tokenId = 1; tokenId <= 15; tokenId++) {
                cards.setPayees(tokenId, payees, shares);
            }
        vm.stopBroadcast();
    }
}

//forge script script/Deploy.s.sol:DeployScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv

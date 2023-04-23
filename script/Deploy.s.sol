// SPDX-Licenese-Identifier: MIT
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
        vm.stopBroadcast();
    }
}

//forge script script/testdeployMemberships.s.sol:DeployScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
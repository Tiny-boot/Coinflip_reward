// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/DauphineToken.sol";
import "../src/Coinflip.sol" as CoinflipV1;
import "../src/CoinflipV2.sol" as CoinflipV2;
import "../src/Proxy.sol";

contract SimulateCoinflip is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // Deploy DauphineToken
        vm.startBroadcast(deployerPrivateKey);
        DauphineToken dauToken = new DauphineToken(deployer);
        vm.stopBroadcast();

        // Deploy CoinflipV1
        vm.startBroadcast(deployerPrivateKey);
        CoinflipV1.Coinflip coinflipV1 = new CoinflipV1.Coinflip();
        vm.stopBroadcast();

        // Deploy Proxy and initialize with CoinflipV1
        vm.startBroadcast(deployerPrivateKey);
        UUPSProxy proxy = new UUPSProxy(
            address(coinflipV1),
            abi.encodeWithSignature("initialize(address,address)", deployer, address(dauToken))
        );
        CoinflipV1.Coinflip wrappedV1 = CoinflipV1.Coinflip(address(proxy));
        vm.stopBroadcast();

        // Simulate User 1 playing and winning in V1
        address user1 = address(0x123);
        vm.startBroadcast(deployerPrivateKey);
        uint8[10] memory correctGuesses = wrappedV1.getFlips();
        bool win1 = wrappedV1.UserInput(correctGuesses, user1);
        vm.stopBroadcast();

        console.log("User 1 Balance after V1 win:", dauToken.balanceOf(user1) / (10 ** dauToken.decimals()));

        // Upgrade to V2
        vm.startBroadcast(deployerPrivateKey);
        CoinflipV2.CoinflipV2 coinflipV2 = new CoinflipV2.CoinflipV2();
        wrappedV1.upgradeToAndCall(
            address(coinflipV2),
            "" // No re-initialization needed, storage is preserved
        );
        CoinflipV2.CoinflipV2 wrappedV2 = CoinflipV2.CoinflipV2(address(proxy));
        vm.stopBroadcast();

        // Simulate User 1 playing and winning in V2
        vm.startBroadcast(deployerPrivateKey);
        correctGuesses = wrappedV2.getFlips();
        bool win2 = wrappedV2.UserInput(correctGuesses, user1);
        vm.stopBroadcast();

        console.log("User 1 Balance after V2 win:", dauToken.balanceOf(user1) / (10 ** dauToken.decimals()));

        // Simulate User 1 transferring tokens to User 2
        address user2 = address(0x456);
        vm.startBroadcast(deployerPrivateKey);
        vm.prank(user1); // Ensure transaction is sent from user1
        dauToken.transfer(user2, 3 * 10 ** dauToken.decimals());
        vm.stopBroadcast();

        console.log("User 1 Balance after transfer:", dauToken.balanceOf(user1) / (10 ** dauToken.decimals()));
        console.log("User 2 Balance after transfer:", dauToken.balanceOf(user2) / (10 ** dauToken.decimals()));
    }
}

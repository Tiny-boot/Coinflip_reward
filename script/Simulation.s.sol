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
        uint256 user1PrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        address user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

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
            address(coinflipV1), abi.encodeWithSignature("initialize(address,address)", deployer, address(dauToken))
        );
        CoinflipV1.Coinflip wrappedV1 = CoinflipV1.Coinflip(address(proxy));
        vm.stopBroadcast();

        // Simulate User 1 playing and winning in V1
        vm.startBroadcast(user1PrivateKey);
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
        vm.startBroadcast(user1PrivateKey);
        correctGuesses = wrappedV2.getFlips();
        bool win2 = wrappedV2.UserInput(correctGuesses, user1);
        vm.stopBroadcast();

        console.log("User 1 Balance after V2 win:", dauToken.balanceOf(user1) / (10 ** dauToken.decimals()));

        // Simulate User 1 transferring tokens to User 2
        uint256 user1BalanceBeforeTransfer = dauToken.balanceOf(user1);
        console.log("User 1 Balance before transfer:", user1BalanceBeforeTransfer / (10 ** dauToken.decimals()));

        // Ensure User 1 has enough balance to transfer
        if (user1BalanceBeforeTransfer >= 3 * 10 ** dauToken.decimals()) {
            // Use vm.startBroadcast and vm.prank to simulate the transaction being sent from user1
            vm.startBroadcast(user1PrivateKey);
            uint256 transferAmount = 3 * 10 ** dauToken.decimals(); // 3 tokens to be transferred
            dauToken.transfer(user2, transferAmount); // Transfer 3 DAU tokens
            vm.stopBroadcast();
        } else {
            console.log("Insufficient balance for transfer.");
        }

        // Log balances of both users after transfer
        uint256 user1BalanceAfterTransfer = dauToken.balanceOf(user1);
        uint256 user2BalanceAfterTransfer = dauToken.balanceOf(user2);

        // Log the balances to make sure the transfer went through
        console.log("User 1 Balance after transfer:", user1BalanceAfterTransfer / (10 ** dauToken.decimals()));
        console.log("User 2 Balance after transfer:", user2BalanceAfterTransfer / (10 ** dauToken.decimals()));
    }
}

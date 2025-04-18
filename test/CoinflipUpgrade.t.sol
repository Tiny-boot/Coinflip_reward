// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import "../src/Coinflip.sol" as CoinflipV1;
import "../src/CoinflipV2.sol" as CoinflipV2;
import {UUPSProxy} from "../src/Proxy.sol";
import {DauphineToken} from "../src/DauphineToken.sol";

contract CoinflipUpgradeTest is Test {
    CoinflipV1.Coinflip public game;
    CoinflipV2.CoinflipV2 public gameV2;
    UUPSProxy public proxy;

    CoinflipV1.Coinflip public wrappedV1;
    CoinflipV2.CoinflipV2 public wrappedV2;
    DauphineToken public dauToken;

    address owner = vm.addr(0x1);
    address player = address(0x123);

    function setUp() public {
        vm.startPrank(owner);
        dauToken = new DauphineToken(owner);
        game = new CoinflipV1.Coinflip();
        gameV2 = new CoinflipV2.CoinflipV2();
        proxy = new UUPSProxy(
            address(game), abi.encodeWithSignature("initialize(address,address)", owner, address(dauToken))
        );
        wrappedV1 = CoinflipV1.Coinflip(address(proxy));
    }

    function test_V1InitialSeed() public view {
        assertEq(wrappedV1.seed(), "It is a good practice to rotate seeds often in gambling");
    }

    function test_UserGetsReward() public {
        uint8[10] memory correctGuesses = wrappedV1.getFlips();
        uint256 balanceBefore = dauToken.balanceOf(player);

        bool result = wrappedV1.UserInput(correctGuesses, player);
        uint256 balanceAfter = dauToken.balanceOf(player);

        assertEq(result, true, "User should win");
        assertEq(balanceAfter, balanceBefore + 5 * 10 ** dauToken.decimals(), "User should receive 5 DAU tokens");
    }

    function test_V1Win() public {
        assertEq(wrappedV1.UserInput([1, 1, 1, 1, 1, 1, 1, 1, 1, 1], player), true);
    }

    function test_Rotation() public {
        wrappedV1.upgradeToAndCall(address(gameV2), "");
        wrappedV2 = CoinflipV2.CoinflipV2(address(proxy));

        wrappedV2.seedRotation("1234567890", 5);
        assertEq(wrappedV2.seed(), "6789012345");
    }
}

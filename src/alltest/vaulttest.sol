// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface IVultfack {
    function vaults(
        uint256 vaultId
    ) external view returns (bytes memory);
}

interface Iforwarder {
    function supportedRouters(address _routers) external returns (bool);
}

contract vaulttTest is Test {

    IVultfack vault = IVultfack(0x155620A2E6A9392c754B73296d9655061525729B);
    address constant router = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    Iforwarder forw = Iforwarder(0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251);

    function setUp() public {
        vm.createSelectFork("https://developer-access-mainnet.base.org", 20295659);
    }

    function testExploit() external {
        // try vault.vaults(15) returns (bytes memory vaultData) {
        //     console.log("Vault data successfully retrieved.");
        //     console.logBytes(vaultData); // Log the returned bytes
        // } catch Error(string memory reason) {
        //     console.log("Error: ", reason);
        // } catch (bytes memory lowLevelData) {
        //     console.log("Low-level error: ");
        //     console.logBytes(lowLevelData);
        // }

        forw.supportedRouters(router);
    }
}

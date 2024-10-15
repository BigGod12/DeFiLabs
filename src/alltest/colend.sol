// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";

interface IDedicatedsender {
    function proxyAdmin() external view returns (address);
}


contract chainportTest is Test {
    IDedicatedsender public ddsender = IDedicatedsender(0x05c2D4ddc349cEf4614F0a5037907B25da4Dcea5);

    function setUp() public {
        vm.createSelectFork("https://rpc.coredao.org", 16307485);
    }


    function testColend_Flashloan() public {
        address proxy = ddsender.proxyAdmin();
        console2.log("proxy admin", proxy);
    }

}
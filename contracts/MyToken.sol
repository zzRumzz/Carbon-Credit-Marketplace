// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarbonToken is ERC20 {
    address public owner;

    constructor(uint256 initialSupply) ERC20("CarbonToken", "CARB") {
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only the owner can mint tokens");
        _mint(to, amount);
    }
}

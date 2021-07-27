// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract StandardSupportedToken is ERC20PresetMinterPauser, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 capWithouDecimals
    ) ERC20PresetMinterPauser(name, symbol) {
        mint(_msgSender(), capWithouDecimals * 1e18);
    }
}

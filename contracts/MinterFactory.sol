// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721GameNFT is IERC721 {
    function mint(address to, uint256 tokenId) external;

    function mintBatch(address to, uint256[] memory tokenIds) external;

    function totalSupply() external view returns (uint256);
}

contract MinterFactory is Ownable, Initializable {
    uint256 public maximumMultipleMintItems;
    // NFT contract
    IERC721GameNFT public erc721;

    event TokenMinted(
        address contractAddress,
        address to,
        uint256 indexed tokenId
    );

    constructor(uint256 _maximumMultipleMintItems) {
        maximumMultipleMintItems = _maximumMultipleMintItems;
    }

    function init(address _erc721) external initializer onlyOwner {
        erc721 = IERC721GameNFT(_erc721);
    }

    /**
     * @dev mint function to distribute spores NFT to user
     */
    function mintTo(address to, uint256 tokenId) external {
        erc721.mint(to, tokenId);
        emit TokenMinted(address(erc721), to, tokenId);
    }

    /**
     * @dev mint function to distribute spores NFT to user
     */
    function mintMultipleTo(address to, uint256[] memory tokenIds) external {
        uint256 numberOfItems = tokenIds.length;
        require(
            numberOfItems <= maximumMultipleMintItems,
            "MinterFactory: invalid number of items to mint"
        );

        for (uint256 i = 0; i < numberOfItems; i++) {
            erc721.mint(to, tokenIds[i]);
            emit TokenMinted(address(erc721), to, tokenIds[i]);
        }
    }
}

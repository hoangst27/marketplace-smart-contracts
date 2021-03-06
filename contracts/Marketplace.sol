// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface IERC721GameNFT is IERC721 {
    function canTransferToken(uint256 tokenId) external returns (bool);
}

contract Marketplace is Ownable, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Supported payment token WETH & list of authorized ERC20
    mapping(address => bool) public paymentTokens;
    // Address to receive transaction fee
    address public feeToAddress;

    // Events
    event MatchTransaction(
        uint256 indexed tokenId,
        address contractAddress,
        uint256 price,
        address paymentToken,
        address seller,
        address buyer,
        uint256 fee
    );

    constructor() {}

    // --- Init ---
    function init(address _feeToAddress, address[] calldata _paymentTokens)
        external
        initializer
        onlyOwner
    {
        feeToAddress = _feeToAddress;
        uint256 tokenLength = _paymentTokens.length;
        for (uint256 i = 0; i < tokenLength; i++) {
            paymentTokens[_paymentTokens[i]] = true;
        }
    }

    function setFeeToAddress(address _feeToAddress) public onlyOwner {
        feeToAddress = _feeToAddress;
    }

    function setPaymentTokens(address[] calldata _paymentTokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            if (paymentTokens[_paymentTokens[i]] == true) {
                continue;
            }

            paymentTokens[_paymentTokens[i]] = true;
        }
    }

    function removePaymentTokens(address[] calldata _removedPaymentTokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _removedPaymentTokens.length; i++) {
            paymentTokens[_removedPaymentTokens[i]] = false;
        }
    }

    /**
     * @dev Function matched transaction with user signatures
     */
    function matchTransaction(
        address[4] calldata addresses,
        uint256[4] calldata values,
        bytes[2] calldata signatures,
        uint256 tokenId
    ) external onlyOwner returns (bool) {
        require(
            paymentTokens[addresses[3]] == true,
            "Marketplace: invalid payment method"
        );

        bytes32 criteriaMessageHash = getMessageHash(
            addresses[2],
            tokenId,
            addresses[3],
            values[1]
        );

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(
            criteriaMessageHash
        );

        require(
            recoverSigner(ethSignedMessageHash, signatures[0]) == addresses[0],
            "Marketplace: invalid seller signature"
        );

        require(
            recoverSigner(ethSignedMessageHash, signatures[1]) == addresses[1],
            "Marketplace: invalid buyer signature"
        );

        // check current ownership
        IERC721GameNFT nft = IERC721GameNFT(addresses[2]);
        require(
            nft.canTransferToken(tokenId),
            "Marketplace: invalid payment method"
        );

        require(
            nft.ownerOf(values[0]) == addresses[0],
            "Marketplace: seller is not owner of this item now"
        );

        // If not spores native token. isApprovedForAll is required
        if (values[2] == 0) {
            require(
                nft.isApprovedForAll(addresses[0], address(this)),
                "Marketplace: seller did not approve market to transfer his item"
            );
        }

        // Check payment approval and buyer balance
        IERC20 paymentContract = IERC20(addresses[3]);
        require(
            paymentContract.balanceOf(addresses[1]) >= values[1],
            "Marketplace: buyer doesn't have enough token to buy this item"
        );
        require(
            paymentContract.allowance(addresses[1], address(this)) >= values[1],
            "Marketplace: buyer doesn't approve spores to spend payment amount"
        );

        // We divide by 1000 to support decimal value such as 2.5% => value * 25 / 1000
        uint256 fee = values[3].mul(values[1]).div(1000);
        uint256 payToSellerAmount = values[1].sub(fee);

        // transfer money to seller
        paymentContract.safeTransferFrom(
            addresses[1],
            addresses[0],
            payToSellerAmount
        );

        // transfer fee to spores address
        if (fee > 0) {
            paymentContract.safeTransferFrom(addresses[1], feeToAddress, fee);
        }

        // transfer item to buyer
        nft.safeTransferFrom(addresses[0], addresses[1], values[0]);

        // emit sale event
        emitEvent(addresses, values);
        return true;
    }

    /**
     * @dev Function to emit transaction matched event
     */
    function emitEvent(
        address[4] calldata addresses,
        uint256[4] calldata values
    ) internal {
        emit MatchTransaction(
            values[0],
            addresses[2],
            values[1],
            addresses[3],
            addresses[0],
            addresses[1],
            values[3]
        );
    }

    function getMessageHash(
        address _nftAddress,
        uint256 _tokenId,
        address _paymentErc20,
        uint256 _price
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_nftAddress, _tokenId, _paymentErc20, _price)
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../interfaces/NFTubeERC1155.sol";

// import "hardhat/console.sol";

contract NFTubeERC1155 is ERC1155Upgradeable, ERC1155SupplyUpgradeable, EIP712Upgradeable, OwnableUpgradeable {
    // Keep track of token balances
    bool public ownerSignatureMintAllowed;
    address public manager;
    uint256 public constant REDEEM_FEE_BASE = 10000;
    string private constant SIGNING_DOMAIN = "NFTube-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    function initialize(string memory _uri, bool _ownerSignatureMintAllowed, address _nftubeManager) external initializer {
        // initialize inherited contracts
        __ERC1155_init(_uri);
        __ERC1155Supply_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __Ownable_init();
        ownerSignatureMintAllowed = _ownerSignatureMintAllowed;
        manager = _nftubeManager;
    }

    function burn( address from, uint256 id, uint256 amount) public onlyOwner {
        if (msg.sender != from) revert NotOwner();
        _burn(from, id, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return interfaceId == type(IUnicERC1155).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 maxTokenId,uint256 minPrice,uint256 maxSupply)"),
            voucher.maxTokenId,
            voucher.minPrice,
            voucher.maxSupply
        )));
        return digest;
    }

    function _transferFee(address recipient, uint256 value) internal {
        (bool success,) = recipient.call{value: value}("");
        if (!success) revert FeeTransferFailed();
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _beforeTokenTransfer(address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
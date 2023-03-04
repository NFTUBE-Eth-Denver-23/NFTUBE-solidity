// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../interfaces/INFTubeERC1155.sol";
import "../interfaces/INFTubeManager.sol";
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

    function mint( address to, uint256 id, uint256 amount) public payable onlyOwner {
        _mint(to, id, amount, "");

        //send asset fee to feeReceiver
        if (msg.value > 0) {
            INFTubeManager(manager).receiveFee{value: msg.value}();
        }
    }

    function mintBatch( address _to, uint256[] calldata _ids, uint256[] calldata _amounts) public payable onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");

        //send asset fee to feeReceiver
        if (msg.value > 0) {
            INFTubeManager(manager).receiveFee{value: msg.value}();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return interfaceId == type(INFTubeERC1155).interfaceId || super.supportsInterface(interfaceId);
    }

    //TODO: consider having manager and creator withdraw the fees instead of transfering for the sake of gas fees
    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(address redeemer, uint256 tokenId, NFTVoucher calldata voucher) public payable returns (uint256) {

        // make sure that the redeemer is paying enough to cover the buyer's cost
        if (msg.value < voucher.minPrice) revert InsufficientFunds();

        // make sure the tokenId the user is trying to mint is within the supported range
        if (voucher.maxTokenId < tokenId) revert TokenNotInRange();

        if (voucher.maxSupply <= totalSupply(tokenId)) revert AboveMaxSupply();

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        if (owner() != signer) revert InvalidSignature();

        _mint(redeemer, tokenId, 1, "");

        INFTubeManager nftubeManager = INFTubeManager(manager);
        uint256 redeemFeeInPercentage = nftubeManager.redeemFee();
        uint256 totalFee = msg.value - voucher.minPrice;
        //send asset fee + redeem fee to feeReceiver
        if (redeemFeeInPercentage > 0) {
            totalFee += (voucher.minPrice * redeemFeeInPercentage / REDEEM_FEE_BASE);
        }

        if (totalFee > 0) {
            nftubeManager.receiveFee{value: totalFee}();
            _transferFee(signer, msg.value - totalFee);
        } else {
            _transferFee(signer, msg.value);
        }

        emit Redeemed(signer, redeemer, tokenId, voucher.minPrice, redeemFeeInPercentage, totalFee);

        return voucher.maxTokenId;
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
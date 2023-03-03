// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INFTubeERC1155 {
    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 maxTokenId;

        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;

        /// @notice Supply per token
        uint256 maxSupply;

        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    function initialize(string memory _uri, bool _ownerSignatureMintAllowed, address _nftubeManager) external;

    function burn( address from, uint256 id, uint256 amount) external;

    function mint( address to, uint256 id, uint256 amount) external payable;

    function mintBatch( address _to, uint256[] memory _ids, uint256[] memory _amounts) external payable;

    function redeem(address redeemer, uint256 tokenId, NFTVoucher calldata voucher) external payable returns (uint256);

    event Redeemed(
        address _signer,
        address _redeemer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _redeemFeeInPercentage,
        uint256 _assetFee
    );

    error NotOwner();
    error InvalidSignature();
    error AboveMaxSupply();
    error InsufficientFunds();
    error TokenNotInRange();
    error RoyaltyTooHigh();
    error FeeTransferFailed();
}
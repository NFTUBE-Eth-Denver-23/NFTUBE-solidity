// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INFTubeERC1155 {
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
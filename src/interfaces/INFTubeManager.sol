//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTubeManager {
    function deployERC1155(
        string memory _uri,
        bool _ownerSignatureMintAllowed
    ) external returns (address newERC1155);

    function setFeeReceiver(address _receiver) external;

    function feeReceiver() external view returns (address);

    function redeemFee() external view returns (uint256);

    function receiveFee() external payable;

    event FeeReceiverSet(
        address _previous,
        address _new
    );

    event RedeemFeeSet(
        uint256 _previous,
        uint256 _new
    );

    event ERC1155Deployed(
        address _contract,
        address _creator,
        string _uri,
        bool _ownerSignatureMintAllowed
    );

    event FeeReceived(
        address _sender,
        uint256 _amount
    );

    error ZeroAddress();
    error FeeTransferFailed();
    error FeeTooBig();
}
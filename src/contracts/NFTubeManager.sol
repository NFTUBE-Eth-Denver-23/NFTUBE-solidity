// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./NFTubeERC1155.sol";
import "./InitializedProxy.sol";
import "../interfaces/INFTubeManager.sol";

contract NFTubeManager is INFTubeManager, Ownable, Pausable {
    uint256 public redeemFee;
    address public feeReceiver;
    address public logic;

    constructor(uint256 _redeemFee, address _feeReceiver) {
        redeemFee = _redeemFee;
        feeReceiver = payable(_feeReceiver);
        logic = address(new NFTubeERC1155());
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        emit FeeReceiverSet(feeReceiver, _feeReceiver);
        feeReceiver = payable(_feeReceiver);
    }

    function setRedeemFee(uint256 _redeemFee) public onlyOwner {
        if (_redeemFee > 1000) revert FeeTooBig(); //10%
        emit RedeemFeeSet(redeemFee, _redeemFee);
        redeemFee = _redeemFee;
    }

    function receiveFee() public payable {
        if (msg.value > 0) {
            (bool success,) = feeReceiver.call{value: msg.value}("");
            if (!success) revert FeeTransferFailed();
            emit FeeReceived(msg.sender, msg.value);
        }
    }

    function deployERC1155(
        string memory _uri,
        bool _ownerSignatureMintAllowed
    ) external override whenNotPaused returns (address newERC1155) {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,bool,address)",
            _uri,
            _ownerSignatureMintAllowed,
            address(this)
        );

        newERC1155 = address(
            new InitializedProxy(
                logic,
                _initializationCalldata
            )
        );

        Ownable(newERC1155).transferOwnership(msg.sender);
        emit ERC1155Deployed(newERC1155, msg.sender, _uri, _ownerSignatureMintAllowed);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";
import {IERC1363} from "openzeppelin/interfaces/IERC1363.sol";
import {IERC1363Receiver} from "openzeppelin/interfaces/IERC1363Receiver.sol";
import {IERC1363Spender} from "openzeppelin/interfaces/IERC1363Spender.sol";

contract NFTtoken is ERC721, IERC1363Receiver, IERC1363Spender {
    using ERC165Checker for address;

    uint256 public tokenid;
    address _nativo;
    bool badImplementation;

    event TokensReceived(address indexed operator, address indexed sender, uint256 amount, bytes data);
    event TokensApproved(address indexed sender, uint256 amount, bytes data);

    constructor(address nativo_, bool _badImplementation) ERC721("TestNFT", "TestNFT") {
        _nativo = nativo_;
        badImplementation = _badImplementation;
    }

    function onTransferReceived(address spender, address sender, uint256 amount, bytes memory data)
        public
        override
        returns (bytes4)
    {
        require(msg.sender == address(_nativo), "ERC1363Payable: acceptedToken is not message sender");

        emit TokensReceived(spender, sender, amount, data);

        _transferReceived(spender, sender, amount, data);
        
        if (badImplementation) {
            return bytes4(0);
        }

        return IERC1363Receiver.onTransferReceived.selector;
    }

    function onApprovalReceived(address sender, uint256 amount, bytes memory data) public override returns (bytes4) {
        require(msg.sender == address(_nativo), "ERC1363Payable: acceptedToken is not message sender");

        emit TokensApproved(sender, amount, data);

        _approvalReceived(sender, amount, data);

        if (badImplementation) {
            return bytes4(0);
        }
        
        return IERC1363Spender.onApprovalReceived.selector;
    }

    function _transferReceived(address spender, address sender, uint256 amount, bytes memory data) internal {
        require(amount == 0.5 ether, "Send 0.5 ether");
        _mint(sender, ++tokenid);
    }

    function _approvalReceived(address sender, uint256 amount, bytes memory data) internal {
        require(amount == 0.5 ether, "Send 0.5 ether");
        IERC20(_nativo).transferFrom(sender, address(this), amount);
        _mint(sender, ++tokenid);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId || interfaceId == type(IERC1363Spender).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

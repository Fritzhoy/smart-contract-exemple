// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract BaseContract is ERC1155, AccessControl, IERC2981, ERC1155Supply {
    using Strings for string;
    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    string public name;
    address private royaltiesRecipient;
    uint8 royaltiesPercentage;
    mapping(uint256 => uint256) private _totalSupply;

    modifier tokenOwnerOnly(uint256 tokenId) {
        _;
    }

    constructor(
        address _client,
        uint8 _royaltiesPercentage,
        address _royaltiesRecipient
        _setupRole(OPERATOR, _client); //Client Wallet
        _setupRole(OPERATOR, msg.sender); //GoBlockchain
    }

    }

        _burn(from, id, amount);
    }

    }

        // Avoid to mint the same ids twice
        for(uint256 i=0; i < ids.length; i++){
    }

    /** @dev EIP2981 royalties implementation. */

    function _setRoyalties(address _newRecipient) internal {
        royaltiesRecipient = _newRecipient;
    }

        _setRoyalties(_newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        //1 corresponds to 1%
    }
    /*since the function appearances in both contracts
    *erc115 and erc1155supply we need to creat the same
    *function in our base contract and override it */
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override (ERC1155Supply, ERC1155) {

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165, AccessControl)
        returns (bool)
    {
        //IERC165
        return (
        interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

}

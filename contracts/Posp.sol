// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./PospPausable.sol";
import "./PospRoles.sol";

contract Posp is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PospRoles, PospPausable {
  event SkillToken(uint256 skillId, uint256 tokenId);

  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private tokenId_;

  string private name_;
  string private symbol_;
  string private baseURI_;
  bool private allowsTransfers_;

  /**
    @dev this will map each tokenId to a skillId.
   */
  mapping(uint256 => uint256) private tokenToSkill_;


  function initialize(string memory __name, string memory __symbol, string memory __baseURI, address[] memory admins) public virtual initializer {
    __ERC721_init(__name, __symbol);
    __ERC721Enumerable_init();
    pospRolesInit();
    pospPausableInit();

    for (uint256 i = 0; i < admins.length; i++) {
      _addAdmin(admins[i]);
    }

    name_ = __name;
    symbol_ = __symbol;
    baseURI_ = __baseURI;
    allowsTransfers_ = false;
  }

  function tokenToSkill(uint256 tokenId) public view returns (uint256) {
    return tokenToSkill_[tokenId];
  }

  /**
    @dev gets the tokenId and skillId for a token at a given index of the tokens list for the requested owner
    @param owner address owning the token list to be accessed
    @param index uint256 representing the index to be accessed of the requested token list
    @return (uint256 tokenId, uint256 skillId)
  */
  function tokenDetailsOfOwnerByIndex(address owner, uint256 index) public view returns (uint256, uint256) {
    uint256 tokenId = tokenOfOwnerByIndex(owner, index);
    uint256 skillId = tokenToSkill(tokenId);
    return (tokenId, skillId);
  }

  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    uint256 skillId = tokenToSkill_[tokenId];
    return _strConcat(baseURI_, _uint2str(skillId), "/", _uint2str(tokenId), "");
  }

  function setBaseURI(string memory __baseURI) public onlyRole(ADMIN_ROLE) whenNotPaused {
    baseURI_ = __baseURI;
  }

  /**
    @dev mints a token for a specific skill to the given address
    @param skillId uint256 representing the ID of the skill we are minting a token for
    @param to address of the user receiving the token
    @return true on success, otherwise will revert
  */
  function mintToken(uint256 skillId, address to) public onlySkillMinter(skillId) whenNotPaused returns (bool) {
    uint256 currentId = tokenId_.current();
    tokenId_.increment();
    return _mintToken(skillId, currentId, to);
  }


  /**
    @dev mints a token for a specific skill to an array of addresses
    @param skillId uint256 representing the ID of the skill we are minting a token for
    @param to address[] containing addresses of users receiving a token for this skill
    @return true on success, otherwise will revert
   */
  function mintTokenToManyUsers(uint256 skillId, address[] memory to) public onlySkillMinter(skillId) whenNotPaused returns (bool) {
    for (uint256 i = 0; i < to.length; i++) {
      mintToken(skillId, to[i]);
    }

    return true;
  }

  function _mintToken(uint256 skillId, uint256 tokenId, address to) internal returns (bool) {
    _mint(to, tokenId);
    tokenToSkill_[tokenId] = skillId;
    emit SkillToken(skillId, tokenId);
    return true;
  }

  // overrides required by Solidity

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
    @dev do not alter, this prevents users from being able to transfer their NFTs*, essentially locking them to the original account it was minted to.
    * - unless they are burning the nft by sending it to address(0)
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
    require(from == address(0) || to == address(0) || allowsTransfers_, "Transfers not allowed");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // utility methods
  /**
     * @dev Function to convert uint to string
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
          /**
            @dev Prior to version 0.8.0, byte used to be an alias for bytes1.
            see https://docs.soliditylang.org/en/latest/types.html#fixed-size-byte-arrays
           */
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

  /**
  * @dev Function to concat strings
  * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  */
  function _strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e)
  internal pure returns (string memory _concatenatedString)
  {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      uint i = 0;
      for (i = 0; i < _ba.length; i++) {
          babcde[k++] = _ba[i];
      }
      for (i = 0; i < _bb.length; i++) {
          babcde[k++] = _bb[i];
      }
      for (i = 0; i < _bc.length; i++) {
          babcde[k++] = _bc[i];
      }
      for (i = 0; i < _bd.length; i++) {
          babcde[k++] = _bd[i];
      }
      for (i = 0; i < _be.length; i++) {
          babcde[k++] = _be[i];
      }
      return string(babcde);
  }
}
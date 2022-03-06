// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PospRoles is Initializable, AccessControlUpgradeable {
  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);
  event SkillMinterAdded(uint256 indexed skillId, address indexed account);
  event SkillMinterRemoved(uint256 indexed skillId, address indexed account);

  error NotMinter(uint256 skillId, address account);

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
    @dev uint256 = skillId, internal mapping will return false if address does not exist or is no longer a minter for this skill
   */
  mapping(uint256 => mapping(address => bool)) private _minters;

  /**
    @return true if `account` has minting permissions for `skillId`, false otherwise
   */
  function isSkillMinter(uint256 skillId, address account) public view returns (bool) {
    return hasRole(ADMIN_ROLE, account) || (_minters[skillId][account] && hasRole(MINTER_ROLE, account));
  }

  /**
    @dev modifier to only allow a function to be called if the caller has minting permissions for a given skillId
   */
  modifier onlySkillMinter(uint256 skillId) {
    if (!isSkillMinter(skillId, msg.sender)) {
      revert NotMinter(skillId, msg.sender);
    }
    _;
  }

  function pospRolesInit() public virtual initializer {
    __AccessControl_init();

    /**
      @notice grants the admin and minter role to the address that calls this initialization method first (it cannot be called again after this happens)
     */
    _grantRole(ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

    /**
      @notice grants the ADMIN_ROLE with role granting/revoking capabilities over the admin and minter roles
      @dev this grants ANY person with the admin role these permissions. i.e any admin can revoke any other admin's permissions. 
     */
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
  }

  function addAdmin(address account) public onlyRole(ADMIN_ROLE) {
    _addAdmin(account);    
  }

  function renounceAdmin(address account) public onlyRole(ADMIN_ROLE) {
    _removeAdmin(account);
  }

  function addSkillMinter(uint256 skillId, address account) public onlySkillMinter(skillId) {
    _addSkillMinter(skillId, account);
  }

  function renounceSkillMinter(uint256 skillId, address account) public onlySkillMinter(skillId) {
    _removeSkillMinter(skillId, account);
  }

  function _addAdmin(address account) internal {
    grantRole(ADMIN_ROLE, account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    revokeRole(ADMIN_ROLE, account);
    emit AdminRemoved(account);
  }

  function _addSkillMinter(uint256 skillId, address account) internal {
    grantRole(MINTER_ROLE, account);
    emit SkillMinterAdded(skillId, account);
  }

  function _removeSkillMinter(uint256 skillId, address account) internal {
    revokeRole(MINTER_ROLE, account);
    delete _minters[skillId][account];
    emit SkillMinterRemoved(skillId, account);
  }
}


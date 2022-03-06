// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./PospRoles.sol";

contract PospPausable is Initializable, PausableUpgradeable, PospRoles {
  function pospPausableInit() public virtual initializer {
    __Pausable_init();
  }

  function pause() public onlyRole(ADMIN_ROLE) whenNotPaused {
    _pause();
  }

  function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
    _unpause();
  }
}
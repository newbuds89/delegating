// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@1inch/solidity-utils/contracts/libraries/AddressSet.sol";
import "./BasicDelegation.sol";
import "./SolvingDelegateeToken.sol";
import "../interfaces/IDelegateeToken.sol";

contract SolvingDelegation is BasicDelegation {
    using AddressSet for AddressSet.Data;

    error NotRegisteredDelegatee();
    error AnotherDelegateeToken();

    mapping(address => IDelegateeToken) public registration;
    AddressSet.Data private _delegateeTokens;

    constructor(string memory name_, string memory symbol_) BasicDelegation(name_, symbol_) {}

    function setDelegate(address account, address delegatee) public override {
        if (delegatee != address(0) && registration[delegatee] == IDelegateeToken(address(0))) revert NotRegisteredDelegatee();
        super.setDelegate(account, delegatee);
    }

    function updateBalances(address from, address to, uint256 amount) public override {
        super.updateBalances(from, to, amount);

        if (to != address(0)) {
            try registration[delegated[to]].mint{gas:200_000}(to, amount) {} catch {}
        }
        if (from != address(0)) {
            try registration[delegated[from]].burn{gas:200_000}(from, amount) {} catch {}
        }
    }

    function register(string memory name_, string memory symbol_) external returns(IDelegateeToken) {
        registration[msg.sender] = new SolvingDelegateeToken(name_, symbol_);
        _delegateeTokens.add(address(registration[msg.sender]));
        return registration[msg.sender];
    }

    // @notice It's neccussary to give token's owner role equals to SolvingDelegation contract via `ownerTransfership`
    function register(IDelegateeToken token) external {
        if (_delegateeTokens.contains(address(token))) revert AnotherDelegateeToken();
        registration[msg.sender] = token;
        _delegateeTokens.add(address(token));
    }
}

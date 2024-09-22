// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Profile} from "./Profile.sol";

import {EquitoApp} from "../lib/equito/src/EquitoApp.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../lib/equito/src/libraries/EquitoMessageLibrary.sol";

contract Token is ERC20, EquitoApp {
    address public profile;
    address public world;

    constructor(address _initialOwner, address _world, address _profile, address _router) ERC20("CUBE Token", "CUBE") EquitoApp(_router) {
        profile = _profile;
        world = _world;
    }

     /// @notice Sends a cross-chain message using Equito.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param amount The amount of tokens to send.
    function crossChainTransfer(
        bytes64 calldata receiver,
        uint256 destinationChainSelector,
        uint256 amount
    ) external payable {
        _burn(msg.sender, amount);
        bytes memory data = abi.encode(receiver, amount);
        router.sendMessage{value: msg.value}(
            getPeer(destinationChainSelector),
            destinationChainSelector,
            data
        );
    }

    /// @notice Receives a cross-chain message from a peer.
    ///         Mints the appropriate amount of tokens to the receiver address.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromPeer(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) internal override {
        (bytes64 memory receiver, uint256 amount) = abi.decode(
            messageData,
            (bytes64, uint256)
        );
        _mint(EquitoMessageLibrary.bytes64ToAddress(receiver), amount);
    }

    modifier onlyUser() {
        require(Profile(profile).balanceOf(_msgSender()) > 0, "Only user can call this function");
        _;
    }

    modifier onlyWorld() {
        require(_msgSender() == world, "Only world can call this function");
        _;
    }

    function setWorld(address _world) public onlyOwner {
        world = _world;
    }

    function mint(address to, uint256 _amount) public onlyWorld {
        _mint(to, _amount);
    }

    function burn(address from, uint256 _amount) public onlyWorld {
        _burn(from, _amount);
    }
}
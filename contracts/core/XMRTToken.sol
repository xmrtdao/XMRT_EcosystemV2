// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract XMRTToken {
    string public name = "XMRT";
    string public symbol = "XMRT";
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
}
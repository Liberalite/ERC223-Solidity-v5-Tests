pragma solidity 0.5.7;

/**
 * @title Contract that is working with ERC223 tokens
 * @dev https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223ReceivingContract { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint256 _value, bytes memory _data) public;
}
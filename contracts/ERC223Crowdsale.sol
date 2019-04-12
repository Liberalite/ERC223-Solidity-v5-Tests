pragma solidity 0.5.7;

import "./Owned.sol";
import "./SafeMath.sol";
import "./SafeERC223.sol";
import "./ERC223Interface.sol";
import "./ReentrancyGuard.sol";

contract ERC223Crowdsale is ReentrancyGuard, Owned {
    using SafeMath for uint256;
    using SafeERC223 for ERC223Interface;

    // TOKEN INTERFACE,
    ERC223Interface private token;
    
    // PRE-SALE WALLET
    address payable private wallet;

    // TOTAL ETHER RAISED
    uint public totalRaised;
    
    // TOTAL TOKENS DISTRIBUTED
    uint public tokensSold;

    // KYC VALIDATION, ADDRESS DEPOSIT LIMIT
    mapping(address => bool) private _kyc;
    mapping(address => uint) public senderLimit;

    // EVENT THAT WHEN SOMEONE HAS CONTRIBUTED TO THE PRE-SALE
    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount);

    // DEPLOY PRE-SALE WITH TOKEN ADDRESS AND CONTRIBUTIONS WALLET
    constructor(ERC223Interface _token, address payable _wallet) public {
        token = _token;
        wallet = _wallet;
    }
    
    // GET ICO ADDRESS
    function icoAddress() public view returns(address) {
        return address(this);
    }
    
    // GET CONTRACT TOTAL TOKENS LEFT FOR SALE
    function checkBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
    
    // KYC - VALIDATE OR INVALIDATE ADDRESS
    function updateKYC(address userAddress, bool status) public onlyOwner returns(bool) {
        _kyc[userAddress] = status;
        return status;
    }
    
    // KYC - CHECK IF ADDRESS HAS BEEN VALIDATED
    function checkKYC(address userAddress) public view returns(bool) {
        return _kyc[userAddress];
    }

    // PAYABLE FUNCTION
    function () external payable {
        buyTokens(msg.sender);
    }
    
    //----------------------------------------------------------
    // 1 ETH = 1,000 TOKENS => 1 ETH + 50% BONUS = 1,500 TOKENS
    //----------------------------------------------------------
    function buyTokens(address beneficiary) public nonReentrant payable {
        require(checkBalance() > 0);
        require(beneficiary == msg.sender);

        uint256 weiAmount = msg.value;
        uint tokens = weiAmount * 1500;
        
        tokensSold = tokensSold.add(tokens);
        totalRaised = totalRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        _forwardFunds();

        senderLimit[beneficiary] = senderLimit[beneficiary].add(weiAmount);
            
        if(_kyc[beneficiary] == false){
            require(weiAmount >= .1 ether && weiAmount <= 25 ether && senderLimit[beneficiary] <= 25 ether);
        } else if (_kyc[beneficiary] == true) {
            require(weiAmount >= .1 ether && weiAmount <= 100 ether && senderLimit[beneficiary] <= 100 ether);
        }
            
        emit TokensPurchased(beneficiary, weiAmount, tokens);
    }
    
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        token.safeTransfer(beneficiary, tokenAmount);
    }
    
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }
    
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
    function _transferToBonusReserve(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }
    
    function unlockBlockedERC20Tokens(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC223Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function tokenFallback(address _owner, uint tokens, bytes memory data) public nonReentrant {
        require(msg.sender == address(token));
        require(owner == _owner);
        emit DepositedTokens(owner, tokens, data);
    }
    
    event DepositedTokens(address from, uint value, bytes data);
}
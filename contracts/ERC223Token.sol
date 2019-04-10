pragma solidity 0.5.7;

import "./SafeMath.sol";
import "./ERC223Interface.sol";
import "./ERC223ReceivingContract.sol";

/**
 * @title Implementation of the ERC223 standard token
 * @dev https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223Token is ERC223Interface {
    using SafeMath for uint256;
    
    address private _owner;
    
    string  public  constant name = "ERC223";
    string  public  constant symbol = "ERC223";
    uint8   public  constant decimals = 18;
    uint256 private constant _totalSupply = 10000000 * (uint256(10) ** decimals);
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    constructor() public {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value > 0 && balanceOf(msg.sender) >= value);
        require(balanceOf(to).add(value) > balanceOf(to));
        
        uint256 codeLength;
        bytes memory empty;

        assembly {
            codeLength := extcodesize(to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, empty);
        }
        
        emit Transfer(msg.sender, to, value, empty);
        return true;
    }
    
    function transfer(address to, uint256 value, bytes memory data) public returns (bool success) {
        require(to != address(0));
        require(value > 0 && balanceOf(msg.sender) >= value);
        require(balanceOf(to).add(value) > balanceOf(to));
        
        uint256 codeLength;

        assembly {
            codeLength := extcodesize(to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        
        emit Transfer(msg.sender, to, value, data);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool success) {
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool success) {
        uint256 oldValue = _allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function unlockBlockedERC20Tokens(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(msg.sender == _owner);
        return ERC223Interface(tokenAddress).transfer(_owner, tokens);
    }
    
    function () external payable {
        revert("This contract does not accept ETH");
    }
    
}
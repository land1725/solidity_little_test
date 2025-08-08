// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MYERC20 is IERC20 {
    uint256 private _totalSupply;
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string public name = "My ERC20 Token";
    string public symbol = "MET";
    uint8 public decimals = 18;

    constructor() {
        _owner = msg.sender;
        // 给创建者初始供应代币
        _totalSupply = decimals;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value)
        external
        returns (bool)
    {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 value)
        external
        haveEnoughMoney(value)
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer to the zero address");
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _allowances[from][msg.sender] >= value,
            "ERC20: insufficient allowance"
        );
        require(
            _balances[from] >= value,
            "ERC20: transfer amount exceeds balance"
        );
        _allowances[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(uint256 value) public {
        require(msg.sender == _owner, "you are not allowed to mint");
        _totalSupply += value;
        _balances[_owner] += value;
        emit Transfer(address(0), _owner, value);
    }

    modifier haveEnoughMoney(uint256 value) {
        require(_balances[msg.sender] >= value, "not enough money");
        _;
    }
}

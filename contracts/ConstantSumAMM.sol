// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;
import "./interfaces/IERC20.sol";

contract AnyxSwapCS {

    // Governing Equation X+Y = K
    // Utilities: Add Liquidity, Swap Tokens, Remove Liquidity

    IERC20 immutable public tokenA;
    IERC20 immutable public tokenB;

    uint public s_reserveA;
    uint public s_reserveB;
    uint public s_totalSharesMinted;

    mapping (address => uint) public individualShares;

    function _updateReserves(uint _amountA, uint _amountB) internal {
        s_reserveA = _amountA;
        s_reserveB = _amountB;
    }

    function _mintShares(address _to, uint _amount) internal {
        individualShares[_to] += _amount;
        s_totalSharesMinted += _amount;
    }

    function _burnShares(address _user, uint _amount) internal {
        delete individualShares[_user];
        s_totalSharesMinted -= _amount;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    //@notice Adds Liquidity and mints corresponding shares
    function addLiquidity(uint amountA, uint amountB) external returns (uint shares) {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if(s_totalSharesMinted == 0)
            shares = amountA + amountB;
        else
            shares = ((amountA + amountB) * s_totalSharesMinted) / (s_reserveA + s_reserveB);

        require(shares > 0, "Shares can't be zero");
        _mintShares(msg.sender, shares);
        _updateReserves(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    //@notice Swaps token A for B or vice versa; dx = dy
    function swapTokens(address _tokenIn, uint _amountIn) external {
        require(_tokenIn == address(tokenA) || _tokenIn == address(tokenB), "Invalid Token Address");
        require(_amountIn > 0, "Amount should be greater than 0");

        bool isTokenA = _tokenIn == address(tokenA);
        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) = isTokenA ?
            (tokenA, tokenB, s_reserveA, s_reserveB) : (tokenB, tokenA, s_reserveB, s_reserveA);
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        // Fees: 0.3%
        uint _amountOutAfterFeesCut = (_amountIn * 997) / 1000;
        (uint _reserveA, uint _reserveB) = isTokenA ?
        (reserveIn + _amountIn, reserveOut - _amountOutAfterFeesCut) :
            (reserveOut - _amountOutAfterFeesCut, reserveIn + _amountIn);
        _updateReserves(_reserveA, _reserveB);
        tokenOut.transfer(msg.sender, _amountOutAfterFeesCut);
    }

    //@notice Burn Shares to return user tokenA and tokenB
    function removeLiquidity() external {
        uint userShares = individualShares[msg.sender];
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));

        uint tokenAOut = (s_reserveA * userShares)/s_totalSharesMinted;
        uint tokenBOut = (s_reserveB * userShares)/s_totalSharesMinted;
        _burnShares(msg.sender, userShares);
        _updateReserves(balanceA - tokenAOut, balanceB - tokenBOut);
        tokenA.transfer(msg.sender, tokenAOut);
        tokenB.transfer(msg.sender, tokenBOut);
    }

}
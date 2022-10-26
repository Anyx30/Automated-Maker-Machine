pragma solidity ^0.8.12;

import "./interfaces/IERC20.sol";
import "hardhat/console.sol";

contract AnyxSwap {

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    // How much tokenA is inside contract
    uint public reserveA;
    // How much tokenB is inside contract
    uint public reserveB;
    uint public totalShares;
    mapping (address => uint) public sharesOfIndividual;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function _mintShares(address _to, uint _amount) internal {
        sharesOfIndividual[_to] += _amount;
        totalShares += _amount;
    }

    function _burnShares(address _to, uint _amount) internal {
        sharesOfIndividual[_to] -= _amount;
        totalShares -= _amount;
    }

    function _updateReserves(uint _reserveA, uint _reserveB) internal {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint _sharesX, uint _sharesY) private pure returns (uint){
        return _sharesX <= _sharesY ? _sharesX : _sharesY;
    }

    function swapTokens(address _tokenIn, uint _amountIn) external {
        require(_tokenIn == address(tokenA) || _tokenIn == address(tokenB), "Invalid Token Address");
        require(_amountIn > 0, "Amount should be greater than 0");

        bool isTokenA = _tokenIn == address(tokenA);
        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) = isTokenA ?
            (tokenA, tokenB, reserveA, reserveB): (tokenB, tokenA, reserveB, reserveA);
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        // Fee: 0.3%
        uint _amountInWithFee = (_amountIn * 997) / 1000;
        //Amount Out: dy = ydx/(x + dx)
        uint _amountOut = (reserveOut * _amountInWithFee)/(reserveIn + _amountInWithFee);
        tokenOut.transfer(msg.sender, _amountOut);
        _updateReserves(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function addLiquidity(uint _amountA, uint _amountB) external returns (uint shares){
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        // Constraint: dy/dx = Y/X
        if (reserveA > 0 || reserveB > 0) {
            require(reserveA/reserveB == _amountA/_amountB, "dy/dx != Y/X");
        }

        // Mint Shares
        // s = (dy/Y) * T = (dx/X) * T
        if (totalShares == 0) {
            shares = _sqrt(_amountA * _amountB);
        }
        else {
            shares = _min(
                _amountA * totalShares / reserveA,
                _amountB * totalShares / reserveB
            );
        }

        require(shares > 0, "Shares = 0");
        _mintShares(msg.sender, shares);
        _updateReserves(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function removeLiquidity() external {
        // balanceOfTokenA >= reserveA (Hehe)
        uint balanceOfTokenA = tokenA.balanceOf(address(this));
        uint balanceOfTokenB = tokenB.balanceOf(address(this));
        uint sharesOfCaller = sharesOfIndividual[msg.sender];

        // Return Liquidity dy = (s/T) * Y ; dx = (s/T) * X
        uint dx = (sharesOfCaller * balanceOfTokenA) / totalShares;
        uint dy = (sharesOfCaller * balanceOfTokenB) / totalShares;

        _burnShares(msg.sender, sharesOfCaller);
        _updateReserves(balanceOfTokenA - dx, balanceOfTokenB - dy);

        tokenA.transfer(msg.sender, dx);
        tokenB.transfer(msg.sender, dy);
    }

}
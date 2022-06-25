// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/ZetaInterfaces.sol";

interface ZetaTokenConsumerUniV2Errors {
    error ErrorGettingZeta();

    error ErrorExchangingZeta();
}

/**
 * @dev Uniswap V2 strategy for ZetaTokenConsumer
 */
contract ZetaTokenConsumerUniV2 is ZetaTokenConsumer, ZetaTokenConsumerUniV2Errors {
    uint256 internal constant MAX_DEADLINE = 100;

    address public uniswapV2RouterAddress;
    address internal immutable wETH;
    address public zetaToken;

    IUniswapV2Router02 internal uniswapV2Router;

    constructor(address zetaTokenInput_, address uniswapV2Router_) {
        zetaToken = zetaTokenInput_;
        uniswapV2RouterAddress = uniswapV2Router_;
        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);
        wETH = uniswapV2Router.WETH();
    }

    function getZetaFromEth(address destinationAddress, uint256 minAmountOut) external payable override {
        address[] memory path = new address[](2);
        path[0] = wETH;
        path[1] = zetaToken;

        uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            minAmountOut,
            path,
            destinationAddress,
            block.timestamp + MAX_DEADLINE
        );
    }

    function getZetaFromToken(
        address destinationAddress,
        uint256 minAmountOut,
        address inputToken,
        uint256 inputTokenAmount
    ) external override {
        bool success = IERC20(inputToken).transferFrom(msg.sender, address(this), inputTokenAmount);
        if (!success) revert ErrorGettingZeta();
        success = IERC20(inputToken).approve(uniswapV2RouterAddress, inputTokenAmount);
        if (!success) revert ErrorGettingZeta();

        address[] memory path;
        if (inputToken == wETH) {
            path = new address[](2);
            path[0] = wETH;
            path[1] = zetaToken;
        } else {
            path = new address[](3);
            path[0] = inputToken;
            path[1] = wETH;
            path[2] = zetaToken;
        }

        uniswapV2Router.swapExactTokensForTokens(
            inputTokenAmount,
            minAmountOut,
            path,
            destinationAddress,
            block.timestamp + MAX_DEADLINE
        );
    }

    function getEthFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        uint256 zetaTokenAmount
    ) external override {
        bool success = IERC20(zetaToken).transferFrom(msg.sender, address(this), zetaTokenAmount);
        if (!success) revert ErrorExchangingZeta();
        success = IERC20(zetaToken).approve(uniswapV2RouterAddress, zetaTokenAmount);
        if (!success) revert ErrorExchangingZeta();

        address[] memory path = new address[](2);
        path[0] = zetaToken;
        path[1] = wETH;

        uniswapV2Router.swapExactTokensForETH(
            zetaTokenAmount,
            minAmountOut,
            path,
            destinationAddress,
            block.timestamp + MAX_DEADLINE
        );
    }

    function getTokenFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        address outputToken,
        uint256 zetaTokenAmount
    ) external override {
        bool success = IERC20(zetaToken).transferFrom(msg.sender, address(this), zetaTokenAmount);
        if (!success) revert ErrorExchangingZeta();
        success = IERC20(zetaToken).approve(uniswapV2RouterAddress, zetaTokenAmount);
        if (!success) revert ErrorExchangingZeta();

        address[] memory path;
        if (outputToken == wETH) {
            path = new address[](2);
            path[0] = zetaToken;
            path[1] = wETH;
        } else {
            path = new address[](3);
            path[0] = zetaToken;
            path[1] = wETH;
            path[2] = outputToken;
        }

        uniswapV2Router.swapExactTokensForTokens(
            zetaTokenAmount,
            minAmountOut,
            path,
            destinationAddress,
            block.timestamp + MAX_DEADLINE
        );
    }
}

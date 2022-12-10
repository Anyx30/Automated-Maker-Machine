// const { expect } = require("chai");
// const { parseEther, parseUnits } = require("ethers/lib/utils");
// const { ethers, network, utils } = require("hardhat");
// const { BigNumber } = require("ethers");
//
// describe("Constant Product AMM Test Suite", async () => {
//     let owner, alice, bob, tokenA, tokenB, amm;
//     before(async () => {
//         [owner, alice, bob] = await ethers.getSigners()
//         let A = await ethers.getContractFactory('TokenA')
//         tokenA = await A.deploy()
//
//         let B = await ethers.getContractFactory('TokenB')
//         tokenB = await B.deploy()
//
//         let swap = await ethers.getContractFactory('AnyxSwapCP')
//         amm = await swap.deploy(tokenA.address, tokenB.address)
//     })
//
//     describe("Add Initial Liquidity", async () => {
//         it("Alice mints 1000 token A and 1000 token B and adds to LP 1000 A and 500 B", async () => {
//             await tokenA.mint(alice.address, 1000)
//             await tokenB.mint(alice.address, 1000)
//             await tokenA.connect(alice).approve(amm.address, parseEther('10000000'))
//             await tokenB.connect(alice).approve(amm.address, parseEther('10000000'))
//             await amm.connect(alice).addLiquidity(1000, 500)
//         })
//
//         it('Expected Shares received √XY', async () => {
//             expect(await amm.sharesOfIndividual(alice.address)).to.eq('707')
//         })
//     })
//
//     describe('Bob swaps token A for token B', async () => {
//         it("Bob deposits 100 token A and received correct amount of token B", async () => {
//             await tokenA.mint(bob.address, 1000)
//             await tokenA.connect(bob).approve(amm.address, parseEther('10000'))
//             await amm.connect(bob).swapTokens(tokenA.address, 100)
//             // dy = 100*500/1100
//             expect(await tokenB.balanceOf(bob.address)).to.eq('45')
//             expect(await amm.reserveA()).to.eq(1100)
//             expect(await amm.reserveB()).to.eq(455)
//         })
//
//         it("Alice now deposits 120 token B and receives token A", async () => {
//             await amm.connect(alice).swapTokens(tokenB.address, 120)
//             // dx = (120*997/1000) * 1100/ 575 = 228 [since there is fee cut].
//             expect(await tokenA.balanceOf(alice.address)).to.eq('228')
//         })
//     })
//
//     describe("Remove Liquidity", async () => {
//         it('Bob adds some liquidity', async () => {
//             // console.log(await amm.totalShares())
//             await tokenB.mint(bob.address, 1000)
//             await tokenB.connect(bob).approve(amm.address, parseEther('10000000'))
//             // console.log(await amm.reserveA())
//             // console.log(await amm.reserveB())
//             await amm.connect(bob).addLiquidity(450, 300)
//             console.log("Reserve A:", await amm.reserveA())
//             console.log("Reserve B:", await amm.reserveB())
//         })
//
//         it("Alice withdraws liquidity by burning shares", async () => {
//             console.log(await tokenA.balanceOf(alice.address))
//             console.log(await tokenB.balanceOf(alice.address))
//             console.log("Total Shares:", await amm.totalShares())
//             await amm.connect(alice).removeLiquidity()
//             console.log(await tokenA.balanceOf(alice.address))
//             console.log(await tokenB.balanceOf(alice.address))
//         })
//     })
// })
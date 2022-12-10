const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const {address} = require("hardhat/internal/core/config/config-validation");

describe("✚ Constant Sum AMM Unit Testing ✚", async () => {
    let owner, alice, bob, carol, tokenA, tokenB, amm
    before(async () => {
        [owner, alice, bob, carol] = await ethers.getSigners()
        let A = await ethers.getContractFactory('TokenA')
        tokenA = await A.deploy()
        let B = await ethers.getContractFactory('TokenB')
        tokenB = await B.deploy()
        let csamm = await ethers.getContractFactory('AnyxSwapCS')
        amm = await csamm.deploy(tokenA.address, tokenB.address)

        await tokenA.mint(alice.address, 1000)
        await tokenB.mint(alice.address, 1000)
        await tokenA.connect(alice).approve(amm.address, parseEther('10000000'))
        await tokenB.connect(alice).approve(amm.address, parseEther('10000000'))

        await tokenA.mint(bob.address, 1000)
        await tokenB.mint(bob.address, 1000)
        await tokenA.connect(bob).approve(amm.address, parseEther('10000000'))
        await tokenB.connect(bob).approve(amm.address, parseEther('10000000'))

        await tokenA.mint(carol.address, 1000)
        await tokenB.mint(carol.address, 1000)
        await tokenA.connect(carol).approve(amm.address, parseEther('10000000'))
        await tokenB.connect(carol).approve(amm.address, parseEther('10000000'))
    })

    describe("Adding Liquidity", async () => {
        it("Alice adds 10 token A and 20 tokenB", async () => {
            await amm.connect(alice).addLiquidity(10 , 20)
            expect(await amm.s_reserveA()).to.eq('10')
            expect(await amm.s_reserveB()).to.eq('20')
        })

        it("Alice receives shares", async () => {
            expect(await amm.individualShares(alice.address)).to.eq('30')
        })

        it("Bob adds liquidity and receives correct amount of shares", async () => {
            await amm.connect(bob).addLiquidity(20 , 14)
            expect(await amm.s_reserveA()).to.eq('30')
            expect(await amm.s_reserveB()).to.eq('34')
            // (20 + 14) * 30 / 20+10 =
            expect(await amm.individualShares(bob.address)).to.eq('34')
            expect(await amm.s_totalSharesMinted()).to.eq('64')
        })

        it('Sending tokenA to the contract and checking the reserves, it should not change', async () => {
            await tokenA.connect(alice).transfer(amm.address, 10)
            expect(await amm.s_reserveA()).to.eq('30')
        })

        it('Carol adds liquidity', async () => {
            await amm.connect(carol).addLiquidity(5 , 10)
            expect(await amm.s_reserveA()).to.eq('45')
            expect(await amm.s_reserveB()).to.eq('44')
            expect(await amm.individualShares(carol.address)).to.eq('15')
            expect(await amm.s_totalSharesMinted()).to.eq('79')
        })
    })

    describe("Swapping Tokens", async () => {
        it('Alice swaps A for B', async () => {
            expect(await tokenB.balanceOf(alice.address)).to.eq('980')
            await amm.connect(alice).swapTokens(tokenA.address, 5)
            expect(await tokenB.balanceOf(alice.address)).to.eq('984') // 997*5 / 1000
        })

        it('Bob swaps B for A', async () => {
            expect(await tokenA.balanceOf(bob.address)).to.eq('980')
            await amm.connect(bob).swapTokens(tokenB.address, 25)
            expect(await tokenA.balanceOf(bob.address)).to.eq('1004') // 997*5 / 1000
        })

        it('Reserves are updated', async () => {
            expect(await amm.s_reserveA()).to.eq('26')
            expect(await amm.s_reserveB()).to.eq('65')
            expect(await amm.s_totalSharesMinted()).to.eq('79')
        })
    })

    describe("Removing Liquidity", async () => {
        it('Carol removes liquidity and her shares are burned', async () => {
            expect(await tokenA.balanceOf(carol.address)).to.eq('995')
            expect(await tokenB.balanceOf(carol.address)).to.eq('990')
            await amm.connect(carol).removeLiquidity()
            expect(await amm.individualShares(carol.address)).to.eq('0')
        })

        it('She receives correct amount of tokens', async () => {
            expect(await tokenA.balanceOf(carol.address)).to.eq('999')
            expect(await tokenB.balanceOf(carol.address)).to.eq('1002')
        })
    })
})
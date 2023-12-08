import {
  time,
  loadFixture,
  impersonateAccount,
} from '@nomicfoundation/hardhat-toolbox-viem/network-helpers'
import { expect } from 'chai'
import hre from 'hardhat'
import { getAddress, parseGwei, parseEther } from 'viem'

function sqrt(value: bigint) {
  if (value < 0n) {
    throw 'square root of negative numbers is not supported'
  }

  if (value < 2n) {
    return value
  }

  function newtonIteration(n: bigint, x0: bigint) {
    const x1 = (n / x0 + x0) >> 1n
    if (x0 === x1 || x0 === x1 - 1n) {
      return x0
    }
    return newtonIteration(n, x1)
  }

  return newtonIteration(value, 1n)
}
export function encodePriceSqrt(reserve1: bigint, reserve0: bigint): bigint {
  let fraction = (reserve1 * 2n ** 192n) / reserve0
  let sqrtRatio = sqrt(fraction)

  return sqrtRatio
}

describe('Lottery', () => {
  const deployContractFixture = async () => {
    console.log(encodePriceSqrt(parseEther('900000'), parseEther('0.1')))
    console.log(encodePriceSqrt(parseEther('0.1'), parseEther('900000')))

    const [owner, jackpot, ...otherAccounts] = await hre.viem.getWalletClients()
    const publicClient = await hre.viem.getPublicClient()

    const blotto = await hre.viem.deployContract('Milotto', undefined, {
      value: parseEther('0.1'),
    })
    const lottery = await hre.viem.deployContract('Milottery', [
      jackpot.account.address,
      blotto.address,
    ])

    return {
      blotto,
      lottery,
      owner,
      otherAccounts,
      publicClient,
    }
  }

  describe('Deployment', () => {
    it('Should deploy the contract', async () => {
      const { lottery, blotto } = await loadFixture(deployContractFixture)
      expect(await lottery.read.blottoDistributor()).to.equal(
        getAddress(blotto.address)
      )
    })

    it('Should able to contribute', async () => {
      const { lottery, owner } = await loadFixture(deployContractFixture)
      await expect(lottery.write.contributeDaily({ value: parseGwei('1') })).to
        .be.fulfilled

      expect(await lottery.read.dailyPool()).to.equal(parseGwei('1'))
      expect(await lottery.read.dailyParticipants([0n])).to.equal(
        getAddress(owner.account.address)
      )
      expect(
        await lottery.read.dailyContributors([
          getAddress(owner.account.address),
        ])
      ).to.equal(true)
    })

    it('Should able to select winner after a day', async () => {
      const { lottery, otherAccounts, publicClient } = await loadFixture(
        deployContractFixture
      )
      await expect(lottery.write.contributeDaily({ value: parseGwei('1') })).to
        .be.fulfilled
      await time.increase(60 * 60 * 24)
      await expect(lottery.write.selectDailyWinner()).to.be.fulfilled
      const selectionEvent = await lottery.getEvents.WinnerSelection()
    })
  })
})

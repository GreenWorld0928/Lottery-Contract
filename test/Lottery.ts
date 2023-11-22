import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox-viem/network-helpers'
import { expect } from 'chai'
import hre from 'hardhat'
import { getAddress, parseGwei } from 'viem'

describe('Lottery', () => {
  const deployContractFixture = async () => {
    const [owner, jackpot, ...otherAccounts] = await hre.viem.getWalletClients()

    const blotto = await hre.viem.deployContract('Blotto')
    const lottery = await hre.viem.deployContract('Lottery', [
      jackpot.account.address,
      blotto.address,
    ])
    const publicClient = await hre.viem.getPublicClient()

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

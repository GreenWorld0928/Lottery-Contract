import { formatEther, getAddress, parseEther, parseGwei } from 'viem'
import hre from 'hardhat'
import fs from 'fs'

async function main() {
  const [owner, jackpot, ...otherAccounts] = await hre.viem.getWalletClients()
  const blotto = await hre.viem.deployContract('Milotto')
  const lottery = await hre.viem.deployContract('Milottery', [
    '0xa5060F94a92e744C24161e4178349Da57abAA13e',
    blotto.address,
  ])

  let data = {
    blotto: blotto.address,
    lottery: lottery.address,
    jackpot: '0xa5060F94a92e744C24161e4178349Da57abAA13e',
  }
  fs.writeFileSync('deployed.json', JSON.stringify(data, null, 2))

  console.log(
    `Blotto: ${blotto.address}\nLottery: ${lottery.address}\nJackpot: ${jackpot.account.address}`
  )

  const balance = await blotto.read.balanceOf([owner.account.address])
  console.log(balance.toString())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})

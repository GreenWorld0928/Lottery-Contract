import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox-viem'
const { vars } = require('hardhat/config')

const MAINNET_URL = vars.get('MAINNET_URL')
const PRIVATE_KEY = vars.get('PRIVATE_KEY')

const config: HardhatUserConfig = {
  solidity: '0.8.20',
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    ethereum: {
      url: MAINNET_URL,
      accounts: [PRIVATE_KEY],
    },
  },
}

export default config

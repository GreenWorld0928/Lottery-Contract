import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox-viem'
import { vars } from 'hardhat/config'

const MAINNET_URL = vars.get('MAINNET_URL', 'https://mainnet.infura.io/v3/')
const PRIVATE_KEY = vars.get(
  'PRIVATE_KEY',
  '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
)

const config: HardhatUserConfig = {
  solidity: '0.8.20',
  networks: {
    hardhat: {
      forking: {
        url: MAINNET_URL,
        blockNumber: 18728585,
      },
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    ethereum: {
      url: MAINNET_URL,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: vars.get('ETHERSCAN_API_KEY', ''),
  },
}

export default config

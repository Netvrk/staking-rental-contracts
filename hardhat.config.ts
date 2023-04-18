import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-defender";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";

import "@openzeppelin/hardhat-upgrades";

dotenv.config();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 300,
      },
    },
  },

  networks: {
    mainnet: {
      url: process.env.MAINNET_URL || "",
      accounts:
        process.env.PRIVATE_KEY_DEPLOYER !== undefined
          ? [process.env.PRIVATE_KEY_DEPLOYER]
          : [],
      gasPrice: 70000000000,
      gasMultiplier: 1.5,
    },
    goerli: {
      url: process.env.GOERLI_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined
          ? [process.env.PRIVATE_KEY_1]
          : [],
    },
    sepolia: {
      url: process.env.SEPOLIA_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined
          ? [process.env.PRIVATE_KEY_1]
          : [],
    },
    rinkeby: {
      url: process.env.RINKEBY_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined
          ? [process.env.PRIVATE_KEY_1]
          : [],
    },
    mumbai: {
      url: process.env.MUMBAI_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined
          ? [process.env.PRIVATE_KEY_1]
          : [],
    },
    matic: {
      chainId: 137,
      url: process.env.MATIC_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined
          ? [process.env.PRIVATE_KEY_1]
          : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    // apiKey: process.env.POLYGONSCAN_API_KEY,
  },
  defender: {
    apiKey: process.env.DEFENDER_API_KEY || "",
    apiSecret: process.env.DEFENDER_API_SECRET || "",
  },
};

export default config;

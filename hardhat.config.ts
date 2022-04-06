import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 300,
      },
    },
  },
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined &&
        process.env.PRIVATE_KEY_2 !== undefined
          ? [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2]
          : [],
    },
    mumbai: {
      url: process.env.MUMBAI_URL || "",
      accounts:
        process.env.PRIVATE_KEY_1 !== undefined &&
        process.env.PRIVATE_KEY_2 !== undefined
          ? [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2]
          : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;

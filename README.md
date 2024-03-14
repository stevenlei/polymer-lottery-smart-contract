# Lottery Bridge App - Smart Contracts

This is the smart contract repository for the Lottery Bridge App, a Polymer challenged from [https://github.com/polymerdevs/Quest-Into-The-Polyverse-Phase-1/issues/13](https://github.com/polymerdevs/Quest-Into-The-Polyverse-Phase-1/issues/13).

The frontned repository can be found at [https://github.com/stevenlei/polymer-lottery-frontend](https://github.com/stevenlei/polymer-lottery-frontend).

## 📋 Prerequisites

The repo is **compatible with both Hardhat and Foundry** development environments.

- Have [git](https://git-scm.com/downloads) installed
- Have [node](https://nodejs.org) installed (v18+)
- Have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (Hardhat will be installed when running `npm install`)
- Have [just](https://just.systems/man/en/chapter_1.html) installed (recommended but not strictly necessary)

You'll need some API keys from third party's:

- [Optimism Sepolia](https://optimism-sepolia.blockscout.com/account/api-key) and [Base Sepolia](https://base-sepolia.blockscout.com/account/api-key) Blockscout Explorer API keys
- Have an [Alchemy API key](https://docs.alchemy.com/docs/alchemy-quickstart-guide) for OP and Base Sepolia

Some basic knowledge of all of these tools is also required, although the details are abstracted away for basic usage.

## 🧰 Install dependencies

To compile your contracts and start testing, make sure that you have all dependencies installed.

From the root directory run:

```bash
just install
```

to install the [vIBC core smart contracts](https://github.com/open-ibc/vibc-core-smart-contracts) as a dependency.

Additionally Hardhat will be installed as a dev dependency with some useful plugins. Check `package.json` for an exhaustive list.

> Note: In case you're experiencing issues with dependencies using the `just install` recipe, check that all prerequisites are correctly installed. If issues persist with forge, try to do the individual dependency installations...

## ⚙️ Set up your environment variables

Convert the `.env.example` file into an `.env` file. This will ignore the file for future git commits as well as expose the environment variables. Add your private keys and update the other values if you want to customize (advanced usage feature).

```bash
cp .env.example .env
```

This will enable you to sign transactions with your private key(s). If not added, the scripts from the justfile will fail.

### Obtaining testnet ETH

The account associated with your private key must have both Base Sepolia and Optimism Sepolia ETH. To obtain the testnet ETH visit:

- [Optimism Sepolia Faucet](https://www.alchemy.com/faucets/optimism-sepolia)
- [Base Sepolia Faucet](https://www.alchemy.com/faucets/base-sepolia)

## 🏃🏽🏃🏻‍♀️ Quickstart

The project comes with a LotteryUC smart contract. You can find the contracts in the `/contracts` directory as LotteryUC.sol, which is using the universal channel.

Run the following command to deploy the Lottery smart contract:

```bash
just do-it
```

## ⛓️🔗⛓️ Template for IBC enabled Solidity contracts

This project is built with the starter template from Polymer Hub, through the [vIBC core contracts](https://github.com/open-ibc/vibc-core-smart-contracts).

## Learn More

Join the [Polymer Labs Community](https://linktr.ee/polymerdao) and build together.

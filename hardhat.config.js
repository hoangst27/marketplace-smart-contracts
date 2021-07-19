require("@nomiclabs/hardhat-waffle");
const config = require("./config/config");

let tokenAddress;
let erc20Address;
let marketplaceProxyAddress;

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('deploy-token', 'Deploy ThetaArenaStandardNFT contract')
  .setAction(async () => {
    const [deployer] = await ethers.getSigners();
    const contractName = "ThetaArenaStandardNFT";
    console.log(
      `Deploying ThetaArenaStandardNFT contract with the account: ${deployer.address}`
    );

    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    const Contract = await ethers.getContractFactory(contractName);
    const token = await Contract.deploy(config.contracts.token.name, config.contracts.token.symbol, config.contracts.token.baseTokenURI);
    console.log('Contract address:', token.address);
    tokenAddress = token.address;

    console.log('Mining...');
    await token.deployed();
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  });

task('deploy-erc20', 'Deploy StandardSupportedToken contract')
  .setAction(async () => {
    const [deployer] = await ethers.getSigners();
    const contractName = "StandardSupportedToken";
    console.log(
      `Deploying StandardSupportedToken contract with the account: ${deployer.address}`
    );

    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    const Contract = await ethers.getContractFactory(contractName);
    const erc20 = config.erc20[0];
    const token = await Contract.deploy(erc20.name, erc20.symbol, erc20.cap);
    console.log('Contract address:', token.address);
    erc20Address = token.address;
    console.log('Mining...');
    await token.deployed();
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  });

task('deploy-marketplace-proxy', 'Deploy MarketplaceProxy contract')
  .setAction(async () => {
    const [deployer] = await ethers.getSigners();
    const contractName = "MarketplaceProxy";
    console.log(
      `Deploying MarketplaceProxy contract with the account: ${deployer.address}`
    );

    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    const Contract = await ethers.getContractFactory(contractName);
    const contract = await Contract.deploy(config.contracts.feeToAddress);
    console.log('Contract address:', contract.address);
    marketplaceProxyAddress = contract.address;

    console.log('Mining...');
    await contract.deployed();
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  });

task('add-proxy', 'Add proxy to ThetaArenaStandardNFT contract')
  .setAction(async () => {
    const [deployer] = await ethers.getSigners();
    const contractName = "ThetaArenaStandardNFT";
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    const Contract = await ethers.getContractFactory(contractName);
    const contract = await Contract.attach(tokenAddress);
    console.log('Contract address:', contract.address);
    console.log('Mining...');
    await contract.allowProxy(marketplaceProxyAddress);
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  });

task('add-payment-tokens', 'Add payment tokens to MarketplaceProxy contract')
  .setAction(async () => {
    const [deployer] = await ethers.getSigners();
    const contractName = "MarketplaceProxy";
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    const Contract = await ethers.getContractFactory(contractName);
    const contract = await Contract.attach(marketplaceProxyAddress);
    console.log('Contract address:', contract.address);

    console.log('Mining...');
    await contract.setPaymentTokens([erc20Address]);
    console.log(`Deployer balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  });


/**
* @type import('hardhat/config').HardhatUserConfig
*/
module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/{alchemyapi_api_key}}`,
      accounts: ['xxxxxx'],
    },
    local: {
      url: 'http://localhost:8545',
      accounts: ['xxxxxxx']
    }
  },
};

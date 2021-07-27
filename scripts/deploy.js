const hre = require("hardhat");
const config = require("../config/config");

async function main() {
  // deploy factory
  const MinterFactory = await hre.ethers.getContractFactory("MinterFactory");
  const MinterFactoryContract = await MinterFactory.deploy(
    config.marketplace.maximumMultipleMintItems
  );
  await MinterFactoryContract.deployed();
  console.log("MinterFactory deployed to:", MinterFactoryContract.address);

  // deploy erc721 token
  const GameNFT = await hre.ethers.getContractFactory("GameNFT");
  const GameNFTContract = await GameNFT.deploy(
    config.marketplace.token.name,
    config.marketplace.token.symbol,
    config.marketplace.token.baseTokenURI,
    MinterFactoryContract.address
  );

  await GameNFTContract.deployed();
  console.log("GameNFT deployed to:", GameNFTContract.address);

  // init factory
  try {
    await MinterFactoryContract.init(GameNFTContract.address);
    console.log(`Allow factory ${MinterFactoryContract.address} to mint GameNFTContract ${GameNFTContract.address}`);
  } catch (err) {
    console.log(err);
  }

  // deploy marketplace
  const Marketplace = await hre.ethers.getContractFactory("Marketplace");
  const MarketplaceContract = await Marketplace.deploy();
  await MarketplaceContract.deployed();
  console.log("Marketplace deployed to:", MarketplaceContract.address);

  // init marketplace
  try {
    await MarketplaceContract.init(
      config.marketplace.feeToAddress,
      config.marketplace.paymentTokens
    );
    console.log(`Set feeToAddress to ${config.marketplace.feeToAddress} and supported payment tokens ${JSON.stringify(config.marketplace.paymentTokens)}`);
  } catch (err) {
    console.log(err);
  }

  // add marketplace to whitelist
  try {
    await GameNFTContract.addApprovalWhitelist(MarketplaceContract.address);
    console.log(`Allow operation ${MarketplaceContract.address} to reduce gas fee`);
  } catch (err) {
    console.log(err);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

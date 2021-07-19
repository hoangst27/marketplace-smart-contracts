const hre = require("hardhat");
async function main() {
  const ThetaArenaStandardNFT = await hre.ethers.getContractFactory("ThetaArenaStandardNFT");
  const deployContract = await ThetaArenaStandardNFT.deploy("Hello, Hardhat!");
  await deployContract.deployed();
  console.log("ThetaArenaStandardNFT deployed to:", deployContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const marketplace = {
  token: {
    name: "Theta Arena NFT",
    symbol: "THETA",
    baseTokenURI: "https://api.theta.io/meta-data/",
  },
  feeToAddress: "0x8F8C7E459E37DA5Ad3CC56847eAb73A94E1d7ea5",
  paymentTokens: [],
  maximumMultipleMintItems: 5,
};

const erc20 = [
  {
    name: "THETA USD",
    symbol: "THETA",
    cap: "1000000000000000000000000000",
    decimals: 18,
  },
];
var config = {
  marketplace,
  erc20,
};

module.exports = config;

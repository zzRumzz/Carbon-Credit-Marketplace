require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");

const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  //get the signer that we will use to deploy
  const [deployer] = await ethers.getSigners();

  const MyToken = await ethers.getContractFactory("CarbonToken");
  const initialSupply = ethers.parseUnits("100000000", 18);
  const mytoken = await MyToken.deploy(initialSupply);
  await mytoken.waitForDeployment();
  console.log("myToken deploy to: ", mytoken.target);
  console.log("Initial supply:", initialSupply.toString());
  //Get the NFTMarketplace smart contract object and deploy it
  const Marketplace = await ethers.getContractFactory("NFTMarketplace");
  const marketplace = await Marketplace.deploy(mytoken.target);

  await marketplace.waitForDeployment();
  console.log("MyToken NFT to:", marketplace.target);
  //Pull the address and ABI out while you deploy, since that will be key in interacting with the smart contract later
  const data = {
    address: marketplace.target,
    abi: marketplace.interface.format('json')
  }
  fs.writeFileSync('./nft-marketplace/src/Marketplace.json', JSON.stringify(data, null, 2))
  const Tokendata = {
    address: mytoken.target,
    abi: mytoken.interface.format('json')
  }
  fs.writeFileSync('./nft-marketplace/src/myToken.json', JSON.stringify(Tokendata, null, 2))
  //This writes the ABI and address to the marketplace.json
  //This data is then used by frontend files to connect with the smart contract
 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
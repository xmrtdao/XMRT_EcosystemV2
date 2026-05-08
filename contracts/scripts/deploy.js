// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy XMRT Governance Token
  const XMRTToken = await ethers.getContractFactory("XMRTToken");
  const token = await XMRTToken.deploy(
    deployer.address, deployer.address, deployer.address, deployer.address, deployer.address
  );
  await token.deployed();
  console.log("XMRT Token deployed to:", token.address);

  // Deploy Governor (OpenZeppelin)
  const Governor = await ethers.getContractFactory("Governor");
  const governor = await Governor.deploy(token.address, deployer.address);
  await governor.deployed();
  console.log("Governor deployed to:", governor.address);

  // Update governor address on token
  await token.setGovernor(governor.address);
  console.log("Governor linked to token");

  // Save deployment addresses
  const fs = require("fs");
  const deployment = {
    network: hre.network.name,
    token: token.address,
    governor: governor.address,
    deployer: deployer.address,
    timestamp: new Date().toISOString()
  };
  fs.writeFileSync(`deployment-${hre.network.name}.json`, JSON.stringify(deployment, null, 2));
  console.log("Deployment saved to deployment-" + hre.network.name + ".json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => { console.error(error); process.exit(1); });

const { ethers } = require("hardhat");
async function main() {

    // 1. deploy DriftBottleToken contract
    const driftBottleToken = await ethers.deployContract('DriftBottleToken');
    await driftBottleToken.waitForDeployment();
    const driftBottleTokenAddr = await driftBottleToken.getAddress();
    console.log(`DriftBottleToken deployed to : ${driftBottleTokenAddr}`);


    // 2. deploy DriftBottle contract
    const driftBottle = await ethers.deployContract('DriftBottle', [
        driftBottleAddr,
        '10000000000000000000',
    ]);
    await driftBottle.waitForDeployment()
    const driftBottleAddr = await driftBottle.getAddress()
    console.log(`DriftBottle deployed to : ${driftBottleAddr}`);

    // 3. 
    await driftBottleToken.grantMinterRole(driftBottleAddr)
    console.log(`Minter role granted.`);


    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    await sleep(30000);
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    const hasMinterRole1 = await driftBottleToken.hasRole(MINTER_ROLE, driftBottleTokenAddr);
    const hasMinterRole2 = await driftBottleToken.hasRole(MINTER_ROLE, driftBottleAddr);
    console.log(`DriftBottleToken has Minter role: ${hasMinterRole1}`);
    console.log(`DriftBottleToken has Minter role: ${hasMinterRole2}`);
}


main().then(() => process.exit(0)).catch(err => {
    console.error(err);
    process.exit(1);
});
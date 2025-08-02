const hre = require("hardhat");

async function main() {
    const projectFactory = await hre.ethers.deployContract("ProjectFactory");

    await projectFactory.waitForDeployment();

    console.log(`ProjectFactory deployed to: ${projectFactory.target}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
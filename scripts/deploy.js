const hre = require("hardhat");
const fs = require("fs/promises");

async function main() {
  const BankAccount = await hre.ethers.getContractFactory("BankAccount"); //grab contract
  const bankAccount = await BankAccount.deploy(); //create instance of contract in bankAccount

  await bankAccount.deployed(); //make sure it gets deployed w/ no errors
  await writeDeploymentInfo(bankAccount); //now set up the data/info
}

async function writeDeploymentInfo(contract) {
  const data = {
    contract: {
      address: contract.address,
      signerAddress: contract.signer.address,
      abi: contract.interface.format(),
    },
  };

  const content = JSON.stringify(data, null, 2); //create into a string

  // this code writes some content to a file named deployment.json using the fs module,
  // and waits for the write operation to complete before proceeding with the rest of the program.
  // basically creates deployment.json file
  await fs.writeFile("deployment.json", content, { encoding: "utf-8" });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

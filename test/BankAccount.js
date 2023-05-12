const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("BankAccount", function () {
  async function deployBankAccount() {
    const [addr0, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    const BankAccount = await ethers.getContractFactory("BankAccount");
    const bankAccount = await BankAccount.deploy();

    return { bankAccount, addr0, addr1, addr2, addr3, addr4 };
  }

  describe("Deployment", () => {
    it("Should deploy without error", async () => {
      await loadFixture(deployBankAccount);
    })
  });

  describe("Creating an account", () => {
    it("Should allow creating a single user account", async () => {
        const { bankAccount, addr0 } = await loadFixture(deployBankAccount);
        await bankAccount.connect(addr0).createAccount([]);
        const accounts = await bankAccount.connect(addr0).getAccounts();
        expect(accounts.length).to.equal(1);
    });
  });
});

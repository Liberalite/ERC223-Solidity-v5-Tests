const etherlime = require('etherlime');
const ethers = require('ethers');
ethers.errors.setLogLevel("error");

const ERC223Token = require('../build/ERC223Token.json');
const ERC223Crowdsale = require('../build/ERC223Crowdsale.json');

// console.log(assert)

const expectThrow = async promise => {
    try {
        let result = await promise;
        console.log(result);
    } catch (error) {
        const invalidJump = error.message.search('invalid JUMP') >= 0
        const invalidOpcode = error.message.search('invalid opcode') >= 0
        const outOfGas = error.message.search('out of gas') >= 0
        const revert = error.message.search('revert') >= 0
        assert(invalidJump || invalidOpcode || outOfGas || revert, "Expected throw, got '" + error + "' instead")
        return
    }
    assert.fail('Expected throw not received')
}

describe('ERC223 Token Deployment + ERC223 Crowdsale ICO', () => {
    let provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    let tokenInstance;
    let icoInstance;

    let walletOwner = new ethers.Wallet(accounts[0].signer.privateKey, provider);
    let walletEther = new ethers.Wallet(accounts[1].signer.privateKey, provider);
    let walletTreasury = new ethers.Wallet(accounts[2].signer.privateKey, provider);
    let walletTeam = new ethers.Wallet(accounts[3].signer.privateKey, provider);
    let walletAdvisors = new ethers.Wallet(accounts[4].signer.privateKey, provider);
    let walletBounty = new ethers.Wallet(accounts[5].signer.privateKey, provider);
    let walletPlayer1 = new ethers.Wallet(accounts[6].signer.privateKey, provider);
    let walletPlayer2 = new ethers.Wallet(accounts[7].signer.privateKey, provider);
    let walletPlayer3 = new ethers.Wallet(accounts[8].signer.privateKey, provider);
    let walletPlayer4 = new ethers.Wallet(accounts[9].signer.privateKey, provider);

    // CONSTANT VARIABLES
    let _name = "ERC223";
    let _symbol = "ERC223";
    let _decimals = 18;
    let _totalSupply = '10000000000000000000000000'; // 10 Million ERC223 Tokens in Wei

    before(async () => {
        let tokenFactory = new ethers.ContractFactory(ERC223Token.abi, ERC223Token.bytecode, walletOwner);
        let icoFactory = new ethers.ContractFactory(ERC223Crowdsale.abi, ERC223Crowdsale.bytecode, walletOwner);
        tokenInstance = await tokenFactory.deploy();
        await tokenInstance.deployed()
        icoInstance = await icoFactory.deploy(tokenInstance.address, walletEther.address);
        await icoInstance.deployed()
    });

    it('should be valid addresses', async () => {
        assert.isAddress(tokenInstance.address, "The contract was not deployed");
        assert.isAddress(icoInstance.address, "The contract was not deployed");
    })

    it('should have correct constant variables', async () => {
        const name = await tokenInstance["name()"]();
        const symbol = await tokenInstance["symbol()"]();
        const decimals = await tokenInstance["decimals()"]();
        const totalSupply = await tokenInstance["totalSupply()"]();
        expect(_name).to.eq(name)
        expect(_symbol).to.eq(symbol)
        expect(_decimals).to.eq(decimals)
        expect(_totalSupply).to.eq(totalSupply.toString())
    })

    it("should receive on token instantiation 10.000.000 tokens", async () => {
        const ownerBalance = await tokenInstance["balanceOf(address)"](walletOwner.address);
        const totalSupply = await tokenInstance["totalSupply()"]();
        expect(ownerBalance.toString()).to.eq(totalSupply.toString());
    });

    it("should check that ico initial balance is 0", async () => {
        const initialIcoBalance = await icoInstance.checkBalance();
        expect(initialIcoBalance.toString()).to.eq("0");
    });

    it("should transfer tokens to Wallet Address using 2 parameters", async () => {
        // GET PLAYER INITIAL BALANCE
        const initialBalance = await tokenInstance["balanceOf(address)"](walletPlayer1.address);
        expect(initialBalance.toString()).to.eq("0");

        // SEND 100K TOKENS TO PLAYER ADDRESS
        const txToAddress = await tokenInstance.transfer(walletPlayer1.address, "100000000000000000000000")
        // SOMETIMES ON DEPLOYMENT ETHERS.JS GETS THE FIRST TRANSFER FUNCTION WITH 2 PARAMETERS AND SOMETIMES THE TRANSFER FUNCTION THAT NEEDS 3 PARAMETERS FROM THE ABI

        // CHECK PLAYER UPDATED BALANCE
        const updatedBalance = await tokenInstance["balanceOf(address)"](walletPlayer1.address);
        expect(updatedBalance.toString()).to.eq("100000000000000000000000"); // 100K Tokens
    });

    it("should transfer tokens to ICO Contract using 2 parameters", async () => {
        // GET INITIAL BALANCE
        const initialBalance = await tokenInstance["balanceOf(address)"](icoInstance.address);
        expect(initialBalance.toString()).to.eq("0");

        // SEND 100K TOKENS TO CONTRACT ADDRESS
        const txToContract = await tokenInstance.transfer(icoInstance.address, "5000000000000000000000000")

        // CHECK UPDATED BALANCE
        const updatedIcoBalance = await tokenInstance["balanceOf(address)"](icoInstance.address);
        expect(updatedIcoBalance.toString()).to.eq("5000000000000000000000000"); // 5M Tokens
    });

    it("should have ETH Balance greater than 10 ETH", async () => {
        let balance = await provider.getBalance(walletPlayer2.address);
        let wei = ethers.utils.bigNumberify(balance);
        let toEth = ethers.utils.formatEther(wei)
        assert.ok(toEth > "10", "Sender must have more than 10 ETH")
    });

    it("should contribute 10 ETH", async () => {
        let tx = await walletPlayer2.sendTransaction({
            to: icoInstance.address,
            value: ethers.utils.parseEther('10'),
        });
        // console.log('Sent in Transaction: ' + tx.hash);
    });

    it("should receive 15000 Tokens", async () => {
        const updatedPlayerBalance = await tokenInstance["balanceOf(address)"](walletPlayer2.address);
        expect(updatedPlayerBalance.toString()).to.eq('15000000000000000000000'); // 15K Tokens
        // THIS WORKS ONLY BECAUSE WE SWITCHED TO THE OLD WAY THAT ONLY REQUIRES THE TOKEN AND DOES NOT CHECK FOR MSG.SIG
    });

    it("should see that 15000 Tokens have been sent by the ICO Contract", async () => {
        const updatedIcoBalance = await icoInstance.checkBalance();
        expect(updatedIcoBalance.toString()).to.eq("4985000000000000000000000"); // 5 Million Tokens - 15.000 Tokens
    });

    // it("should identify both transfer functions", async () => {
    //     // const txToContract = await tokenInstance.transfer(icoInstance.address, "1000000000000000000000000", "0x")
    //     console.log(await tokenInstance.functions)
    //     console.log(await tokenInstance.functions["transfer"][0])
    //     console.log(await tokenInstance.functions["transfer"][1])
    //     const transfer1 = await tokenInstance["transfer[0]"](icoInstance.address, "1000000000000000000000000", "0x");
    //     const transfer2 = await tokenInstance["transfer[1]"](icoInstance.address, "1000000000000000000000000", "0x");
    //     console.log(transfer1)
    //     console.log(transfer2)
    // });

});
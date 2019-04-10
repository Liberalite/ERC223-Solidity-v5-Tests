const etherlime = require('etherlime');
const ethers = require('ethers');
ethers.errors.setLogLevel("error");

const ERC223Token = require('../build/ERC223Token.json');
const ERC223Crowdsale = require('../build/ERC223Crowdsale.json');

const deploy = async (network, secret) => {
	const deployer = new etherlime.EtherlimeGanacheDeployer();
	const deployedToken = await deployer.deploy(ERC223Token);
	const deployedIco = await deployer.deploy(ERC223Crowdsale, false, deployedToken.contractAddress, "0xd4fa489eacc52ba59438993f37be9fcc20090e39");
};

module.exports = {
	deploy
};
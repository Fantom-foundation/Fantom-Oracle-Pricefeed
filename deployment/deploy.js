// Fantom Voting smart contract deployment script
const fs = require('fs');
const net = require("net");
const Web3 = require("web3");
const moment = require("moment");

// parse the arguments
const fileArgs = process.argv.slice(2);
if (fileArgs.length < 1) {
    console.log("\nPlease provide source address unlock password.\n");
    return 1;
}

// setups
const ipcPath = "/home/jirim/lachesis/data/lachesis.ipc";
const srcAddress = "0x3a7952c135e7b40942e57ea01396b71bf9eb5b90";
const unlockPassword = fileArgs.shift();
const gasLimit = 4000000;
const byteCodeFilePath = "../build/PriceOracle.bin";
const abiFilePath = "../build/PriceOracle.abi";

// init the web3 provider and configure local client connection
const client = new Web3(new Web3.providers.IpcProvider(ipcPath, net));

/**
 * Deploy precompiled contract with parameters specified.
 *
 * @param {Web3} client
 * @param {string} abiFile
 * @param {string} byteCodeFile
 * @param {number} expirationPeriod
 * @param {[string]} feeds
 * @returns {Promise<{}>}
 */
async function deploy(
    client,
    abiFile,
    byteCodeFile,
    expirationPeriod,
    feeds
) {
    let abi, byteCode;

    // read needed files
    try {
        // try to rad the ABI and binary data of the compiled contract
        abi = JSON.parse(fs.readFileSync(abiFile, "utf8"));
        byteCode = fs.readFileSync(byteCodeFile, "ascii");
    } catch (e) {
        console.log("Error reading contract data.", e.toString());
        return e;
    }

    // unlock the sending account
    await client.eth.personal.unlockAccount(srcAddress, unlockPassword, 120);

    // prep the contract
    const contract = new client.eth.Contract(abi);
    return contract.deploy({
        data: byteCode,
        arguments: [
            client.utils.numberToHex(expirationPeriod),
            feeds
        ]
    }).send({
        from: srcAddress,
        gas: client.utils.toHex(gasLimit),
    });
}

// deploy the contract as needed
deploy(
    client,
    abiFilePath,
    byteCodeFilePath,
    1800,
    [srcAddress]
).then((res) => {
    // log the success
    console.log(res, "\nDeployed.\n");
    return 0;
}).catch(err => {
    // log the error
    console.log("\nError happened.\n", err, "\n");
    return 1;
});

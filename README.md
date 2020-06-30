# Fantom Oracle Price Feed Contract

The repository contains Solidity smart contract implementing simplified price feeds
oracle for Fantom Opera network.

A deployed smart contract offers price exachange pair values indexed and identified 
by exchange symbols. The actual price is fed into the contract from an external 
off-chain data source. The backend service implementing this function is available
on the foundation GitHub
as the [Fantom Oracle Backend](https://github.com/Fantom-foundation/Fantom-Oracle-Backend).

## Contract compilation

1. Install appropriate [Solidity](https://solidity.readthedocs.io) compiler. 
    The contract expects Solidity version to be from the branch 0.5.0. The latest available Solidity 
    compiler of this branch is the [Solidity Version 0.5.17](https://github.com/ethereum/solidity/releases/tag/v0.5.17).
2. Compile the contract for deployment.
    
    `solc -o ./build --optimize --optimize-runs=200 --abi --bin ./contract/PriceOracle.sol`
    
3. Deploy compiled binary file `./build/FantomBallot.bin` into the blockchain.

4. Use generated ABI file `./build/FantomBallot.abi` to interact with the contract.

A simple deployment script supported by Web3 library is available in the [deployment](deployment)
folder. Use NPM to install dependecies using `npm install` and node.js to run the deployment script.
Please make sure to set internal variables to your liking.

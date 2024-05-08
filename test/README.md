# Testing in Foundry CLI

forge test --fork-url $SEPOLIA_RPC_URL
forge coverage --fork-url $SEPOLIA_RPC_URL
    // will output "how much of our code" was actually tested. 

gasleft() is a solidity built in function that returns gas spent so far
tx.gasprice() is another solidity built in function that returns gas price

evm.codes to keep track of opcode gas expenditure
forge snapchot

-m is deprecated in favor of --mt
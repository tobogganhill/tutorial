pragma solidity ^0.5.0;

import '../contracts/Ilighthouse.sol';


contract Gamble {
	ILighthouse public myLighthouse;

	address[20] public accounts; // Array of users registered
	uint256 public numAccounts = 0; // Should be <= 19, this holds number of registered users

	mapping(address => uint256) public balances; // Stores users deposited ether in a wallet
	mapping(address => uint256) public toBet; // Holds ether users have decided to gamble on an upcoming dice roll
	mapping(address => uint256) public chosenNumber; // Holds the users chosen number to bet on in an upcoming dice roll

	constructor(ILighthouse _myLighthouse) public {
		myLighthouse = _myLighthouse;
	}

	// Pass in sender address manually because truffle proxy contracts interfere with msg.sender
	function deposit(address msgSender) external payable {
		bool exists = false;
		for (uint256 i = 0; i < numAccounts; i++) {
			if (accounts[i] == msgSender) {
				exists = true;
				break;
			}
		}

		if (exists == false) {
			accounts[numAccounts] = msgSender;
			numAccounts++;
		}

		balances[msgSender] += msg.value;
	}

	// Allows users to withdraw all their ether
	function withdraw(address payable msgSender) public {
		uint256 amount = balances[msgSender];
		balances[msgSender] = 0;

		bool ok = false;
		bytes memory mem;
		(ok, mem) = msgSender.call.value(amount).gas(20000)(''); // fallback function logs withdraw in a storage write, requires 20000 gas
		require(ok = true, 'Transfer failed');
	}

	// Functions to display the internal state
	function checkAccountLength() public view returns (uint256) {
		return accounts.length;
	}

	function checkNumAccounts() public view returns (uint256) {
		return numAccounts;
	}

	function checkAccounts(uint256 index) public view returns (address) {
		require(index < 20, 'No more than 20 accounts can be registered at a time');
		return accounts[index];
	}

	function checkBalance(address msgSender) public view returns (uint256) {
		return balances[msgSender];
	}

	function checkBet(address msgSender) public view returns (uint256) {
		return toBet[msgSender];
	}

	function checkNumber(address msgSender) public view returns (uint256) {
		return chosenNumber[msgSender];
	}

	// User places a bet on a number they think will win the dice roll
	function gamble(address msgSender, uint256 money, uint256 number) public {
		balances[msgSender] -= money;
		toBet[msgSender] += money;
		chosenNumber[msgSender] = number;
	}

	// Rolls the dice for all players who bet on this round, giving a 6x return if they win
	function diceRoll() public {
		uint256 winningNumber;
		bool ok;
		(winningNumber, ok) = myLighthouse.peekData(); // obtain random number from Rhombus Lighthouse

		for (uint256 i = 0; i < numAccounts; i++) {
			if (
				toBet[accounts[i]] != 0 && chosenNumber[accounts[i]] == winningNumber
			) {
				balances[accounts[i]] += toBet[accounts[i]] * 6;
			}
			toBet[accounts[i]] = 0;
		}
	}
}

pragma solidity 0.4.17;

contract BettingContract {
	/* Standard state variables */
	address owner;

	address public gamblerA;
	address public gamblerB;
	address public oracle;

	uint    private start_time;
	uint[]  private outcomes;

	bool    public is_decided;
	bool    public is_declard;

	uint80 constant None = uint80(0);

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet)  bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetOpened(address ownr,   uint[] out);
	event BetAble  (address gambler);
	event BetMade  (address gambler, uint amount);
	event BetClosed(uint totalpool,  uint outcome1, uint outcome2);

	event OracleFound  (address oracl);
	event OutcomePicked(uint    outcome);


	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
	    if (msg.sender == owner)
	        _;
	}

	modifier OracleOnly() {
	    if (msg.sender == oracle)
	        _;
	}

	modifier ContractLiveOnly() {
	    if (is_declard)
	        _;
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
	    if (is_declard) {
	        revert();
	    } else {

	        is_declard = true;
	        start_time = now;

	        owner      = tx.origin;
	        outcomes   = _outcomes;

	        BetOpened(owner, outcomes);
	    }
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
        if ((_oracle == gamblerA) || (_oracle == gamblerB)) {
            revert();
        } else {
            oracle = _oracle;
            return oracle;
        }
	}

	/* Participant calls gamble to become a Gambler */
	function gamble() ContractLiveOnly() {
	    if ((gamblerA != None) && (gamblerB != None)) {
	        revert();
	    } else {
	        address sender = msg.sender;
	        if ((sender == owner) || (sender == oracle)) {
	            revert();
	        } else if (gamblerA == None) {
	            gamblerA = sender;
	            BetAble(gamblerA);
	        } else if (gamblerB == None) {
	            gamblerB = sender;
	            BetAble(gamblerB);
	        } else {
	            revert();
	        }
	    }
	}


	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable ContractLiveOnly() returns (bool) {
	    address sender = msg.sender;
	    if ((sender != gamblerA) && (sender != gamblerB)) {
	        revert();
	    } else {
	        if (bets[sender].initialized) {
	            revert();
	        } else {
	            bets[sender] = Bet({
					outcome 	: _outcome,
					amount  	: msg.value,
					initialized : true
				});

	            BetMade(sender, msg.value);
				return true;
	        }

	    }
		return false;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
	    if (is_decided) {
	        revert();

	    } else if (!(bets[gamblerA].initialized) && !(bets[gamblerB].initialized)) {
	        revert();

	    } else {

	        is_decided = true;

	        if (bets[gamblerA].outcome == bets[gamblerB].outcome) {
	            winnings[gamblerA] += bets[gamblerA].amount;
	            winnings[gamblerB] += bets[gamblerB].amount;

	        } else {
	            uint totalPool = bets[gamblerA].amount + bets[gamblerB].amount;
	            if ((bets[gamblerA].outcome != _outcome) && (bets[gamblerB].outcome != _outcome)) {
    	            winnings[oracle]   += totalPool;

	            } else if (bets[gamblerA].outcome == _outcome) {
	                winnings[gamblerA] += totalPool;

	            } else {
	                winnings[gamblerB] += totalPool;
	            }
	        }

	        bets[gamblerA].amount = 0;
	        bets[gamblerB].amount = 0;
	    }
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
	    address sender = msg.sender;
	    if (winnings[sender] == None) {
	       revert();
	    } else {
	        uint currentBal = winnings[sender];
	        if (withdrawAmount >= currentBal) {
	            winnings[sender] = 0;
	            if (!(sender.send(currentBal))) {
					winnings[sender] += currentBal;
				}
	        } else {
	            winnings[sender] -= withdrawAmount;
				if (!(sender.send(withdrawAmount))) {
					winnings[sender] += withdrawAmount;
				}
	        }
			return winnings[sender];
	    }
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
	    if (outcomes.length == 0) {
	        revert();
	    } else {
	        return outcomes;
	    }
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
	    if (winnings[msg.sender] == None) {
	        revert();
	    } else {
	        return winnings[msg.sender];
	    }
	}

	/* Refunds Gamblers and resets contract if Oracle has not made decision */
	function contractRefund() ContractLiveOnly() {
	    if ((now < start_time + 20 minutes) && !(is_decided)) {
	        revert();
	    } else {
	        uint tempA = bets[gamblerA].amount;
	        uint tempB = bets[gamblerB].amount;

	        bets[gamblerA].amount = 0;
	        bets[gamblerB].amount = 0;

	        winnings[gamblerA] += tempA;
	        winnings[gamblerB] += tempB;

	        contractReset();
	    }
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
	    delete(bets[gamblerA]);
	    delete(bets[gamblerB]);

	    delete(is_decided);
	    delete(is_declard);

	    delete(gamblerA);
	    delete(gamblerB);
	    delete(oracle);
	}

	/* Fallback function */
	function() {
		revert();
	}
}

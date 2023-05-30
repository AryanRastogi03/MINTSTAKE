// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyStakingToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount, uint256 startTime, uint256 duration, uint256 rewards);
    event Unstaked(address indexed user, uint256 amount, uint256 endTime);
    event RewardsClaimed(address indexed user, uint256 rewards);

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 rewards;
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public rewardsBalance;

    uint256 private constant INITIAL_SUPPLY = 1000000 * (10**18);

    constructor() {
        name = "My Staking Token";
        symbol = "MST";
        decimals = 18;
        totalSupply = INITIAL_SUPPLY;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        _transfer(from, to, value);

        allowance[from][msg.sender] -= value;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        return true;
    }

    function stake(uint256 amount, uint256 duration) external {
        require(amount > 0, "Invalid amount");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        // Transfer tokens to the contract
        _transfer(msg.sender, address(this), amount);

        // Calculate rewards
        uint256 rewards = calculateRewards(amount, duration);

        // Update rewards balance for the staker
        rewardsBalance[msg.sender] += rewards;

        // Create a new stake
        stakes[msg.sender].push(Stake(amount, block.timestamp, block.timestamp + duration, rewards));
        emit Staked(msg.sender, amount, block.timestamp, duration, rewards);
    }

    function unstake(uint256 index) external {
        require(index < stakes[msg.sender].length, "Invalid stake index");

        Stake memory stakeToUnstake = stakes[msg.sender][index];

        require(block.timestamp >= stakeToUnstake.endTime, "Staking duration not completed");

        uint256 unstakeAmount = stakeToUnstake.amount;

        // Remove the stake from the array
        if (index < stakes[msg.sender].length - 1) {
            stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length - 1];
        }
        stakes[msg.sender].pop();

        // Transfer the staked tokens back to the user
        _transfer(address(this), msg.sender, unstakeAmount);

        emit Unstaked(msg.sender, unstakeAmount, block.timestamp);
    }

    function claimRewards() external {
        uint256 rewards = rewardsBalance[msg.sender];

        require(rewards > 0, "No rewards to claim");

        // Transfer rewards to the staker
        _transfer(address(this), msg.sender, rewards);

        // Reset rewards balance for the staker
        rewardsBalance[msg.sender] = 0;

        emit RewardsClaimed(msg.sender, rewards);
    }

    function getStakeCount(address staker) external view returns (uint256) {
        return stakes[staker].length;
    }

    function calculateRewards(uint256 amount, uint256 duration) internal pure returns (uint256) {
        // Add your own logic to calculate the reward based on the staked amount and duration
        // This is just a placeholder implementation
        return amount * duration / 100;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Invalid recipient");

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
    }
}

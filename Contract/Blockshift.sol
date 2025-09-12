// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Blockshift - Decentralized Task Management & Reward System
 * @dev A smart contract for managing tasks, tracking completion, and distributing rewards
 * @author Blockshift Team
 */
contract Blockshift {
    
    // Task structure to store task details
    struct Task {
        uint256 id;
        string title;
        string description;
        address creator;
        address assignee;
        uint256 reward;
        bool isCompleted;
        bool isActive;
        uint256 createdAt;
        uint256 deadline;
    }
    
    // State variables
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks;
    mapping(address => uint256) public userRewards;
    
    uint256 private taskCounter;
    uint256 public totalRewardsDistributed;
    
    // Events
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee, uint256 reward);
    event RewardClaimed(address indexed user, uint256 amount);
    
    // Modifiers
    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCounter, "Task does not exist");
        _;
    }
    
    modifier onlyTaskCreator(uint256 _taskId) {
        require(msg.sender == tasks[_taskId].creator, "Only task creator can perform this action");
        _;
    }
    
    modifier onlyAssignee(uint256 _taskId) {
        require(msg.sender == tasks[_taskId].assignee, "Only assigned user can complete this task");
        _;
    }
    
    /**
     * @dev Core Function 1: Create a new task with reward
     * @param _title Task title
     * @param _description Task description  
     * @param _deadline Task deadline timestamp
     */
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _deadline
    ) external payable {
        require(bytes(_title).length > 0, "Task title cannot be empty");
        require(msg.value > 0, "Task must have a reward");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        
        taskCounter++;
        
        tasks[taskCounter] = Task({
            id: taskCounter,
            title: _title,
            description: _description,
            creator: msg.sender,
            assignee: address(0),
            reward: msg.value,
            isCompleted: false,
            isActive: true,
            createdAt: block.timestamp,
            deadline: _deadline
        });
        
        userTasks[msg.sender].push(taskCounter);
        
        emit TaskCreated(taskCounter, msg.sender, _title, msg.value);
    }
    
    /**
     * @dev Core Function 2: Assign task to a user and complete it
     * @param _taskId Task ID to complete
     * @param _assignee Address of the user completing the task
     */
    function assignAndCompleteTask(uint256 _taskId, address _assignee) 
        external 
        taskExists(_taskId) 
        onlyTaskCreator(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(task.isActive, "Task is not active");
        require(!task.isCompleted, "Task already completed");
        require(_assignee != address(0), "Invalid assignee address");
        require(block.timestamp <= task.deadline, "Task deadline has passed");
        
        // Assign and complete the task
        task.assignee = _assignee;
        task.isCompleted = true;
        task.isActive = false;
        
        // Add reward to assignee's balance
        userRewards[_assignee] += task.reward;
        totalRewardsDistributed += task.reward;
        
        // Add to assignee's task list
        userTasks[_assignee].push(_taskId);
        
        emit TaskAssigned(_taskId, _assignee);
        emit TaskCompleted(_taskId, _assignee, task.reward);
    }
    
    /**
     * @dev Core Function 3: Claim accumulated rewards
     */
    function claimRewards() external {
        uint256 rewardAmount = userRewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim");
        require(address(this).balance >= rewardAmount, "Insufficient contract balance");
        
        // Reset user rewards before transfer (prevent reentrancy)
        userRewards[msg.sender] = 0;
        
        // Transfer rewards to user
        payable(msg.sender).transfer(rewardAmount);
        
        emit RewardClaimed(msg.sender, rewardAmount);
    }
    
    // View functions
    function getTask(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }
    
    function getUserTasks(address _user) external view returns (uint256[] memory) {
        return userTasks[_user];
    }
    
    function getUserRewardBalance(address _user) external view returns (uint256) {
        return userRewards[_user];
    }
    
    function getTotalTasks() external view returns (uint256) {
        return taskCounter;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Emergency function for contract owner (optional)
    function emergencyWithdraw() external {
        // In a production environment, you might want to add owner restrictions
        require(msg.sender == address(this), "Unauthorized");
        payable(msg.sender).transfer(address(this).balance);
    }
}

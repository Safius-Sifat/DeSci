// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol"; // Useful for debugging

contract ProjectFactory {
    // A struct to hold all the information about a single research project.
    struct Project {
        address payable owner; // The researcher's wallet address
        string title;          // Title of the research
        string description;    // A short description
        uint256 fundingGoal;   // The amount of ETH they need to raise
        uint256 raisedAmount;  // The amount of ETH raised so far
        uint256 deadline;      // Timestamp after which funding is closed
        bool active;           // Is the project currently active
    }

    // An array to store all projects created.
    Project[] public projects;

    // An event that is emitted when a new project is created.
    // The frontend can listen for this event to update the UI.
    event ProjectCreated(
        uint256 projectId,
        address owner,
        string title,
        uint256 fundingGoal,
        uint256 deadline
    );

    // An event for when a project is funded.
    event ProjectFunded(uint256 projectId, address funder, uint256 amount);

    /**
     * @dev Creates a new research project.
     * @param _title The title for the new project.
     * @param _description A description of the project.
     * @param _fundingGoal The funding goal in wei (1 ETH = 1e18 wei).
     * @param _durationInDays The duration for the funding campaign in days.
     */
    function createProject(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        uint256 _durationInDays
    ) public {
        require(_fundingGoal > 0, "Funding goal must be greater than 0");

        Project memory newProject = Project({
            owner: payable(msg.sender), // The creator is the owner
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            raisedAmount: 0,
            deadline: block.timestamp + (_durationInDays * 1 days),
            active: true
        });

        projects.push(newProject);
        uint256 projectId = projects.length - 1;

        emit ProjectCreated(projectId, msg.sender, _title, _fundingGoal, newProject.deadline);
    }

    /**
     * @dev Allows users to fund a specific project.
     * This function must be `payable` to receive ETH.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) public payable {
        require(_projectId < projects.length, "Project does not exist");
        Project storage project = projects[_projectId];

        require(project.active, "Project is not active");
        require(block.timestamp < project.deadline, "Funding deadline has passed");
        require(msg.value > 0, "Must send some ETH");

        project.raisedAmount += msg.value;

        // Check if goal is met and deactivate funding
        if (project.raisedAmount >= project.fundingGoal) {
            project.active = false;
        }

        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the project owner to withdraw the raised funds.
     * PROTOTYPE ONLY: In a real system, this would be tied to milestone verification.
     * @param _projectId The ID of the project to withdraw funds from.
     */
    function withdrawFunds(uint256 _projectId) public {
        require(_projectId < projects.length, "Project does not exist");
        Project storage project = projects[_projectId];

        require(msg.sender == project.owner, "Only the owner can withdraw");
        require(project.raisedAmount > 0, "No funds to withdraw");

        // Transfer the contract's balance for this project to the owner
        // For simplicity, we just transfer what's raised. A real contract
        // would need more robust fund management.
        (bool success, ) = project.owner.call{value: project.raisedAmount}("");
        require(success, "Transfer failed.");

        // After withdrawal, we can mark the funds as 0 to prevent re-withdrawal
        project.raisedAmount = 0;
    }

    /**
     * @dev A helper function to get the number of projects.
     * The frontend will use this to loop through and display all projects.
     */
    function getProjectsCount() public view returns (uint256) {
        return projects.length;
    }
}
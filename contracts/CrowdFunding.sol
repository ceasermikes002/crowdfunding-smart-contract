// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    // Struct to hold campaign details
    struct Campaign {
        string title;            // Title of the campaign
        string description;      // Description of the campaign
        address payable benefactor; // Address to receive the funds if the campaign is successful
        uint goal;               // Funding goal for the campaign (in wei)
        uint deadline;           // Deadline of the campaign (timestamp)
        uint amountRaised;       // Total amount raised for the campaign (in wei)
        bool ended;              // Flag to check if the campaign has ended
    }

    // Array to store all campaigns
    Campaign[] public campaigns;

    // Address of the contract owner
    address public owner;

    // Events to log important actions
    //CampaignCreated: Emitted when a new campaign is created. 
    //Indexed parameters (campaignId and benefactor) are searchable in the blockchain logs.
    event CampaignCreated(
        uint indexed campaignId,
        string title,
        address indexed benefactor,
        uint goal,
        uint deadline
    );
    //DonationReceived: Emitted when a donation is made to a campaign.
    event DonationReceived(
        uint indexed campaignId,
        address indexed donor,
        uint amount
    );
    //CampaignEnded: Emitted when a campaign ends and funds are transferred.
    event CampaignEnded(
        uint indexed campaignId,
        uint amountRaised,
        address indexed benefactor
    );

    // Modifier to restrict access to functions to the contract owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    // Modifier to check if a campaign exists
    modifier campaignExists(uint _campaignId) {
        require(_campaignId < campaigns.length, "Campaign does not exist.");
        _;
    }

    // Constructor to initialize the contract owner to the account that deploys the contract
    constructor() {
        owner = msg.sender;
    }

    // Function to create a new crowdfunding campaign
    function createCampaign(
        string memory _title,            // Title of the campaign
        string memory _description,      // Description of the campaign
        address payable _benefactor,     // Address to receive the funds if the campaign is successful
        uint _goal,                      // Funding goal for the campaign (in wei)
        uint _duration                   // Duration of the campaign (in seconds from now)
        //Note that memory means that the variable would only be stored temporarily and not to the blockchain
    ) public {
        require(_goal > 0, "Goal must be greater than zero."); // Ensure the goal is positive

        uint deadline = block.timestamp + _duration; // Calculate the deadline

        // Create a new campaign and add it to the campaigns array
        campaigns.push(Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            ended: false
        }));

        // Emit an event for the creation of the campaign
        emit CampaignCreated(campaigns.length - 1, _title, _benefactor, _goal, deadline);
    }

    // Function to donate to a specific campaign
    function donateToCampaign(uint _campaignId) public payable campaignExists(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "The campaign has already ended."); // Check if the campaign is still ongoing
        require(!campaign.ended, "The campaign has ended."); // Check if the campaign has not ended already

        // Update the amount raised in the campaign
        campaign.amountRaised += msg.value;

        // Emit an event for the donation
        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

    // Function to end a campaign and transfer the funds to the benefactor
    function endCampaign(uint _campaignId) public campaignExists(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "The campaign is still ongoing."); // Ensure the campaign has ended
        require(!campaign.ended, "The campaign has already ended."); // Ensure the campaign has not ended already

        // Mark the campaign as ended
        campaign.ended = true;

        // Transfer the funds to the benefactor
        campaign.benefactor.transfer(campaign.amountRaised);

        // Emit an event for the end of the campaign
        emit CampaignEnded(_campaignId, campaign.amountRaised, campaign.benefactor);
    }

    // Function for the owner to withdraw any leftover funds from the contract
    function withdrawFunds(uint _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance in the contract."); // Check if there are enough funds
        payable(owner).transfer(_amount); // Transfer the specified amount to the owner
    }

    // Fallback function to receive ether sent to the contract without data
    receive() external payable {}
}

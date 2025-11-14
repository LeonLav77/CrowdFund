// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CrowdFund {
    struct Campaign {
        address owner;
        string title;
        uint goal;
        uint deadline;
        uint totalRaised;
        bool goalReached;
        bool fundsWithdrawn;
    }
    
    mapping(uint => Campaign) public campaigns;
    // camapignId => (contributor address => amount)
    mapping(uint => mapping(address => uint)) public contributions;
    uint public campaignIdCounter;

    event CampaignCreated(uint campaignId, string title, uint goal, uint deadline);
    event DonationReceived(uint campaignId, address donor, uint amount);
    event FundsWithdrawn(uint campaignId, address owner, uint amount);
    event RefundIssued(uint campaignId, address contributor, uint amount);

    constructor() {
        campaignIdCounter = 0;
    }

    function createCampaign(string memory _title, uint _goal, uint _durationMinutes) public {
        uint deadline = block.timestamp + (_durationMinutes * 1 minutes);

        Campaign memory newCampaign = Campaign({
            owner: msg.sender,
            title: _title,
            goal: _goal,
            deadline: deadline,
            totalRaised: 0,
            goalReached: false,
            fundsWithdrawn: false
        });

        campaigns[campaignIdCounter] = newCampaign;
        emit CampaignCreated(campaignIdCounter, _title, _goal, deadline);
        campaignIdCounter++;

    }

    function donateTo(uint campaignId) public payable {
        campaignExists(campaignId);
        campaignStillActive(campaignId);
        donationGreaterThanZero(msg.value);

        Campaign storage campaign = campaigns[campaignId];

        contributions[campaignId][msg.sender] += msg.value;
        campaign.totalRaised += msg.value;

        if (campaign.totalRaised >= campaign.goal) {
            campaign.goalReached = true;
        }

        emit DonationReceived(campaignId, msg.sender, msg.value);
    }

    function withdrawFunds(uint campaignId) public {
        campaignExists(campaignId);
        
        Campaign storage campaign = campaigns[campaignId];
        require(msg.sender == campaign.owner, "Only campaign owner can withdraw funds");
        campaignFinished(campaignId);
        goalWasReached(campaignId);
        fundsNotWitrawnYet(campaignId);

        campaign.fundsWithdrawn = true;
        uint amount = campaign.totalRaised;

        payable(campaign.owner).transfer(amount);

        emit FundsWithdrawn(campaignId, campaign.owner, amount);
    }

    function refund(uint campaignId) public {
        campaignExists(campaignId);
        campaignFinished(campaignId);
        goalNotReached(campaignId);
        
        uint amount = contributions[campaignId][msg.sender];
        require(amount > 0, "Nothing to return");

        contributions[campaignId][msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit RefundIssued(campaignId, msg.sender, amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTimeLeft(uint campaignId) public view returns (uint) {
        campaignExists(campaignId);
        
        Campaign storage campaign = campaigns[campaignId];
        if (block.timestamp >= campaign.deadline) {
            return 0;
        }
        return campaign.deadline - block.timestamp;
    }

    function campaignExists(uint campaignId) internal view {
        require(campaignId < campaignIdCounter, "Campaign does not exist");
    }

    function campaignStillActive(uint campaignId) internal view{
        require(block.timestamp < campaigns[campaignId].deadline);
    }

    function campaignFinished(uint campaignId) internal view {
        require(block.timestamp >= campaigns[campaignId].deadline);
    }

    function goalWasReached(uint campaignId) internal view {
        require(campaigns[campaignId].goalReached, "Goal not reached");
    }

    function goalNotReached(uint campaignId) internal view {
        require(!campaigns[campaignId].goalReached, "Goal was reached");
    }

    function donationGreaterThanZero(uint amount) internal pure {
        require(amount > 0, "Donation must be greater than 0");
    }

    function fundsNotWitrawnYet(uint campaignId) internal view {
        require(!campaigns[campaignId].fundsWithdrawn, "Funds already withdrawn");
    }
}
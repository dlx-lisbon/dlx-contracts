pragma solidity ^0.5.10;

import "@openzeppelin/contracts/ownership/Ownable.sol";


/**
 * @title MeetupCore
 * @dev Meetup control contract
 */
contract MeetupCore is Ownable {

    enum MeetupStatus {OPEN, CANCELED}

    event NewMeetup(uint256 _id, uint256 _date, string _infoHash);
    event UpdatedMeetup(uint256 _id, uint256 _date, string _infoHash);
    event CanceledMeetup(uint256 _id);
    event NewCoordinator(address _coordinator);
    event CoordinatorLeft(address _coordinator);

    /**
     * Meetup data sctructure
     * @param status meetup status
     * @param date meetup data
     * @param seats meetup seats available
     * @param author meetup author addresses
     * @param infoHash meetup IPFS hash for info
     */
    struct Meetup {
        address author;
        uint256 status;
        uint256 date;
        uint256 seats;
        string infoHash;
    }
    // meetup attendees
    mapping(uint256 => mapping(address => bool)) public attendees;
    // meetups array
    Meetup[] public meetups;
    // coordinators map
    mapping(address => bool) public coordinators;

    /**
     * @dev Modifier to restrict any action to coordinators and contract owner.
     */
    modifier onlyCoordinators() {
        require(msg.sender == owner() || coordinators[msg.sender] == true, "Not Allowed!");
        _;
    }

    /**
     * @dev Constructor method initializing MeetupCore
     */
    constructor() public Ownable() {
        //
    }

    /**
     * @dev Public method available only to the contract owner
     * used to add new coordinators.
     * @param _coordinator address of the coordinator to be added
     */
    function addCoordinator(address _coordinator) public onlyOwner {
        coordinators[_coordinator] = true;
        emit NewCoordinator(_coordinator);
    }

    /**
     * @dev Public method available only to the contract owner
     * used to remove a given coordinator.
     * @param _coordinator address of the coordinator to be removed
     */
    function removeCoordinator(address _coordinator) public onlyOwner {
        coordinators[_coordinator] = false;
        emit CoordinatorLeft(_coordinator);
    }

    /**
     * @dev Public method available to coordinators and the contract owner
     * used to register a new meetup.
     * @param _date meetup date
     * @param _seats meetup available seats
     * @param _infoHash IPFS hash containing the title, full description, and location of the meetup
     */
    function newMeetup(uint256 _date, uint256 _seats, string memory _infoHash) public onlyCoordinators {
        Meetup memory meetup;
        meetup.status = uint256(MeetupStatus.OPEN);
        meetup.date = _date;
        meetup.seats = _seats;
        meetup.author = msg.sender;
        meetup.infoHash = _infoHash;
        uint256 id = meetups.push(meetup) - 1;
        emit NewMeetup(id, _date, _infoHash);
    }

    /**
     * @dev Public method available to coordinators and the contract owner
     * used to edit a meetup.
     * @param _id meetup id
     * @param _date meetup date
     * @param _seats meetup available seats
     * @param _infoHash IPFS hash containing the title, full description, and location of the meetup
     */
    function editMeetup(
        uint256 _id,
        uint256 _date,
        uint256 _seats,
        string memory _infoHash
    ) public onlyCoordinators {
        Meetup memory meetup = meetups[_id];
        meetup.date = _date;
        meetup.seats = _seats;
        meetup.infoHash = _infoHash;
        meetups[_id] = meetup;
        emit UpdatedMeetup(_id, _date, _infoHash);
    }

    /**
     * @dev Public method available to coordinators and the contract owner
     * used to cancel a meetup.
     * @param _id meetup id
     */
    function cancelMeetup(uint256 _id) public onlyCoordinators {
        Meetup memory meetup = meetups[_id];
        meetup.status = uint256(MeetupStatus.CANCELED);
        meetups[_id] = meetup;
        emit CanceledMeetup(_id);
    }

    /**
     * @dev Public method used to join a meetup.
     * @param _id meetup id
     */
    function joinMeetup(uint256 _id) public {
        Meetup storage meetup = meetups[_id];
        require(meetup.seats > 0, "No seats available!");
        attendees[_id][msg.sender] = true;
        meetup.seats -= 1;
        meetups[_id] = meetup;
    }

    /**
     * @dev Public method used to leave a meetup.
     * @param _id meetup id
     */
    function leaveMeetup(uint256 _id) public {
        Meetup storage meetup = meetups[_id];
        require(attendees[_id][msg.sender] == true, "Not in meetup!");
        attendees[_id][msg.sender] = false;
        meetup.seats += 1;
        meetups[_id] = meetup;
    }

    /**
     * @dev Public method used to get the total number of meetups
     * registered, independently of it's status.
     */
    function totalMeetups() public view returns(uint256) {
        return meetups.length;
    }
}
pragma solidity ^0.5.0;

contract ticketingSystem{
	
	address owner;
	uint CounterArtists;
    uint CounterVenues;
    uint CounterTickets;
    uint CounterConcerts;

	struct Artist{
		bytes32 name;
		uint category;
		uint totalSoldTicket;
		address owner;
	}
	struct Venue{
		bytes32 name;
		uint capacity;
		uint comission;
		address payable owner;
	}
	struct Ticket{
		uint concertDate;
		uint artistId;
		uint venueId;
		uint concertId;
        uint price;
        uint amountPaid;
        bool isAvailable;
        bool isAvailableForSale;
        address owner;
	}
	struct Concert{
		uint concertId;
		uint artistId;
		uint venueId;
		uint concertDate;
		uint concertPrice;
        uint totalSoldTicket;
        uint totalMoneyCollected;
        bool validatedByArtist;
        bool validatedByVenue;
        address owner;
	}

	mapping(uint => Artist) private artistsRegister;
	mapping(uint => Venue) private venuesRegister;
	mapping(uint => Ticket) private ticketsRegister;
	mapping(uint => Concert) private concertsRegister;

	constructor() public {
		owner = msg.sender;
	}

    modifier OwnerOfArtist(uint _id){
    	require(artistsRegister[_id].owner == msg.sender);
    	_;
    }

    modifier OwnerOfVenue(uint _id){
    	require(venuesRegister[_id].owner == msg.sender);
    	_;
    }

    modifier OwnerOfConcert(uint _id){
    	require(concertsRegister[_id].owner == msg.sender);
    	_;
    }

    modifier OwnerOfTicket(uint _id){
    	require(ticketsRegister[_id].owner == msg.sender);
    	_;
    }

	function createArtist(bytes32 _name, uint _category) public{
		CounterArtists++;
		artistsRegister[CounterArtists] = Artist(_name, _category, 0, msg.sender);
	}

	function modifyArtist(uint _id, bytes32 _name, uint _category, address _owner) public OwnerOfArtist(_id) {
		artistsRegister[_id].name = _name;
		artistsRegister[_id].category = _category;
		artistsRegister[_id].owner = _owner;
	}

	function createVenue(bytes32 _name, uint _capacity, uint _comission) public{
		CounterVenues++;
		venuesRegister[CounterVenues] = Venue(_name, _capacity, _comission, msg.sender);
	}

	function modifyVenue(uint _id, bytes32 _name, uint _capacity, uint _comission, address payable _owner) public OwnerOfVenue(_id){
		venuesRegister[_id].name = _name;
		venuesRegister[_id].capacity = _capacity;
		venuesRegister[_id].comission = _comission;
		venuesRegister[_id].owner = _owner;
	}

	function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _concertPrice)
	  public
	  returns (uint concertNumber)
	  {
	  	CounterConcerts++;
	    require(_concertDate >= now);
	    require(artistsRegister[_artistId].owner != address(0));
	    require(venuesRegister[_venueId].owner != address(0));
	    concertsRegister[CounterConcerts].concertDate = _concertDate;
	    concertsRegister[CounterConcerts].artistId = _artistId;
	    concertsRegister[CounterConcerts].venueId = _venueId;
	    concertsRegister[CounterConcerts].concertPrice = _concertPrice;
	    validateConcert(CounterConcerts);
	    concertNumber = CounterConcerts;
	  }

	function validateConcert(uint _concertId) public {
	    require(concertsRegister[_concertId].concertDate >= now);
	    if (venuesRegister[concertsRegister[_concertId].venueId].owner == msg.sender)
	    {
	      concertsRegister[_concertId].validatedByVenue = true;
	    }
	    if (artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender)
	    {
	      concertsRegister[_concertId].validatedByArtist = true;
	    }
	  }

	function emitTicket(uint _id, address _owner) public OwnerOfConcert(_id) {
		CounterTickets++;
        Concert storage thisConcert = concertsRegister[_id];
        artistsRegister[thisConcert.artistId].totalSoldTicket++;
        thisConcert.totalSoldTicket++;
        ticketsRegister[CounterTickets].concertId = _id;
        ticketsRegister[CounterTickets].owner = _owner;
        ticketsRegister[CounterTickets].artistId = thisConcert.artistId;
        ticketsRegister[CounterTickets].venueId = thisConcert.venueId;
        ticketsRegister[CounterTickets].concertDate = thisConcert.concertDate;
        ticketsRegister[CounterTickets].price = thisConcert.concertPrice;
        ticketsRegister[CounterTickets].isAvailable = true;
    }
    
    function useTicket(uint _id) public {
        require(ticketsRegister[_id].concertDate <= now);
        require(concertsRegister[ticketsRegister[_id].concertId].validatedByVenue);
        Ticket storage thisTicket = ticketsRegister[_id];
        thisTicket.owner = address(0);
        thisTicket.isAvailable = false;
		thisTicket.isAvailableForSale = false;
    }
    
    function buyTicket(uint _id) public payable{
        Concert storage thisConcert = concertsRegister[_id];
        CounterTickets++;
        artistsRegister[thisConcert.artistId].totalSoldTicket++;
        thisConcert.totalSoldTicket++;
        thisConcert.totalMoneyCollected += msg.value;
        ticketsRegister[CounterTickets].concertId = _id;
        ticketsRegister[CounterTickets].artistId = thisConcert.artistId;
        ticketsRegister[CounterTickets].venueId = thisConcert.venueId;
        ticketsRegister[CounterTickets].concertDate = thisConcert.concertDate;
        ticketsRegister[CounterTickets].amountPaid = msg.value;
        ticketsRegister[CounterTickets].isAvailable = true;
        ticketsRegister[CounterTickets].isAvailableForSale = false;
        ticketsRegister[CounterTickets].owner = msg.sender;
    }

    function transferTicket(uint _id, address _client) public OwnerOfTicket(_id) {
        ticketsRegister[_id].owner = _client;
    }

    function cashOut(uint _id, address payable _cashout) public OwnerOfConcert(_id){
        require(now >= concertsRegister[_id].concertDate);
        Concert storage thisConcert = concertsRegister[_id];
        Venue storage thisVenue = venuesRegister[thisConcert.venueId];
        uint venueShare = thisConcert.totalMoneyCollected * thisVenue.comission / 10000;
        uint artistShare = thisConcert.totalMoneyCollected - venueShare;
        thisVenue.owner.transfer(venueShare);
        _cashout.transfer(artistShare);
    }

}
pragma solidity ^0.4.20;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC20.sol";

contract TAL is ERC721{
	using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    event AddBreeder(address indexed breeder);
    event AnimalDeleted(address indexed owner, uint tokenId);
    event NewBorn(address indexed owner, uint tokenId);

    struct Dinde
    {
    	uint id;
        address owner;
        bool female;
    	string name;
    	uint age;
    	uint poids;
    	uint agressivite;
    }

    uint compteurID;

	// Mapping from address to boolean
    mapping (address => bool) private registeredBreeders;
    mapping (uint => Animal) private DindeID;

    constructor (ERC721 erc721, ERC20 erc20) public {
        // register the supported interfaces to conform to ERC721 via ERC165
		_erc721 = erc721;
        _erc20 = erc20;
    }

	//register Breeder with the Address
    function registerBreeder(address addr) public {
        require(!registeredBreeders[addr], "already registered");
        registeredBreeders[addr] = true;
        emit AddBreeder(addr);
    }

    function isBreeder(address addr) public view returns (bool) {
        return registeredBreeders[addr];
    }

    modifier onlyBreeder() {
        require(registeredBreeders[msg.sender], "not breeder");
    }

    function declareAnimal(address owner, bool female, string name, uint age, uint poids, uint agressivite) public onlyBreeder() returns (bool) {
        compteurID = compteurID + 1;
        Dinde memory dinde = Dinde(owner, female, name, age, poids, agressivite);
        DindeID[compteurID] = dinde;
        _erc721.mintToken(owner, compteurID);
        return true;
    }

    function deadAnimal(uint id) public {
        _erc721.burnToken(msg.sender, id);
        delete DindeID[id];
        emit AnimalDeleted(msg.sender, id);
    }

    function breedAnimals(uint senderID, uint receiverID) public onlyBreeder() returns (bool) {
        AllowBreeding(senderID, receiverID);
        Breeding(msg.sender, senderID, receiverID);
        emit NewBorn(msg.sender, compteurID);
        return true;
    }

    function AllowBreeding(uint senderID, uint receiverID) private view {
        require(CheckSex(senderID, receiverID), "same sex, can not breed.");
    }

    function CheckSex(uint ID1, uint ID2) private view returns (bool) {
        if ((DindeID[ID1].female) && (!DindeID[ID2].female)) return true;
        if ((!DindeID[ID1].female) && (DindeID[ID2].female)) return true;
        return false;
    }

    function Breeding(address owner, uint senderID, uint receiverID) private {
        bool female = DindeID[receiverID].female;
        uint agressivite = DindeID[senderID].agressivite;

        string name = "newtest";
        uint age = 0;
        uint poids = 1;

        declareAnimal(owner, female, name, age, poids, agressivite);
    }
}
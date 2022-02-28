// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract GamTestGobelinFight is ERC721, Ownable {

    enum type_character {VIKING, GAULOIS}
    
    uint nextId = 0;

    struct Character {
        uint8 attack;
        uint8 defense;
        uint life;
        uint32 experience;
        uint lastHeal;
        uint lastFight;
        type_character typeCharacter;
    }

    struct Payement {
        uint amount;
        uint timestamp;
    }

    struct Balance {
        uint totalBalance;
        uint numbPayement;
        mapping(uint => Payement) payments;
    }

    struct Gobelin {
        uint8 attack;
        uint8 defense;
        uint life;
    }

    mapping(uint => Character) private _characterDetails;
    mapping(uint => Gobelin) _gobelin;
    mapping(address => Balance) Wallets;

    /*
    Appelez au déployement du contrat
    */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    /*
    Permet de récupérer les statistiques d'un gobelin
    */
    function getGobelin(uint _gobelinId) public view returns(Gobelin memory) {
        return _gobelin[_gobelinId];
    }

    /*
    Permet de créer son gobelin
    Axe d'amélioration : Vu que solidity ne possède pas de random a prorement parler, faudrait faire le calcul côté front et juste envoyer les datas en paramètres
    */
    function setGobelin(uint _gobelinId, uint8 _attack, uint8 _defense, uint _life) public {
        _gobelin[_gobelinId].attack = _attack;
        _gobelin[_gobelinId].defense = _defense;
        _gobelin[_gobelinId].life = _life;
    }

    /*
    Permet de savoir combien d'argent sur le contrat
    */
    function getBalance() public view  returns(uint) {
        return address(this).balance;
    }

    /*
    Permet de savoir combien il y a d'argent sur mon wallet
    */
    function getMyBalance() public view returns(uint) {
        return Wallets[msg.sender].totalBalance;
    }
    
    /*
    Permet de récuperer tout l'argent déposer sur le contract
    */
    function withdrawAllMoney(address payable _to) public {
        uint amount = Wallets[msg.sender].totalBalance;
        Wallets[msg.sender].totalBalance = 0;
        _to.transfer(amount);
    }

    /*
    Permet de récupérer une partie de l'argent déposer sur le contract
    */
    function withdrawMoney(address payable _to, uint _amount) public {
        require(_amount <= Wallets[msg.sender].totalBalance, "not enough money");
        Wallets[msg.sender].totalBalance -= _amount;
        _to.transfer(_amount);
    }

    /*
    Permet de combattre un gobelin
    Axe d'amélioration : Vu que je peux pas mettre de uint negatif, faudrait faire le calcul côté front et juste envoyé les addresses à la fonction
    Axe d'amélioration : Gestion d'erreur
    */
    function fightGobelin(uint _tokenId1, uint _gobelinId, address payable _joueur1) public payable {
        uint substractLifeToGobelin = 5;
        
        if (_gobelin[_gobelinId].life - substractLifeToGobelin == 0 ) {
            _characterDetails[_tokenId1].experience++;
            _gobelin[_gobelinId].life = 1;
            _joueur1.transfer(1000000);
            Wallets[_joueur1].totalBalance += 1000000;
        }
        else {
            _characterDetails[_tokenId1].experience = 2;
        }

    }

    /*
    Permet de récuperer les details de son personnage
    */
    function getTokenId(uint _tokenId) public view returns(Character memory) {
        return _characterDetails[_tokenId];
    }

    /* 
    Permet de mint un nouveau personnage
    */
    function mint(type_character _typeCharacter) public {
        require(balanceOf(msg.sender) <= 4, "Already create max characters.");
        require(_typeCharacter == type_character.VIKING || _typeCharacter == type_character.GAULOIS, "Not valid");
        if (_typeCharacter == type_character.VIKING) {
            Character memory thisCharacter = Character(20, 15, 100, 1, block.timestamp, block.timestamp, type_character.VIKING);
            _characterDetails[nextId] = thisCharacter;
            _safeMint(msg.sender, nextId);
            nextId++;
        }
        if (_typeCharacter == type_character.GAULOIS) {
            Character memory thisCharacter = Character(13, 25, 80, 1, block.timestamp, block.timestamp, type_character.GAULOIS);
            _characterDetails[nextId] = thisCharacter;
            _safeMint(msg.sender, nextId);
            nextId++;
        }
    }

    /*
    On verifie que le personnage que l'on a soit transferable si il est mort on ne peut pas
    */
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
        Character storage thisCharacter = _characterDetails[tokenId];
        require( thisCharacter.life > 0, "this character is dead and cannot be transfer");
    }

    /*
    Permet de faire des transaction vers le Wallet
    */
    receive() external payable {
        Payement memory thisPayment = Payement(msg.value, block.timestamp);
        Wallets[msg.sender].totalBalance += msg.value;
        Wallets[msg.sender].payments[Wallets[msg.sender].numbPayement] = thisPayment;
        Wallets[msg.sender].numbPayement++;
    }

}

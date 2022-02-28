// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TestGame is ERC721, Ownable {

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

    struct potion {
        uint numberPotion;
        uint lifeBonus;
    }

    struct throwingKnife {
        uint numberThrowingKnife;
        uint8 dommageBonus;
    }

    mapping(uint => Character) private _characterDetails;
    mapping(address => potion) Potion;
    mapping(address => throwingKnife) ThrowingKnife;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {

    }

    /*
    Permet de récupérer les statistiques d'une potion
    */
    function getPotion(address _prorietaire) public view returns(potion memory) {
        return Potion[_prorietaire];
    }

    /*
    Permet de récupérer les statistiques d'un couteau de lancer
    */
    function getthrowingKnife(address _prorietaire) public view returns(throwingKnife memory) {
        return ThrowingKnife[_prorietaire];
    }

    /*
    Permet d'ajouter un couteau de lancer
    Axe d'amélioration : il faudrait plus faire un setteur pour le ThrowingKnife[_prorietaire].dommageBonus = 10; vu qu'il ne devrait pas changer
    */
    function addThrowingKnife(address _prorietaire) public {
        ThrowingKnife[_prorietaire].numberThrowingKnife += 1;
        ThrowingKnife[_prorietaire].dommageBonus = 10;
    }

    /*
    Permet d'ajouter une potion
    Axe d'amélioration : il faudrait plus faire un setteur pour le Potion[_prorietaire].lifeBonus = 40 vu qu'il ne devrait pas changer
    */
    function addPotion(address _prorietaire) public {
        Potion[_prorietaire].numberPotion += 1;
        Potion[_prorietaire].lifeBonus = 40;
    }

    /* 
    Permet d'utiliser une potion qui soigne son personnage et diminue le stock de potion de 1
    */
    function usedPotion(address _prorietaire, uint _tokenId) public {
        require(Potion[_prorietaire].numberPotion > 0, "not enough potion");
        require(msg.sender == _prorietaire, "not the owner");
        Potion[_prorietaire].numberPotion -= 1;
        _characterDetails[_tokenId].life += Potion[_prorietaire].lifeBonus;
    }

    /*
    Permet de chercher un item
    Axe d'amélioration : Vu que solidity ne possède pas de random a prorement parler, il faudrait faire le calcul côté front et juste envoyer les datas en paramètres
    */
    function searchItem(address _prorietaire, uint random) public {
        require(random >= 0 && random <= 1, "not in range for search");
        if (random == 0) {
            Potion[_prorietaire].numberPotion += 1;
        }
        if (random == 1) {
            ThrowingKnife[_prorietaire].numberThrowingKnife += 1;
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
    Permet de heal son personnage
    */
    function heal(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "you cant heal an other Character than yours.");
        Character storage thisCharacter = _characterDetails[_tokenId];
        require(thisCharacter.lastHeal + 60 < block.timestamp, "To soon to heal");
        require(thisCharacter.life > 0, "cant heal someone dead");
        thisCharacter.lastHeal = block.timestamp;
        thisCharacter.life += 50;
    }

    /*
    Permet a 2 personnages différents de s'affronter
    */
    function fight(uint _tokenId1, uint _tokenId2, bool itemFight) public payable {
        //require(_characterDetails[_tokenId1].lastFight + 60 < block.timestamp && _characterDetails[_tokenId2].lastFight + 60 < block.timestamp, "must wait before next fight");
        require(ownerOf(_tokenId1) == msg.sender, "Not your character");
        require(ownerOf(_tokenId1) != ownerOf(_tokenId2), "You cannot fight your own character");
        require(_characterDetails[_tokenId1].life > 0 && _characterDetails[_tokenId2].life > 0, "You can only fight with living character.");

        //Calculs
        if( itemFight == true) {
            _characterDetails[_tokenId1].attack += ThrowingKnife[msg.sender].dommageBonus;
            ThrowingKnife[msg.sender].numberThrowingKnife -= 1;
        }
        uint substractLifeToCharacter2 = (_characterDetails[_tokenId1].attack + _characterDetails[_tokenId1].experience) - (_characterDetails[_tokenId2].defense / 4);
        uint substractLifeToCharacter1 = (_characterDetails[_tokenId2].attack + _characterDetails[_tokenId2].experience) - (_characterDetails[_tokenId1].defense / 4);

        //timeStamp
        _characterDetails[_tokenId1].lastFight = block.timestamp;
        _characterDetails[_tokenId2].lastFight = block.timestamp;

        //Le perso 1 tue le perso 2, le perso 2 ne peut pas répliquer
        if (_characterDetails[_tokenId2].life - substractLifeToCharacter2 <= 0) {
            _characterDetails[_tokenId2].life = 0;
            _characterDetails[_tokenId1].experience++;
        }
        // Le perso 1 ne tue pas le perso 2, mais le perso 2 réplique et le tue
        else {
            if (_characterDetails[_tokenId2].life - substractLifeToCharacter2 > 0 && _characterDetails[_tokenId1].life - substractLifeToCharacter1 <= 0) {
                _characterDetails[_tokenId2].life -= substractLifeToCharacter2;
                _characterDetails[_tokenId1].life = 0;
                _characterDetails[_tokenId2].experience++;
            }
            //Le perso 1 ne tue pas le perso 2 et que le perso 2 ne tue pas le perso 1 
            else {
                _characterDetails[_tokenId1].life -= substractLifeToCharacter1;
                _characterDetails[_tokenId2].life -= substractLifeToCharacter2;
                if(substractLifeToCharacter1 > substractLifeToCharacter2) {
                    _characterDetails[_tokenId2].experience++;
                }
                else if(substractLifeToCharacter2 > substractLifeToCharacter1) {
                    _characterDetails[_tokenId1].experience++;
                }
                else {
                    _characterDetails[_tokenId1].experience++;
                    _characterDetails[_tokenId2].experience++;

                }
            }
        }
    }

    /*
    On verifie que le personnage que l'on a soit transferable si il est mort on ne peut pas
    */
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
        Character storage thisCharacter = _characterDetails[tokenId];
        require( thisCharacter.life > 0, "this character is dead and cannot be transfer");
    } 

}

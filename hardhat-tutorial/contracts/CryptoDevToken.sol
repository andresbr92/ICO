// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.4;

  import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
  import "@openzeppelin/contracts/access/Ownable.sol";
  import "./ICryptoDevs.sol";

  contract CryptoDevToken is ERC20, Ownable {
    // Price of one Crypto Dev token 
    uint256 public constant tokenPrice = 0.001 ether;

     // Each NFT would give the user 10 tokens
      // It needs to be represented as 10 * (10 ** 18) as ERC20 tokens are represented by the smallest denomination possible for the token
      // By default, ERC20 tokens have the smallest denomination of 10^(-18). This means, having a balance of (1)
      // is actually equal to (10 ^ -18) tokens.
      // Owning 1 full token is equivalent to owning (10^18) tokens when you account for the decimal places.
      // More information on this can be found in the Freshman Track Cryptocurrency tutorial.

      uint256 public constant tokensPerNFT = 10 * 10**18;
     uint256 public constant maxTotalSupply = 10000 * 10**18;
      ICryptoDevs CryptoDevsNFT;
      // Mapping to keep track of which NFT tokenIds have been claimed
      mapping(uint256 => bool) public tokensIdsClaimed;

      constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
      }

      function mint(uint256 amount) public payable {
        // the value of ether must be equal of greater than tokenPrice * amount
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is incorrect");
        // total tokens + amount <= 10000, otherwhise revert the transaction
        uint256 amountWithDecimals = amount *10**18;
        require((totalSupply() + amountWithDecimals) <= maxTotalSupply, "Exceeds the max total supply available");
        //call the internal function from Openzeppelin erc20 contract
        _mint(msg.sender, amountWithDecimals);
      }

        /**
       * @dev Mints tokens based on the number of NFT's held by the sender
       * Requirements:
       * balance of Crypto Dev NFT's owned by the sender should be greater than 0
       * Tokens should have not been claimed for all the NFTs owned by the sender
       */

      function claim() public {
        address sender = msg.sender;
        // Get the number of CryptoDevs NFT's held by a given sender adress
        uint256 balance = CryptoDevsNFT.balanceOf(sender);
        require(balance > 0, "You dont own any Crypto Dev NFT's");
        // amount keeps track of number of unclaimed tokenIds
        uint256 amount = 0;
        // loop over the balance and get the token ID owned by `sender` at a given `index` of its token list.
        for(uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
            // if the tokenId has not been claimed, increase de amount
            if(!tokensIdsClaimed[tokenId]) {
                amount += 1;
                tokensIdsClaimed[tokenId] = true;
            }
        }
        // If all the token ids have been claimed, revert the transaction;
        require(amount > 0, "You have already claimed all the tokens");

        _mint(msg.sender, amount * tokensPerNFT);


      }
      function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
      }
      // Function to receive Ether. msg.data must be empty
      receive() external payable {}

      // Fallback function is called when msg.data is not empty
      fallback() external payable {}

      

  }
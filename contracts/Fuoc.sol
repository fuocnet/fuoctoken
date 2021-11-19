// SPDX-License-Identifier: GPL-0.3
pragma solidity ^0.8.7;
/**
 * Interface as ERC20 standard
 */

interface IFRC20 {
    
  /**
   * Returns string of token name
   */
  function name() external view returns (string memory);
  
  /**
   * Returns string of token symbol
   */
  function symbol() external view returns (string memory);

  /**
   * Returns uint8 of token decimals
   */
  function decimals() external view returns (uint8);

  /**
   * Returns amount of token supply
   */
  function totalSupply() external view returns (uint256);

  /**
   * Return amount balance of specific address
   */
  function balanceOf(address guy) external view returns (uint256);

  /**
   * Function for move balance from one address to another address
   * This function will return boolean after proccess was completed
   */
  function transfer(address dst, uint256 wad) external returns (bool);

  /**
   * Return the remaining amout of token that spender can spend
   */
  function allowance(address src, address dst) external view returns (uint256);

  /**
   * Function to approve spender for spending amount of token
   */
  function approve(address dst, uint256 wad) external returns (bool);

  /**
   * Same like transfer function but here the sender can be anyone that have access (allowed) to source (holder)
   */
  function transferFrom(address src, address dst, uint256 wad) external returns (bool);

  /**
   * Event that will emited after transfer / transferFrom function
   */
  event Transfer(address indexed src, address indexed dst, uint256 wad);
  
  /**
   * Event that will emited after user approve a transaction
   */
  event Approval(address indexed src, address indexed dst, uint256 wad);

}


/**
 * Extension for using math in other contracts
 */
abstract contract Math {
  
  /**
   * Sum two number and return the results
   */
  function Sum(uint x, uint y) internal pure returns (uint z) 
  {
        
    require((z = x + y) >= x);
        
  }

  /**
   * Sub two number and return the result
   */
  function Sub(uint x, uint y) internal pure returns (uint z) 
  {
        
    require((z = x - y) <= x);
        
  }

}


/**
 * Main contract for ERC20 token standard
 * Using IFRC for the interface
 * Using Math for math operations
 */
contract FRC20 is IFRC20, Math {

  mapping(address => uint256) private $balanceOf;
  mapping(address => mapping(address => uint256)) private $allowances;
    
  uint256 private $totalSupply;
  string private $name;
  string private $symbol;

  /**
   * Contract constructor that will set the token name and symbol
   */
  constructor(string memory _name, string memory _symbol)
  {

    $name = _name;
    $symbol = _symbol;
        
  }

  /**
   * As defined in Interface this will return the value of token name
   */
  function name() public view virtual override returns (string memory)
  {

    return $name;
        
  }

  /**
   * As defined in Interface this will return the value of token aymbol
   */
  function symbol() public view virtual override returns (string memory)
  {
        
    return $symbol;
        
  }

  /**
   * As defined in Interface this will return the value of token decimals
   */
  function decimals() public view virtual override returns (uint8)
  {
        
    return 18;
        
  }

  /**
   * As defined in Interface this will return the amount of token supply
   */
  function totalSupply() public view virtual override returns (uint256)
  {
        
    return $totalSupply;
        
  }

  /**
   * As defined in Interface this will return the amount of balance for spexific address
   */
  function balanceOf(address guy) public view virtual override returns (uint256)
  {
        
    return $balanceOf[guy];
        
  }

  /**
   * As defined in Interface this will return the amount of allowance
   */
  function allowance(address src, address dst) public view virtual override returns (uint256)
  {
        
    return $allowances[src][dst];
        
  }

  /**
   * Transfer function to move token from one address to another
   */
  function transfer(address dst, uint256 wad) public virtual override returns (bool)
  {
  
    /**
     * Instead using the logic for transfer here, we call the transferFrom from function to handle the logic
     * we set the token source to msg.sender(transaction trigger)
     * for the destination we inherit from above as dst
     * and the amount of token is wad
     */
    return transferFrom(msg.sender, dst, wad);

  }

  /**
   * Transfer function for third party
   * Unlike transfer above, this function allow third party to move your balance to other address if the third party was allowed to do that
   */
  function transferFrom(address src, address dst, uint256 wad) public virtual override returns (bool)
  {
  
    /**
     * From here we call _safeTransfer function and pass the params to handle the logic
     */
    return _safeTransfer(src, dst, wad);
        
  }

  /**
   * function for handle transfer
   */
  function _safeTransfer(address src, address dst, uint256 wad) internal returns (bool)
  {
    
    /**
     * Transfer from zero address is porhibited so we check if the sender are not the zero address
     */
    require(src != address(0), "Transfer from zero address");

    /**
     * Also transfer to zero address was porhibited, but for that we have burn function
     */
    require(dst != address(0), "Transfer to zero address");

    /**
     * Check if the balance of sender was enough to transfer
     */
    require(balanceOf(src) >= wad, "Insufficient balance");

    /**
     * If sender was not the transaction caller, we need to verify if the transaction caller have permission to spend the token
     */
    if (src != msg.sender)
      {
        
        /**
         * Verify if the transaction caller have permision and the alowance was enough for transaction
         */
        require(allowance(src, dst) >= wad, "Insufficient allowance");

        /**
         * Decrease allowance of transaction caller using Sub function
         */
        $allowances[src][dst] = Sub(allowance(src, dst), wad);
            
      }

      /**
       * Set the balance of sender after transfer
       */
      $balanceOf[src] = Sub(balanceOf(src), wad);

      /**
       * Set the balance of recipient after transfer
       */
      $balanceOf[dst] = Sum(balanceOf(dst), wad);
      
      /**
       * Emit the transfer event to write transaction history on blockchain
       */
      emit Transfer(src, dst, wad);

      // return true of the proccess wass successed
      return true;
        
    }

    /**
     * Function for approving third party to spend your balance
     */
    function approve(address dst, uint256 wad) public virtual override returns (bool)
    {

      /**
        * Approving for zero address was porhibited so we check that here
        */
      require(dst != address(0), "Approval for zero address");

      /**
       * set the allowance
       */
      $allowances[msg.sender][dst] = wad;

      /**
       * Emit the Approval event to blockchain
       */
      emit Approval(msg.sender, dst, wad);

      /**
       * Return true if the transaction was successed
       */
      return true;
        
    }

    /**
     * mint function for minting new token
     * this will be used once when the token was deployed
     */
    function _mint(address dst, uint256 wad) internal
    {

      /**
       * check if destination address is not zero address
       */
      require(dst != address(0), "Mimt to zero address");

      /**
       * set the totalSupply
       */
      $totalSupply = Sum(totalSupply(), wad);

      /**
       * send the token to destination address
       */
      $balanceOf[dst] = Sum(balanceOf(dst), wad);

      /**
       * emit Transfer event to write transaction into blockchain
       */
      emit Transfer(address(0), dst, wad);
        
    }
    
}


/**
 * Contract for FUOC token
 */
contract FUOC is FRC20 {

  /**
   * constructor for defining token name, token symbol, and total supply
   */
  constructor() FRC20("Fuoc Token", "FUOC")
  {

    /**
     * This was initial mint of token to create the supply
     */
    _mint(msg.sender, 1000000000 ether);
    
  }
    
}

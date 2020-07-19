pragma solidity ^0.5.0;

// AggregatorInterface specifies ChainLink aggregator interface.
import "./AggregatorInterface.sol";

// IERC20Detailed defines the interface to ERC20Detailed token contract.
// We use this type of contract, @openzeppelin implementation,
// for our synthetic DeFi ERC20 tokens.
interface IERC20Detailed {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// ChainLinkPriceReferenceAggregator implements aggregation for set of ChainLink
// reference price oracles redirecting price requests to their target price
// oracle based on the denomination address.
contract ChainLinkPriceReferenceAggregator {
    // nativeToken represents the address of the native FTM tokens pool.
    address public nativeToken = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    // TokenInformation represents a single token handled by the reference aggregator.
    // The De-Fi API uses this reference to do on-chain tokens tracking.
    struct TokenInformation {
        address token;      // address of the token (unique identifier)
        string name;        // Name fo the token
        string symbol;      // symbol of the token
        string logo;        // URL address of the token logo
        uint8 decimals;     // number of decimals the token itsdelf uses
        uint8 priceDecimals;// number of decimals the token's price oracle uses
        bool isActive;      // is this token active in DeFi?
        bool canDeposit;    // is this token available for deposit?
        bool canBorrow;     // is this token available for fLend?
        bool canTrade;      // is this token available for direct fTrade?
        uint volatility;    // what is the index of volatility of the token in 8 decimals
    }

    // owner represents the manager address of the oracle aggregator.
    address public owner;

    // ChainLink aggregator interface references by denomination.
    // The left side is the token identifier, the right side
    // is the ChainLink aggregator address.
    mapping(address => AggregatorInterface) public aggregators;

    // tokens is the list of tokens handled by the DeFi reference aggregator.
    TokenInformation[] public tokens;

    // AggregatorChanged event is emitted when a new price oracle aggregator is set for a token.
    event AggregatorChanged(address indexed token, address aggregator, uint timestamp);

    // TokenInformationAdded event is emitted when a new token information is added to the contract.
    event TokenInformationAdded(address indexed token, string name, uint index, uint timestamp);

    // TokenInformationUpdated event is emitted when an existing token information is updated.
    event TokenInformationChanged(address indexed token, uint index, uint timestamp);

    // install new aggregator instance
    constructor() public {
        // remember the manager address
        owner = msg.sender;
    }

    // -----------------------------------------------
    // aggregators per token address management
    // -----------------------------------------------

    // setAggregator sets a new aggregator reference for the given token.
    function setAggregator(address token, address aggregator) external {
        // only owner can make the change
        require(msg.sender == owner, "access restricted");

        // make the change
        aggregators[token] = AggregatorInterface(aggregator);

        // emit notification to express the change
        emit AggregatorChanged(token, aggregator, now);
    }

    // -----------------------------------------------
    // current price and time stamp
    // -----------------------------------------------

    // getPrice returns the latest price available for the token specified.
    function getPrice(address token) public view returns (int256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer from the aggregator of the given token
        return aggregators[token].latestAnswer();
    }

    // getTimeStamp returns the time stamp the latest price was made available
    // by the ChainLink aggregator oracle for the token specified.
    function getTimeStamp(address token) public view returns (uint256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer from the aggregator of the given token
        return aggregators[token].latestTimestamp();
    }

    // -----------------------------------------------
    // prices and time stamps history
    // -----------------------------------------------

    // getPreviousPrice returns the price available for the token specified
    // from the ChainLink aggregator oracle <_back> update cycles before the most recent one.
    function getPreviousPrice(address token, uint256 _back) public view returns (int256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer round from the aggregator of the given token
        // we make sure the requested round is valid
        uint256 latest = aggregators[token].latestRound();
        require(_back <= latest, "not enough history");

        // get the price back then
        return aggregators[token].getAnswer(latest - _back);
    }

    // getTimeStamp returns the time stamp the price was made available
    // by the ChainLink aggregator oracle <_back> update cycles before the most recent one.
    function getPreviousTimeStamp(address token, uint256 _back) public view returns (uint256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer round from the aggregator of the given token
        // we make sure the requested round is valid
        uint256 latest = aggregators[token].latestRound();
        require(_back <= latest, "not enough history");

        // get the time stamp back then
        return aggregators[token].getTimestamp(latest - _back);
    }

    // -----------------------------------------------
    // tokens registry related functions below this
    // -----------------------------------------------

    // tokensCount returns the total number of tokens' details in the registry.
    function tokensCount() public view returns (uint256) {
        return tokens.length;
    }

    // findTokenIndex finds an index of a token in the tokens list by address; returns -1 if not found.
    function findTokenIndex(address _token) public view returns (int256) {
        // loop the list and try to find the token
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].token == _token) {
                return int256(i);
            }
        }
        return - 1;
    }

    // addToken adds new token into the reference contract.
    function addToken(
        address _token,
        address _aggregator,
        string calldata _logo,
        uint8 _priceDecimals,
        bool _isActive,
        bool _canDeposit,
        bool _canBorrow,
        bool _canTrade,
        uint _volatility
    ) external {
        // make sure only owner can do this
        require(msg.sender == owner, "access restricted");

        // try to find the address
        require(0 > findTokenIndex(_token), "token already known");

        // set the price aggregator
        aggregators[_token] = AggregatorInterface(_aggregator);
        emit AggregatorChanged(_token, _aggregator, now);

        // declare needed token details (either native, or ERC20 synth)
        string memory _name;
        uint8 _decimals;
        string memory _symbol;

        // pull the symbol of the token
        if (_token == nativeToken) {
            _decimals = 18;
            _name = "Native TFM Token";
            _symbol = "FTM";
        } else {
            // pull decimals from the ERC20 token
            _decimals = IERC20Detailed(_token).decimals();
            require(_decimals > 0, "token decimals invalid");

            // pull the name and symbol of the token
            _name = IERC20Detailed(_token).name();
            _symbol = IERC20Detailed(_token).symbol();
        }

        // add the token to the list
        tokens.push(TokenInformation({
            token : _token,
            name : _name,
            symbol : _symbol,
            logo: _logo,
            decimals : _decimals,
            priceDecimals : _priceDecimals,
            isActive : _isActive,
            canDeposit : _canDeposit,
            canBorrow : _canBorrow,
            canTrade : _canTrade,
            volatility : _volatility
            })
        );

        // inform
        emit TokenInformationAdded(_token, _name, tokens.length - 1, now);
    }

    // updateToken modifies existing token in the reference contract.
    function updateToken(
        address _token,
        string calldata _logo,
        uint8 _priceDecimals,
        bool _isActive,
        bool _canDeposit,
        bool _canBorrow,
        bool _canTrade,
        uint _volatility
    ) external {
        // make sure only owner can do this
        require(msg.sender == owner, "access restricted");

        // try to find the address in the tokens list
        int256 ix = findTokenIndex(_token);
        require(0 <= ix, "token not known");

        // update token details in the contract
        tokens[uint256(ix)].logo = _logo;
        tokens[uint256(ix)].priceDecimals = _priceDecimals;
        tokens[uint256(ix)].isActive = _isActive;
        tokens[uint256(ix)].canDeposit = _canDeposit;
        tokens[uint256(ix)].canBorrow = _canBorrow;
        tokens[uint256(ix)].canTrade = _canTrade;
        tokens[uint256(ix)].volatility = _volatility;

        // inform
        emit TokenInformationChanged(_token, uint256(ix), now);
    }
}

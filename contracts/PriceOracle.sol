pragma solidity ^0.5.0;

// @title Fantom price oracle.
contract PriceOracle {
    // Price structure represents a single symbol price.
    // We are using integer math in the contracts, but the price
    // can and usually does include fractions. To deal with it we multiply
    // the regular price of a symbol by 10^18, e.g. we treat the price
    // the same way we calculate in WEIs.
    struct Price {
        uint256 price; // price of the symbol in 10^18 range
        uint updated; // timestamp of the last price update
    }

    // expirationPeriod represents a time duration after which a price
    // is no longer relevant and can not be used.
    uint public priceExpirationPeriod;

    // owner represents the manager address of the oracle.
    address public owner;

    // sources represent a map of addresses allowed
    // to push new price updates into the oracle.
    mapping(address => bool) public sources;

    // prices represents the price storage organized by symbols.
    mapping(bytes32 => Price) public prices;

    // PriceChanged event is emitted when a new price for a symbol is pushed in.
    event PriceChanged(bytes32 indexed symbol, uint256 price);

    // PriceExpirationPeriodChanged event is emitted when a new price expiration period is set.
    event PriceExpirationPeriodChanged(uint newPeriod);

    // constructor instantiates a new oracle contract.
    constructor(uint expiration, address[] memory feeds) public {
        // keep the expiration period
        priceExpirationPeriod = expiration;

        // keep the list of feeds
        for (uint i = 0; i < feeds.length; i++) {
            sources[feeds[i]] = true;
        }
    }

    // changeExpirationPeriod modifies price expiration period inside the contract.
    function changeExpirationPeriod(uint expiration) public {
        // make sure this is legit
        require(msg.sender == owner, "only owner can change expiry");
        priceExpirationPeriod = expiration;

        // emit the expiration period changed
        emit PriceExpirationPeriodChanged(expiration);
    }

    // addSource adds new price source address to the contract.
    function addSource(address addr) public {
        // make sure this is legit
        require(msg.sender == owner, "only owner can add source");
        sources[addr] = true;
    }

    // dropSource disables address from pushing new prices.
    function dropSource(address addr) public {
        // make sure this is legit
        require(msg.sender == owner, "only owner can drop source");
        sources[addr] = false;
    }

    // setPrice changes the price for given symbol.
    function setPrice(bytes32 symbol, uint256 newPrice) public {
        // make sure the request is legit
        require(sources[msg.sender], "only authorized source can push price");

        // get the price from mapping
        Price storage price = prices[symbol];
        price.price = newPrice;
        price.updated = now;

        // emit the price change event
        emit PriceChanged(symbol, newPrice);
    }

    // getPrice returns a price for the symbol.
    function getPrice(bytes32 symbol) public view returns (uint256) {
        // get the price from mapping
        Price storage price = prices[symbol];

        // make sure the price has been set and is still legit
        require(price.updated > 0, "price for symbol not available");
        require(now < price.updated + priceExpirationPeriod, "price expired");

        return price.price;
    }
}

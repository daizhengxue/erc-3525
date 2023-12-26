// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@solvprotocol/erc-3525/ERC3525.sol";
import "@solvprotocol/erc-3525/IERC3525.sol";
import "./Base64.sol";
contract InscriptionERC3525 is ERC3525 {
    uint256 public mintLimit;
    uint256 public maxSupply;
    uint128 internal _totalSupply;
    uint256 private nextSlot;

    using Strings for uint256;

    // Struct to represent an Inscription, which is a set of slots
    struct Inscription {
        string op;     // Operation, e.g., "mint"
        uint256 amt;   // Amount, or value associated with the token
    }
    // Mapping from tokenId to its Inscription data
    mapping(uint256 => Inscription) private _inscriptions;

    constructor(    
        uint64 maxSupply_,
        uint64   mintLimit_
    ) ERC3525("Ins-20", "FINA", 18) {

        maxSupply = maxSupply_;
        mintLimit = mintLimit_;

    }
    /*function mintInscription(
        uint256 slot,
        string memory op,
        uint256 amt
    ) public {
        require(tx.origin == msg.sender, "Contracts are not allowed");
        require(keccak256(bytes(op)) == keccak256(bytes("mint")), "Operation must be 'mint'");
        uint256 tokenId = _mint(msg.sender, slot, amt); // Mint the token with the specified slot and amount
        require(amt <= mintLimit, "Exceeded mint limit");
        require(_totalSupply() + amt <= maxSupply, "Exceeded max supply");

        // Store the inscription data associated with the new token
        _inscriptions[tokenId] = Inscription({
            //p: p,
            op: op,
            //tick: tick,
            amt: amt
        });
    }*/

    function mintInscription(
    uint256 amt
    ) public {
    require(tx.origin == msg.sender, "Contracts are not allowed");
    require(amt <= mintLimit, "Exceeded mint limit");
    require(_totalSupply + amt <= maxSupply, "Exceeded max supply");
     // use nextSlot a slot number
    uint256 slot = nextSlot;
    // Mint the token with the specified slot and amount
    // If you're not using the tokenId, you can omit the variable
    _mint(msg.sender, slot, amt);

    // Update the total supply
    _totalSupply += uint128(amt);
    // Increment nextSlot for the next mint
    nextSlot++;
    }

    function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

    // Override tokenURI to include the inscription in the token's metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Query for nonexistent token");

    // Fetch the inscription data for the given token
    //Inscription memory inscription = _inscriptions[tokenId];
    uint256 currentBalance = balanceOf(tokenId);
    string memory op = "mint";
    string memory tick = symbol();
    string memory p = name();
    // New SVG and JSON construction
    string memory svgPart = string(
        abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="100" y="100" class="base">{</text>',
            '<text x="130" y="130" class="base">"p":"', p, '",</text>',
            '<text x="130" y="160" class="base">"op":"', op, '",</text>',
            '<text x="130" y="190" class="base">"tick":"', tick, '",</text>',
            '<text x="130" y="220" class="base">"amt":', Strings.toString(currentBalance),
            '</text><text x="100" y="250" class="base">}</text></svg>'
        )
    );

    // Encode the SVG part in base64
    string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svgPart))));

    // Construct the JSON part with the new SVG image
    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name":"', tick, ' #', Strings.toString(tokenId), '",',
                    '"description":"An ERC3525 token with inscription.",',
                    '"image":"', imageURI, '"}'
                )
            )
        )
    );

    // Return the final data URI
    return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // Add other functions as needed...
    

}

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
    //坤为地：全阴，二进制表示为 '000'。
    //震为雷：阳阴阴，二进制表示为 '100'。
    //巽为风：阴阳阴，二进制表示为 '010'。
    //坎为水：阴阳阳，二进制表示为 '011'。
    //离为火：阳阴阳，二进制表示为 '101'。
    //艮为山：阴阴阳，二进制表示为 '001'。
    //兑为泽：阳阳阴，二进制表示为 '110'。
    uint8[8] private hexagrams = [7, 0, 4, 2, 3, 5, 1, 6];
    uint8 private nextSlot = 1;  // 从 1 开始
    mapping(address => uint256) private addressToSlot;

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
        uint64  mintLimit_
    ) ERC3525("Ins-20", "FINA", 18) {

        maxSupply = maxSupply_;
        mintLimit = mintLimit_;
        nextSlot = 1;
    }
    function InscriptionMinted(uint256 amt) public {
    require(tx.origin == msg.sender, "Contracts are not allowed");
    require(amt <= mintLimit, "Exceeded mint limit");
    require(_totalSupply + amt <= maxSupply, "Exceeded max supply");

    uint256 slot;
    if (addressToSlot[msg.sender] == 0) {
        // 使用区块时间戳和发送者地址生成伪随机数
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 8;
        slot = hexagrams[random];  // 从易经卦象中选择一个 slot
        addressToSlot[msg.sender] = slot;
    } else {
        slot = addressToSlot[msg.sender];  // 重用已有的 slot
    }

    // Mint 操作
    _mint(msg.sender, slot, amt);

    // 更新总供应量
    _totalSupply += uint128(amt);
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

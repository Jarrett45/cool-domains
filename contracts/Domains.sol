// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

//First import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";

//Import another help function.
import "@openzeppelin/contracts/utils/Base64.sol";

import "hardhat/console.sol";

//We inherit the contract we imported. This means we'll have access
//to the inherited contract's methods.
contract Domains is ERC721URIStorage {

    //Magic given  to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //Here's our domain TLD!
    string public tld;

    //We'll be storing our NFT images on chain as SVGs.
    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';
    string newSvgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" version="1.0" width="300.000000pt" height="168.000000pt" viewBox="0 0 300.000000 168.000000" preserveAspectRatio="xMidYMid meet"><g transform="translate(0.000000,168.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none"><path d="M0 840 l0 -840 394 0 394 0 41 113 c70 192 104 335 117 492 4 57 7 62 59 112 31 29 65 57 76 64 20 10 20 9 14 -43 -6 -46 -3 -59 20 -101 30 -52 47 -107 47 -147 l0 -25 12 23 c10 19 9 34 -9 87 -11 35 -24 67 -28 71 -4 4 -7 12 -7 18 0 6 5 4 10 -4 7 -11 10 -7 10 18 0 17 3 32 8 32 4 -1 23 -21 42 -46 19 -25 49 -55 65 -67 17 -11 34 -27 38 -34 4 -7 13 -13 19 -13 7 0 21 -9 32 -19 36 -33 112 -31 154 4 17 14 33 25 36 25 11 0 -6 -54 -25 -80 -15 -20 -17 -33 -10 -62 7 -28 6 -35 -4 -31 -7 2 -16 -5 -20 -16 -8 -27 -71 -75 -86 -66 -7 5 -9 25 -4 62 7 56 -5 103 -32 131 -10 11 -12 8 -7 -15 3 -19 -2 -39 -18 -62 -13 -19 -31 -48 -40 -65 -9 -17 -17 -25 -18 -18 0 14 -30 17 -30 2 0 -5 4 -10 10 -10 6 0 5 -10 -2 -25 -7 -17 -14 -21 -19 -14 -4 6 -10 -7 -14 -30 -4 -23 -14 -45 -22 -48 -10 -4 -12 -14 -8 -35 5 -19 0 -41 -14 -69 -24 -45 -26 -53 -9 -43 11 7 9 -7 -7 -51 -8 -20 -8 -20 11 0 10 11 37 42 59 69 22 28 54 64 72 83 19 18 33 43 33 56 0 14 7 30 15 37 13 10 15 9 15 -11 1 -24 1 -24 26 5 32 36 104 76 137 76 13 0 33 10 44 23 30 33 117 166 152 233 38 72 39 55 5 -57 -19 -64 -24 -96 -20 -136 5 -41 3 -53 -8 -53 -7 0 -19 7 -26 15 -15 19 -30 19 -30 2 0 -8 -18 -19 -40 -26 -39 -11 -39 -13 -25 -35 14 -21 13 -23 -25 -45 -22 -12 -46 -32 -55 -44 -8 -12 -15 -18 -15 -14 0 4 -11 -3 -25 -15 -25 -22 -35 -45 -13 -32 7 5 8 3 3 -6 -6 -10 -13 -6 -27 13 -11 15 -27 27 -35 27 -11 0 -8 -6 8 -19 l24 -19 -28 -22 c-26 -21 -67 -87 -67 -110 0 -12 49 -13 68 -1 9 5 11 17 6 36 -5 20 -4 26 5 21 6 -4 11 -20 11 -37 0 -16 5 -29 11 -29 5 0 7 5 3 11 -3 6 19 35 51 65 65 62 118 79 149 48 17 -16 16 -18 -13 -30 -17 -7 -31 -17 -31 -23 0 -5 -10 -7 -22 -4 l-23 5 23 -16 c12 -10 22 -23 22 -29 0 -8 -4 -7 -9 2 -8 12 -12 12 -25 -2 -9 -8 -16 -18 -16 -21 0 -3 329 -6 730 -6 l730 0 0 840 0 840 -856 0 c-812 0 -856 -1 -843 -17 8 -10 23 -26 34 -36 20 -19 19 -19 -10 -2 -16 10 -39 26 -51 36 -20 19 -64 26 -64 11 0 -5 21 -29 47 -55 26 -26 42 -47 36 -47 -15 0 -113 78 -120 96 -5 14 -43 20 -43 6 0 -11 28 -52 58 -84 14 -16 21 -28 14 -28 -6 0 -33 27 -59 59 -26 33 -56 60 -65 60 -23 1 -22 -6 2 -49 20 -35 20 -34 -19 8 -21 23 -46 42 -55 42 -21 0 -20 -7 9 -59 14 -24 23 -46 21 -48 -5 -5 -64 72 -73 95 -11 25 -31 10 -40 -30 l-10 -43 -8 43 c-4 23 -12 42 -17 42 -14 0 -2 -44 26 -102 12 -26 18 -49 13 -51 -5 -1 -1 -37 11 -82 11 -44 19 -81 17 -83 -6 -7 -43 106 -51 153 -4 27 -18 69 -30 94 -13 24 -24 50 -24 57 0 22 -17 16 -24 -8 -10 -38 -7 -204 5 -260 6 -29 19 -70 29 -90 10 -21 15 -38 10 -38 -12 0 -59 114 -70 170 -14 76 -12 162 5 204 8 20 11 36 6 36 -50 0 -39 -356 15 -528 5 -15 4 -15 -5 -2 -14 19 -38 103 -45 160 -4 25 -11 73 -17 106 -10 59 -1 196 16 249 4 11 -3 4 -16 -15 -12 -19 -44 -68 -70 -108 l-47 -73 15 -54 c20 -69 27 -66 11 4 -9 39 -9 54 0 63 9 9 12 5 12 -17 0 -64 17 -55 30 17 14 81 29 120 29 78 0 -35 -23 -134 -47 -204 -18 -54 -19 -62 -5 -83 8 -13 13 -32 10 -43 -3 -11 -1 -20 4 -20 13 0 11 44 -2 74 -7 14 -8 33 -4 43 13 31 23 -22 23 -122 0 -56 -3 -79 -7 -60 l-7 30 -8 -32 c-11 -48 -21 -47 -18 1 2 24 -1 59 -6 80 -6 20 -6 34 -2 31 5 -3 2 14 -7 39 -19 51 -31 55 -14 4 9 -28 9 -31 -3 -15 -23 30 -50 127 -38 139 7 7 13 -4 17 -36 4 -25 11 -43 16 -41 4 3 12 -3 18 -12 17 -30 12 -8 -10 42 -11 26 -18 56 -15 67 4 16 -5 12 -37 -18 -23 -21 -33 -29 -22 -16 16 19 19 40 19 147 1 87 -2 125 -10 125 -7 0 -36 -21 -65 -47 -52 -46 -52 -38 0 20 l25 27 -272 0 -272 0 0 -840z m872 645 c3 -60 9 -119 12 -130 6 -15 5 -16 -2 -5 -18 28 -42 159 -42 227 1 63 2 66 14 43 8 -14 16 -72 18 -135z m107 68 c-1 -73 -17 -55 -25 27 -5 59 -4 63 10 46 10 -12 15 -38 15 -73z m101 18 c-1 -13 -3 -13 -15 3 -19 26 -19 42 0 26 8 -7 15 -20 15 -29z m145 19 c10 -11 13 -20 7 -20 -6 0 -16 9 -22 20 -6 11 -9 20 -7 20 2 0 12 -9 22 -20z m-205 -45 c0 -5 -5 -3 -10 5 -5 8 -10 20 -10 25 0 6 5 3 10 -5 5 -8 10 -19 10 -25z m164 -25 c5 -23 4 -30 -2 -20 -14 23 -25 77 -14 65 6 -5 13 -26 16 -45z m-54 -5 c0 -17 -2 -17 -10 -5 -5 8 -10 24 -10 35 0 17 2 17 10 5 5 -8 10 -24 10 -35z m160 14 c0 -5 -4 -9 -10 -9 -5 0 -10 7 -10 16 0 8 5 12 10 9 6 -3 10 -10 10 -16z m-215 1 c3 -5 1 -10 -4 -10 -6 0 -11 5 -11 10 0 6 2 10 4 10 3 0 8 -4 11 -10z m168 -35 c3 -19 1 -23 -8 -15 -7 6 -15 22 -18 35 -3 19 -1 23 8 15 7 -6 15 -22 18 -35z m-204 -5 c6 -19 7 -30 2 -25 -5 6 -13 24 -17 40 -9 39 0 30 15 -15z m51 -15 c0 -5 -5 -3 -10 5 -5 8 -10 20 -10 25 0 6 5 3 10 -5 5 -8 10 -19 10 -25z m-102 -26 c-3 -8 -7 -3 -11 10 -4 17 -3 21 5 13 5 -5 8 -16 6 -23z m-234 -189 c3 -8 10 -55 16 -105 8 -80 38 -246 54 -300 4 -11 -1 -4 -10 15 -26 55 -106 488 -92 496 5 3 8 16 7 27 0 12 0 27 1 32 2 6 6 -26 10 -70 4 -44 11 -87 14 -95z m964 68 c5 -61 -50 -92 -82 -46 -23 32 -20 55 9 84 24 24 28 25 48 11 14 -9 23 -27 25 -49z m-123 21 c-19 -83 68 -140 131 -86 21 18 27 32 27 65 0 23 2 42 5 42 3 0 16 -9 28 -21 25 -23 21 -43 -18 -101 -52 -77 -206 -43 -224 49 -5 26 -1 36 21 57 35 33 38 33 30 -5z m-443 -30 c18 -24 19 -28 4 -62 -12 -31 -20 -37 -44 -37 -21 0 -32 7 -40 25 -17 36 -15 48 9 79 25 32 45 31 71 -5z m-118 -18 c-5 -34 -3 -43 19 -65 33 -33 88 -35 118 -5 16 16 20 31 17 64 -3 45 12 52 32 14 26 -48 1 -101 -63 -129 l-40 -18 46 0 c25 0 54 -3 64 -6 11 -4 52 10 101 34 45 21 82 38 83 37 12 -27 24 -149 17 -175 -12 -43 -7 -98 10 -94 27 5 10 -18 -20 -27 -32 -9 -32 -9 -5 -10 16 -1 27 -7 27 -15 0 -8 14 -19 31 -25 33 -11 35 -34 3 -39 -10 -2 -26 -6 -34 -9 -8 -3 -24 -6 -34 -7 -11 -1 -21 -7 -24 -15 -3 -8 1 -12 8 -9 23 7 63 -39 58 -66 -9 -44 5 -49 55 -20 26 14 49 30 52 35 4 5 12 9 18 9 16 -1 -54 -59 -70 -60 -7 0 -13 -4 -13 -10 0 -5 -21 -9 -47 -8 -38 0 -75 14 -177 65 -70 35 -133 69 -140 74 -6 5 -32 23 -58 39 -26 16 -54 40 -63 54 -32 49 -98 211 -103 254 l-5 43 39 -17 c22 -9 55 -19 74 -22 31 -4 33 -3 18 11 -9 9 -26 32 -38 52 l-22 36 27 34 c34 46 47 45 39 -4z m-188 -36 c7 -19 14 -54 14 -78 0 -24 4 -47 9 -52 24 -28 63 -219 60 -303 -1 -34 -2 -33 -10 13 -4 28 -20 83 -34 124 -28 82 -30 95 -15 86 14 -8 14 -10 -19 76 -18 47 -29 93 -29 122 1 26 3 47 5 47 2 0 11 -16 19 -35z m-6 -243 c0 -2 -4 0 -10 3 -13 8 -14 10 15 -89 27 -94 30 -109 15 -86 -22 34 -71 253 -70 310 1 11 49 -124 50 -138z m810 138 c30 -6 56 -12 59 -15 8 -9 -62 -75 -78 -75 -9 0 -34 15 -56 34 -34 29 -38 36 -26 50 16 19 30 20 101 6z m191 -173 c-10 -9 -11 -8 -5 6 3 10 9 15 12 12 3 -3 0 -11 -7 -18z m-867 -113 l6 -49 -15 55 c-16 61 -19 98 -5 64 5 -12 11 -43 14 -70z m836 72 c0 -2 -8 -10 -17 -17 -16 -13 -17 -12 -4 4 13 16 21 21 21 13z m-90 -81 c-24 -24 -45 -43 -48 -41 -3 4 79 85 88 86 2 0 -16 -20 -40 -45z m-65 -55 c-3 -5 -12 -10 -18 -10 -7 0 -6 4 3 10 19 12 23 12 15 0z m-728 -52 c-3 -7 -5 -2 -5 12 0 14 2 19 5 13 2 -7 2 -19 0 -25z m693 28 c0 -2 -8 -10 -17 -17 -16 -13 -17 -12 -4 4 13 16 21 21 21 13z m-105 -136 c3 -6 -1 -7 -9 -4 -18 7 -21 14 -7 14 6 0 13 -4 16 -10z m-176 -54 c7 -8 8 -17 3 -20 -6 -3 -12 3 -15 14 -6 24 -4 25 12 6z m231 4 c0 -12 -27 -12 -55 0 -16 7 -13 9 18 9 20 1 37 -3 37 -9z m174 -265 c3 -8 1 -15 -4 -15 -6 0 -10 7 -10 15 0 8 2 15 4 15 2 0 6 -7 10 -15z m-317 -242 c-15 -16 -17 -16 -17 -1 0 9 6 18 13 21 20 7 22 -2 4 -20z"/><path d="M1654 1362 c-21 -14 -23 -41 -3 -64 l19 -23 20 24 c24 28 26 51 5 51 -8 0 -15 5 -15 10 0 12 -11 13 -26 2z"/><path d="M1081 1308 c-18 -47 36 -82 59 -39 14 27 13 41 -5 41 -8 0 -15 5 -15 10 0 19 -31 10 -39 -12z"/><path d="M610 1625 c-6 -30 -9 -63 -7 -73 3 -11 5 -8 6 9 0 15 8 46 16 69 18 50 18 50 6 50 -5 0 -15 -25 -21 -55z"/><path d="M642 1613 c-7 -38 -15 -86 -17 -108 l-6 -40 19 30 c20 31 40 185 23 185 -4 0 -13 -30 -19 -67z"/><path d="M696 1671 c-2 -3 -6 -28 -10 -56 l-6 -50 25 54 c14 29 25 54 25 56 0 5 -31 1 -34 -4z"/><path d="M1260 546 c0 -2 7 -7 16 -10 8 -3 12 -2 9 4 -6 10 -25 14 -25 6z"/><path d="M1112 500 c0 -14 2 -19 5 -12 2 6 2 18 0 25 -3 6 -5 1 -5 -13z"/><path d="M1678 483 c-3 -4 -2 -19 2 -33 l6 -25 8 24 c8 22 -7 52 -16 34z"/><path d="M1040 365 c0 -31 -21 -99 -34 -112 -17 -17 -36 -78 -36 -117 0 -22 -7 -62 -15 -88 -11 -37 -11 -48 -2 -48 7 0 28 42 47 92 19 51 48 108 64 126 29 33 30 35 18 90 -7 31 -19 63 -27 71 -13 14 -15 12 -15 -14z"/><path d="M1185 290 c3 -5 8 -10 11 -10 2 0 4 5 4 10 0 6 -5 10 -11 10 -5 0 -7 -4 -4 -10z"/><path d="M1171 134 c0 -11 3 -14 6 -6 3 7 2 16 -1 19 -3 4 -6 -2 -5 -13z"/><path d="M1130 54 c-22 -51 -23 -54 -12 -54 22 1 35 22 36 59 1 23 0 41 -2 41 -1 0 -12 -21 -22 -46z"/><path d="M830 15 l-25 -14 28 -1 c17 0 27 5 27 15 0 18 1 18 -30 0z"/></g><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    
    //A "mapping" data type to store their names.
    mapping(string => address) public domains;

    //This will store values.
    mapping(string => string) public records;

    mapping(uint => string) public names;

    //Create a global owner variable for withdraw.
    address payable public owner;

    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);

    //We make the contract "payable" by adding this to the constructor.
    constructor(string memory _tld) ERC721("Nen Name Service", "NNS") payable {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    //This function will give us the price of a domain based on length.
    function price(string calldata name) public pure returns(uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        if(len == 3) {
            return 5 * 10**17;  //5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17;  //To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    //A register function that adds their names to our mapping.
    //Added "payable" modifier to register function
    function register(string calldata name)  public payable{

        if(domains[name] != address(0)) revert AlreadyRegistered();
        if(!valid(name)) revert InvalidName(name);

        //Check that the name is unregistered.
        require(domains[name] == address(0));

        uint256 _price = price(name);

        //Check if enough Matic was paid in the transaction.
        require(msg.value >= _price, "Not enough Matic paid");

        //Combine the name passed into the function with the TLD.
        string memory _name = string(abi.encodePacked(name, ".", tld));
        //Create the SVG (image) for the NFT with the name.
        string memory finalSvg = string(abi.encodePacked(newSvgPartOne, _name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s on the contract with tokenId %d", name, newRecordId);

        //Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64.
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Nen name service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '", "length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

        console.log("\n------------------------------------");
        console.log("Final tokenURI", finalTokenUri);
        console.log("------------------------------------\n");

        //Mint the NFT to newRecordId.
        _safeMint(msg.sender, newRecordId);

        //Set the NFTs data -- in this case the JSON blob w/ our domian's info!
        _setTokenURI(newRecordId, "ipfs://Qmas84KucwedjHczqwDPqP7CxCM1d5qvMaNy36Trnq59MB" /*finalTokenUri*/);
        domains[name] = msg.sender;

        names[newRecordId] = name;

        _tokenIds.increment();
        console.log("%s has registered a domain!", msg.sender);
    }

    //This will give us the domain owners' address.
    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        if(msg.sender != domains[name]) revert Unauthorized();

        //Check that the owner is the transaction sender.
        //require(domains[name] == msg.sender);
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns(string memory) {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "Failed to withdraw Matic");
    }

    function getAllNames() public view returns(string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());

        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) < 10;
    }

}
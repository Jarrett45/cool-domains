import React, { useEffect, useState } from 'react';
import './styles/App.css';
import twitterLogo from './assets/twitter-logo.svg';
import {ethers} from "ethers";
import contractABI from "./utils/contractABI.json";
import polygonLogo from "./assets/polygonlogo.png";
import ethLogo from "./assets/ethlogo.png";
import { networks } from "./utils/networks";

// Constants
const TWITTER_HANDLE = '_buildspace';
const TWITTER_LINK = `https://twitter.com/${TWITTER_HANDLE}`;

//Add the domain you will be minting.
const tld = ".nen";
const CONTRACT_ADDRESS = "0xF38D055a2Cde0D03e3F8d1b76bEDEaC58e356eD7";

const App = () => {

  const [currentAccount, setCurrentAccount] = useState("");

  const [domain, setDomain] = useState("");

  const [loading, setLoading] = useState(false);

  const [record, setRecord] = useState("");

  const [network, setNetwork] = useState("");

  const [editing, setEditing] = useState(false);

  const [mints, setMints] = useState([]);

  const connectWallet = async () => {

    try {

      const { ethereum } = window;

      if(!ethereum) {
        alert("Get Metamask -> https://metamask.io/");
        return;
      }

      const accounts = await ethereum.request({ method: "eth_requestAccounts" });

      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts);
    } catch (error) {
      console.log(error);
    }
  }

  const checkIfWalletIsConnected = async () => {

    const { ethereum } = window;

    if(!ethereum) {
      console.log("Make sure you have Metamask!!");
      return;
    } else {
      console.log("We have the ethereum object", ethereum);
    }

    //Check if we're authorized to access the user's wallet.
    const accounts = await ethereum.request({ method: "eth_accounts" });

    //We can have multiple authorized accounts, we grab the first one if it's there!
    if(accounts.length !== 0) {
      const account = accounts[0];
      console.log("Found an authorized account:", account);
      setCurrentAccount(account);
    } else {
      console.log("No authorized account found");
    }

    //This is the new part, we check the user's network chain ID.
    const chainId = await ethereum.request({ method: "eth_chainId"});
    setNetwork(networks[chainId]);

    ethereum.on('chainChanged', handleChainChanged);

    //Reload the page when they change networks.
    function handleChainChanged(_chainId) {
      window.location.reload();
    }

  }

  const mintDomain = async () => {

    //Don't run if the domain is empty.
    if(!domain) { return; }

    //Alert the user if the domain is too short.
    if(domain < 3) {
      alert("Domain must be at least 3 characters long");
      return;
    }

    //Calculate price based on length of domain(change this to match the contract)
    //3 characters = 0.5 MATIC, 4 characters = 0.3 MATIC, 5 or more characters = 0.1 MATIC
    const price = domain.length === 3 ? "0.5" : domain.length === 4 ? "0.3" : "0.1";
    console.log("Minting domian", domain, "with price", price);

    try {

      const { ethereum } = window;

      if(ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = await provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI.abi, signer);

        setLoading(true);
        
        console.log("Going to pop wallet now to pay gas...");
        let txn = await contract.register(domain, { value: ethers.utils.parseEther(price) });
        const receipt = await txn.wait();

        //Check if the transaction was successfully completed.
        if(receipt.status == 1) {
          console.log("Domain minted! https://mumbai.polygonscan.com/tx/"+txn.hash);

          //Set the record for the domain. 
          txn = await contract.setRecord(domain, record);
          await txn.wait();

          console.log("Record set! https://mumbai.polygonscan.com/tx/"+txn.hash);

          setLoading(false);

          //Call fetchMints after 2 seconds.
          setTimeout(() => {
            fetchMints();
          }, 2000);

          setRecord("");
          setDomain("");
        } else {
          alert("Transaction failed! Please try again");
          
          setLoading(false);
        }
        
      }
      
    } catch (error) {
      console.log(error);

      setLoading(false);
    }
    
  }

  const fetchMints = async () => {

    try {

      const { ethereum } = window;

      if(ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI.abi, signer);

        //Get all the domain names from our contract.
        const names = await contract.getAllNames();

        //For each name, get the record and address.
        const mintRecords = await Promise.all(names.map( async (name) => {
          
          const mintRecord = await contract.records(name);
          const owner = await contract.domains(name);
          return {
            id: names.indexOf(name),
            name: name,
            record: mintRecord,
            owner: owner,
          };
          
        } ));

        console.log("MINTS FETCHED ", mintRecords);
        setMints(mintRecords);
      }
      
    } catch (error) {
      console.log(error);
    }
    
  }

  const updateDomain = async () => {

    if(!record || !domain) { return; };
    setLoading(true);

    {/*Display a logo and wallet connection status*/}
    console.log("Updating domain", domain, "with record", record);

    try {

      const { ethereum } = window;
      if(ethereum) {
        const provider = new ethers.providers.Web3Porvider(ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(CONTRACT_ADDRESS, contractABI.abi, signer);

        let txn = await contract.setRecord(domain, record);
        await txn.wait();
        console.log("Record set https://mumbai.polygonscan.com/tx/" + txn.hash);

        fetchMints();
        setRecord('');
        setDomain('');
      }
      
    } catch (error) {
      console.log(error);
    }

    setLoading(false);
    
  }

  const switchNetwork = async () => {
    if(window.ethereum) {

      try {

        //Try to switch to the Mumbai Testnet.
        await window.ethereum.request({
          method: "wallet_switchEthereumChain",
          params: [{ chainId: "0x13881" }], //Check network.js for hexadecimal network ids.
        });
        
      } catch (error) {
        //This error codes means that the chain we want has not been add to Metamask.
        //In this case we ask the uers add it to their Metamask.
        if(error.code === 4902) {

          try {

            await window.ethereum.requeset({
              method: "wallet_addEthereumChain",
              params: [
                {
                  chainId: "0x13881",
                  chainName: "Polygon Mumbai Testnet",
                  nativeCurrency: {
                    name: "Mumbai Matic",
                    symbol: "MATIC",
                    decimals: 18
                  },
                  blockExporlorerUrls: ["https://mumbai.polygonscan.com/"]
                }
              ]
            });
            
          } catch (error) {
            console.log(error);
          }
          
        }
        
        console.log(error);
        
      }
      
    } else {
      //If window.ethereum is not found then Metamask is not installed.
      alert("Metamask is not installed. Please install it to use this app: https://metamask.io/download.html");
    }
    
  }

  //Creat a function to render if wallet is not connected yet.
  const renderNotConnectedContainer = () => (
    <div className="connect-wallet-container">
      <img src="https://media4.giphy.com/media/etW2P2cvB0PYY/giphy.gif?cid=ecf05e47hbmw2eayughfpevf860az3msaqedtaalvdlttpx2&rid=giphy.gif&ct=g" alt="Kurapika gif" />
      <button className="cta-button connect-wallet-button" onClick={connectWallet}>
        Connect Wallet
      </button>
    </div>
  );

  const renderConnectedContainer = () => {

    //If not on Polygon Mumbai Testnet, render "Please connect to Polygon Mumbai Testnet".
    if(network !== "Polygon Mumbai Testnet") {
      return (
        <div className="connect-wallet-container">
          <h2>Please connect to the Polygon Mumbai Testnet</h2>
          <button className="cta-button mint-button" onClick={switchNetwork}>Click Here To Switch</button>
        </div>
      );
    }
    
    return (
      <div className="form-container">
        <div className="first-row">
          <input
            type="text"
            value={domain}
            placeholder="domain"
            onChange={e => setDomain(e.target.value)}
            />
          <p> {tld} </p>
        </div>

        <input
          type="text"
          value={record}
          placeholder="what's your nen ability?"
          onChange={e => setRecord(e.target.value)}
          />

        {/*If the editing is true, return the "Set record" and "Cancel" button*/}
        {editing ? (
        <div className="button-container">
          {/*This will call updateDomain function we just made*/}
          <button className="cta-button mint-button" disabled={loading} onClick={updateDomain}>
            Set Record
          </button>
          {/*This will let us get out of editing mode by setting editing to false*/}
          <button className="cta-button mint-button" onClick={ () => { setEditing(false) } }>
            Cancel
          </button>
        </div>) : (loading ? 
        <button className="cta-button mint-button" disabled>Minting</button>
         : 
        //If editing is not true, the mint button will return instead
        <button className="cta-button mint-button" disabled={loading} onClick={mintDomain}>
          Mint
        </button>
        ) }
        
      </div>
    );
  }

  const renderMints = () => {

    if(currentAccount && mints.length > 0) {
      
      return (
        <div className="mint-container">
          <p className="subtitle">Recently Minted Domains!!</p>
          <div className="mint-list">
            { mints.map((mint, index) => {
          return (
            <div className="mint-item" key={index}>
              <div className="mint-row">
                <a className="link" href={`https://testnets.opensea.io/assets/mumbai/${CONTRACT_ADDRESS}/${mint.id}`} target="_blank" rel="noopener noreferrer">
                  <p className="underlined">{' '}{ mint.name }{ tld }{' '}</p>
                </a>
                {/*If mint.owner is currentAccount, add an "edit" button*/}
                { mint.owner.toLowerCase() === currentAccount.toLowerCase() ?
                <button className="edit-button" onClick={() => editRecord(mint.name)}>
                  <img src="https://img.icons8.com/metro/26/000000/pencil.png" alt="Edit button" className="edit-icon" />
                </button>
                :
                null
                }
              </div>
              <p>{ mint.record }</p>
            </div>
          )
            }) }
          </div>
        </div>
      )
        
    }
    
  }

  const editRecord = (name) => {
    
    console.log("Editing record for", name);
    setEditing(true);
    setDomain(name);
    
  }

  //This runs our function when the page load.
  useEffect(() => {
    checkIfWalletIsConnected();
  }, [])

  //This will run any time currentAccount or network are changed.
  useEffect(() => {
    if(network === "Polygon Mumbai Testnet") {
      fetchMints();
    }
  }, [currentAccount, network]);

  return (
		<div className="App">
			<div className="container">
				<div className="header-container">
					<header>
            <div className="left">
              <p className="title">🐱‍👤 Nen Name Service</p>
              <p className="subtitle">Your immortal API on the blockchain!</p>
            </div>
            {/*Display a logo and wallet connection status*/}
            <div className="right">
              <img src={ network.includes("Polygon") ? polygonLogo : ethLogo } alt="Network Logo" className="logo" />
              { currentAccount ? <p> Wallet: {currentAccount.slice(0,6)}...{currentAccount.slice(-4)} </p> : <p> Not Connected </p>}
            </div>
					</header>
				</div>

        {/*Add the render method here and hide the function if currentAccount isn't empty*/}
        {currentAccount ? renderConnectedContainer() : renderNotConnectedContainer()}
        {mints && renderMints()}

        <div className="footer-container">
					<img alt="Twitter Logo" className="twitter-logo" src={twitterLogo} />
					<a
						className="footer-text"
						href={TWITTER_LINK}
						target="_blank"
						rel="noreferrer"
					>{`built with @${TWITTER_HANDLE}`}</a>
				</div>
			</div>
		</div>
	);
}

export default App;

const main = async () => {
    const [owner, superCoder] = await hre.ethers.getSigners();

    //const [owner, randomPerson] = await hre.ethers.getSigners();

    const domainContractFactory = await hre.ethers.getContractFactory("Domains");
    const domainContract = await domainContractFactory.deploy("nen");
    await domainContract.deployed();
    console.log("Contract deployed to:", domainContract.address);

    /*
    console.log("Contract deployed by:", owner.address);

    const txn = await domainContract.register("doom");
    await txn.wait();

    const domainOwner = await domainContract.getAddress("doom");
    console.log("Owner of domain:", domainOwner);

    //Trying to set a record that doesn't belong to me!
    txn = await domainContract.connect(randomPerson).setRecord("doom", "Haha my domain now!");
    await txn.wait();
    */

    //We're passing in a second variable - value. This is the moneyyyyyyyy.
    let txn = await domainContract.register("go", {value: hre.ethers.utils.parseEther("1234")});
    await txn.wait();

    const address = await domainContract.getAddress("kurapika");
    console.log("Owner of domain kurapika:", address);

    //How much money is in here?
    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));

    //Quick! Grab the funds from the contract! (as superCoder)
    try {
        txn = await domainContract.connect(superCoder).withdraw();
        await txn.wait();
    } catch (error) {
        console.log("Could not rob contract");
    }

    try {
        txn = await domainContract.connect(superCoder).setRecord("kurapika", "What is the nen??");
        await txn.wait();
        console.log("Set record for kurapika");
    } catch (error) {
        console.log(error);
    }

    txn = await domainContract.connect(owner).setRecord("kurapika", "What is the nen??");
    await txn.wait();
    console.log("Set record for kurapika.nen");

    //Let's look in their wallet so we can compare later.
    let ownerBalance = await hre.ethers.provider.getBalance(owner.address);
    console.log("Balance of owner before withdrawal:", hre.ethers.utils.formatEther(ownerBalance));

    //Oops, looks like the owner is saving their money!
    txn = await domainContract.connect(owner).withdraw();
    await txn.wait();

    //Fetch balance of contract & owner.
    const contractBalance = await hre.ethers.provider.getBalance(domainContract.address);
    ownerBalance = await hre.ethers.provider.getBalance(owner.address);

    console.log("Contract balance after withdrawal:", hre.ethers.utils.formatEther(contractBalance));
    console.log("Balance of owner after withdrawal:", hre.ethers.utils.formatEther(ownerBalance));
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();
const main = async () => {
    const domainContractFactory = await hre.ethers.getContractFactory("Domains");
    const domainContract = await domainContractFactory.deploy("nen");
    await domainContract.deployed();
    console.log("Contract deployed to:", domainContract.address);

    let txn = await domainContract.register("kurapika", {value: hre.ethers.utils.parseEther("0.1")});
    await txn.wait();
    console.log("Minted domain kurapika.nen");

    txn = await domainContract.setRecord("kurapika", "What is kurapika's nen power??");
    await txn.wait();
    console.log("Set record for kurapika.nen");

    const address = await domainContract.getAddress("kurapika");
    console.log("Owner of domain kurapika:", address);

    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract Balance:", hre.ethers.utils.formatEther(balance));
}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
}

runMain();
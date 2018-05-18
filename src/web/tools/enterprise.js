var web3 = require('./web3');
var contract_data = require('../data/contract_data');
var contract_abi = require('../data/contract_abi');

function enterprise() {
  this.newContract = function(session) {
    var unlockStatus = web3.personal.unlockAccount(session.account, session.password);
    var enterprise = contract_abi.enterprise_contract_abi.new({
     from: session.account,
     data: contract_data.enterpriseContractData, 
     gas: '4700000'
   }, function (e, contract){
    if (typeof contract.address !== 'undefined') {
      console.log(contract.address);
      session.contractAddress = contract.address;
      session.save();
    }});
  }

  this.getTransferRecords = function (contractAddress) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getTransferRecords({from: session.account});
  }

  this.addTransferRequest = function(session, contractAddress, factory, amount, expireTime){
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.addTransferRequest(factory, amount, expireTime,{from: session.account, gas:6000000});
  }

  this.setTransferStatus = function(session, contractAddress, factory, exporter, amount, expireTime){
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.setTransferStatus(factory, exporter, amount, expireTime, {from:session.account, gas:6000000});
  }

  this.setDebtStatus = function(session, contractAddress, enterprise, amount, time, status) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.setDebtStatus(enterprise, amount, time, status,{from: session.account, gas: 6000000});
  }

  this.commitTransferDebt = function(session, contractAddress, factory, exporter, amount, time) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.commitTransferDebt(factory, exporter, amount, time, {from: session.account, gas:6000000})
  }

  this.addFinancing = function(session, contractAddress, factory, amount, cash, is_done) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.addFinancing(factory, amount, cash, is_done, {from:session.account, gas: 6000000});
  }

  this.getDebts = function(session, contractAddress, enterpriseAddress) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getDebts(enterpriseAddress, {from: session.account, gas: 6000000});
  }

  this.getFinancing = function(session, contractAddress, factory) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getFinancing(factory, {from: session.account, gas: 6000000});
  }

  this.addDebt = function(session, contractAddress, enterprise, debtType, amount, time) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.addDebt(enterprise, debtType, amount, time,{from:session.account, gas:6000000});
  }
}

module.exports = enterprise;
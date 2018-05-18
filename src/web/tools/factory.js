var web3 = require('./web3')
var contract_data = require('../data/contract_data');
var contract_abi = require('../data/contract_abi');

function factory() {
    this.newContract = function(session) {
    var unlockStatus = web3.personal.unlockAccount(session.account, session.password);
    var factoring = contract_abi.factory_contract_abi.new({
     from: session.account, 
     data: contract_data.factoryContractData, 
     gas: '4700000'

   }, function (e, contract){
    if (typeof contract.address !== 'undefined') {
      session.contractAddress = contract.address;
      session.save();
    }});
  }

  this.getQueue = function(session, contractAddress) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getQueue({from: session.account, gas: 6000000});
  }

  this.getDebts = function(session, contractAddress, merchant) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress)
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getDebts(merchant, {from: session.account, gas: 6000000});
  }

  this.getCredit = function(session, contractAddress, merchant) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress)
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getCredit(merchant, {from: session.account, gas: 6000000});
  }

  this.setCredit = function(session, contractAddress, merchant, value) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress)
    web3.personal.unlockAccount(session.account, session.password);
    return contract.setCredit(merchant, value, {from: session.account, gas: 6000000});
  }

  this.requestFinancing = function(session, contractAddress, merchant, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.requestFinancing(merchant, amount,time , {from: session.account, gas:6000000});
  }

  this.cancelFinancing = function(session, contractAddress, merchant, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.cancelFinancing(merchant, amount,time , {from: session.account, gas:6000000});
  }

  this.commitTransferDebt = function(session, contractAddress, exporter, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.commitTransferDebt(exporter, amount,time , {from: session.account, gas:6000000});
  }

  //返回是否仍有欠款
  this.payBack = function(session, contractAddress, exporter, time, money) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.payBack(exporter, time, {from: session.account, value: money, gas: 6000000});
  }

}

module.exports = factory;
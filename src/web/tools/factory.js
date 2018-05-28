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
    if (!e){
      if (!contract.address) { //第一次调用 交易哈希设置后调用
       console.log("TransactionHash : " + contract.transactionHash);
      } else { //第二次调用 合约部署后调用
       console.log("Contract Address is : " + contract.address);
       session.contractAddress = contract.address;
       session.save();
      }
    }else{
      console.log("部署合约出错：" + e);
    }});
  }

  //融资申请列表：出口商20　进口商20　应收账款额8　当前信用额度8　帐期8　状态1
  this.getQueue = function(session, contractAddress) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getQueue({from: session.account, gas: 5000000});
  }

  //返回应收账款列表：原出口商20　未付8　已付8　帐期8
  this.getDebts = function(session, contractAddress, merchant) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getDebts(merchant, {from: session.account, gas: 5000000});
  }

  //返回信用额度 uint256
  this.getCredit = function(session, contractAddress, merchant) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getCredit(merchant, {from: session.account, gas: 5000000}).toJSON();
  }

  //设置额度
  this.setCredit = function(session, contractAddress, merchant, value) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.setCredit(merchant, value, {from: session.account, gas: 5000000});
  }

  //申请融资　出口商调用
  this.requestFinancing = function(session, contractAddress, merchant, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    contract.requestFinancing(merchant, amount, time , {from: session.account, gas:5000000});
    return true;
  }

  //取消申请　出口商调用
  this.cancelFinancing = function(session, contractAddress, merchant, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.cancelFinancing(merchant, amount, time , {from: session.account, gas:5000000});
  }

  //确认账款转移 进口商调用
  this.commitTransferDebt = function(session, contractAddress, exporter, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.commitTransferDebt(exporter, amount, time, {from: session.account, gas:5000000});
  }

  //进行还款　返回是否仍有欠款
  this.payBack = function(session, contractAddress, exporter, merchant, amount, time) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.payBack(exporter, merchant, amount, time, {from: session.account, gas: 5000000});
  }

  this.getMoney = function(session, contractAddress, exporter, amount) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.payBack(exporter, amount, {from: session.account, gas: 5000000});

  }

  //获取融资额
  this.getAmount = function(session, contractAddress) {
    var contract = contract_abi.factory_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.get_amount({from:session.account, gas:5000000});
  }

}

module.exports = factory;
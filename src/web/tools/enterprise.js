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

  //返回账款转移申请列表　保理20　出口商20　数额8　帐期8　状态1
  this.getTransferRecords = function (session, contractAddress) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getTransferRecords({from: session.account});
  }

  //申请账款转移　出口商调用
  this.addTransferRequest = function(session, contractAddress, factory, amount, expireTime){
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    contract.addTransferRequest(factory, amount, expireTime,{from: session.account, gas:5000000});
    return true;
  }

  //设置转移请求的状态为false　返回是否成功
  this.setTransferStatus = function(session, contractAddress, factory, exporter, amount, expireTime){
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.setTransferStatus(factory, exporter, amount, expireTime, {from:session.account, gas:5000000});
  }

  //设置账款状态　返回是否成功
  this.setDebtStatus = function(session, contractAddress, enterprise, amount, time, status) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.setDebtStatus(enterprise, amount, time, status,{from: session.account, gas: 5000000});
  }

  //确认转移账款　进口商调用
  this.commitTransferDebt = function(session, contractAddress, factory, exporter, amount, time) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.commitTransferDebt(factory, exporter, amount, time, {from: session.account, gas:5000000})
  }

  //添加融资记录
  this.addFinancing = function(session, contractAddress, factory, amount, cash, is_done) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.addFinancing(factory, amount, cash, is_done, {from:session.account, gas: 5000000});
  }

  //返回账款记录　对方20 数额8　帐期8　账款类型1　是否已转移1　状态1
  this.getDebts = function(session, contractAddress, enterpriseAddress) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getDebts(enterpriseAddress, {from: session.account, gas: 5000000});
  }

  //返回融资记录列表 数额8　融资额8　是否已经提取1
  this.getFinancing = function(session, contractAddress, factory) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.getFinancing(factory, {from: session.account, gas: 5000000});
  }

  //添加账款记录
  this.addDebt = function(session, contractAddress, enterprise, debtType, amount, time) {
    var contract = contract_abi.enterprise_contract_abi.at(contractAddress);
    web3.personal.unlockAccount(session.account, session.password);
    return contract.addDebt(enterprise, debtType, amount, time,{from:session.account, gas:5000000});
  }
}

module.exports = enterprise;
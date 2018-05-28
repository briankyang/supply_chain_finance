var express = require('express');
var router = express.Router();
var enterprise = require('../tools/enterprise');
var factory = require('../tools/factory');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/info', function(req, res, next) {
    res.render('debt-info');
});

router.post('/info', function(req, res, next) { //查询账款信息
    var contractAddress = req.body.contractAddress;
    var enterpriseAddress = req.body.enterpriseAddress;
    var _enterprise = new enterprise();
    var _data = _enterprise.getDebts(req.session, contractAddress, enterpriseAddress);
    var parse_data = [];
    var i = 0, j = 0;
    while (i < _data.length) {
        let tmp = {};
        let t = "";
        for (j = 0; j < 20; ++j){
            t += _data[i++].substring(2);
        }
        tmp.address = "0x" + t;
        t = "";
        for (j = 0; j < 8; ++j)
            t += _data[i++].substring(2);
        tmp.amount = "0x" + t;
        t = "";
        for (j = 0; j < 8; ++j)
            t += _data[i++].substring(2);
        tmp.expireTime = "0x" + t;
        t = "";
        tmp.debtType = _data[i++].substring(2);
        tmp.isTransfered = _data[i++].substring(2);
        tmp.status = _data[i++].substring(2);
        parse_data.push(tmp);
    }
    res.json({"code":"0",msg:"ok","count":parse_data.length,"data":parse_data})
    // res.json({"code":"0",msg:"ok","count":100,"data":[{"id":1, "address":"0xffee", "amount":120, "expireTime": 1600000, "debtType": 1, "isTransfered":false,"status":"true"}]})
});

router.get('/add', function(req, res, next) {
    res.render('debt-add');
});

router.post('/add', function(req, res, next) {// 添加账款信息
    var contractAddress = req.body.contractAddress;
    var enterpriseAddress = req.body.enterpriseAddress;
    var debtType = req.body.debtType;
    var value = req.body.value;
    var expireTime = req.body.expireTime;
    var _enterprise = new enterprise();
    var _status = _enterprise.addDebt(req.session, contractAddress, enterpriseAddress, debtType=="1"?"1":"", value, expireTime);
    res.json({status: _status});
});

router.get('/trans', function(req, res, next) {
    var _address = req.query.as;
    var _amount = req.query.at;
    var _expireTime = req.query.et;
    console.log(parseInt(_amount));
    console.log(parseInt(_expireTime));
    res.render('debt-trans', {address:_address, amount:_amount, expireTime: _expireTime});
})

router.post('/trans', function(req, res, next) { //请求进口商进行账款转移
    var contractAddress = req.body.contractAddress;
    var factoryAddress = req.body.factoryAddress;
    var merchant = req.body.merchant;
    var value = req.body.value;
    var expireTime = req.body.expireTime;
    var _factory = new factory();
    console.log("额度::" + _factory.requestFinancing(req.session, factoryAddress, merchant, value, expireTime));
    var _enterprise = new enterprise();
    var _status = _enterprise.addTransferRequest(req.session, contractAddress, factoryAddress, value, expireTime);
    res.json({status:_status});
});

router.get('/queue', function(req, res, next) {
    res.render('trans-queue');
});

router.post('/queue', function(req, res, next) {　//查看账款转移请求
    var contractAddress = req.body.contractAddress;
    var _enterprise = new enterprise();
    var _data = _enterprise.getTransferRecords(req.session, contractAddress);
    var parse_data = [];
    var i = 0, j = 0;
    while (i < _data.length) {
        let tmp = {};
        let t = "";
        for (j = 0; j < 20; ++j){
            t += _data[i++].substring(2);
        }
        tmp.factory = "0x" + t;
        t = "";
        for (j = 0; j < 20; ++j)
            t += _data[i++].substring(2);
        tmp.exporter = "0x" + t;
        t = "";
        for (j = 0; j < 8; ++j)
            t += _data[i++].substring(2);
        tmp.amount = "0x" + t;
        t = "";
        for (j = 0; j < 8; ++j)
            t += _data[i++].substring(2);
        tmp.expireTime = "0x" + t;
        t = "";
        tmp.status = _data[i++].substring(2);
        parse_data.push(tmp);
    }
    console.log(_data);
    res.json({"code":"0",msg:"ok","count":parse_data.length,"data":parse_data})
});

router.get('/commitTrans', function(req, res, next) {
    var _factory = req.query.ft;
    var _exporter = req.query.er;
    var _amount = req.query.at;
    var _expireTime = req.query.et;
    res.render('trans-commit', {factory:_factory, exporter:_exporter, amount:_amount, expireTime:_expireTime});
});

router.post('/commitTrans', function(req, res, next) {　// 进口商进行账款转移
    var contractAddress = req.body.contractAddress;
    var factoryAddress = req.body.factoryAddress;
    var exporter = req.body.exporter;
    var value = req.body.value;
    var expireTime = req.body.expireTime;
    var _enterprise = new enterprise();
    var _factory = new factory();
    _enterprise.commitTransferDebt(req.session, contractAddress, factoryAddress, exporter, value, expireTime);
    _factory.commitTransferDebt(req.session, factoryAddress, exporter, value, expireTime);
    res.json({status: true});
});

module.exports = router;

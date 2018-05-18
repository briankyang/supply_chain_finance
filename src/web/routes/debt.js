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
    var _data = _enterprise.info(req.session, contractAddress, enterpriseAddress);
    res.json({data: _data});
});

router.get('/add', function(req, res, next) {
    res.render('debt-add');
});

router.post('/add', function(req, res, next) {// 添加账款信息
    var contractAddress = req.body.contractAddress;
    var enterpriseAddress = req.body.enterpriseAddress;
    var debtType = req.body.debtType;
    var value = req.body.value;
    var expireTime = req.body.value;
    var _enterprise = new enterprise();
    var _status = _enterprise.add(req.session, contractAddress, enterpriseAddress, debtType, value, expireTime);
    res.json({status: _status});
});

router.post('/del', function(req, res, next) {
    var contractAddress = req.body.contractAddress;
    var enterpriseAddress = req.body.enterpriseAddress;
    var debtType = req.body.debtType;
    var value = req.body.value;
    var expireTime = req.body.expireTime;
    var _enterprise = new enterprise();
    var _status = _enterprise.del(req.session, contractAddress, enterpriseAddress, debtType, value, expireTime);
    res.json({status: _status});
});


router.get('/trans', function(req, res, next) {
    res.render('debt-trans');
})

router.post('/trans', function(req, res, next) {
    var contractAddress = req.body.contractAddress;
    var factoryAddress = req.body.factoryAddress;
    var value = req.body.value;
    var expireTime = req.body.expireTime;
    var _enterprise = new enterprise();
    var _status = _enterprise.trans(req.session, contractAddress, factoryAddress, value, expireTime);
    res.json({status:_status});
});

router.post('/getList', function(req, res, next) {
    var contractAddress = req.body.contractAddress;
    res.json({res:(new enterprise()).getTrans(contractAddress)});
});

router.get('/queue', function(req, res, next) {
    return 'trans-queue';
})

router.post('/doTrans', function(req, res, next) {
    var contractAddress = req.body.contractAddress;
    var factoryAddress = req.body.factoryAddress;
    var enterpriseAddress = req.body.enterpriseAddress;
    var value = req.body.value;
    var expireTime = req.body.expireTime;
    var _enterprise = new enterprise();
    var _factory = new factory();
    var _status = _enterprise.doTrans(req.session, contractAddress, factoryAddress, enterpriseAddress, value, expireTime);
    var __status = false;
    if (_status) {
        __status = _factory.commitFinancing(req.session, factoryAddress, enterpriseAddress, value, expireTime);
    }

    res.json({status: __status});
});

module.exports = router;

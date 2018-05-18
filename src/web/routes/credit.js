var express = require('express');
var router = express.Router();
var factory = require('../tools/factory');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/query', function(req, res, next) {
    res.render('credit-query');
});

router.post('/query', function(req, res, next) { //查询信用额度
    var factoryAddress = req.body.factoryAddress;
    var merchantAddress = req.body.merchantAddress;
    var _factory = new factory();
    var _credit = _factory.queryCredit(req.session, factoryAddress, merchantAddress);
    res.json({address:merchantAddress, credit:_credit});
});

router.get('/modify', function (req, res, next) {
    res.render('credit-modify');
})

router.post('/modify', function(req, res, next) { //调整信用额度
    var _factory = new factory();
    var factoryAddress = req.body.factoryAddress;
    var merchantAddress = req.body.merchantAddress;
    var value = req.body.value;
    var _factory = new factory();
    var retVal = _factory.modifyCredit(req.session, factoryAddress, merchantAddress, value);
    res.json({address: merchantAddress, credit: retVal});
});

module.exports = router;

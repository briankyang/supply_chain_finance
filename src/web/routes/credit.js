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
    var contractAddress = req.body.contractAddress;
    var merchant = req.body.merchant;
    var _factory = new factory();
    console.log(req.body);
    var _credit = _factory.getCredit(req.session, contractAddress, merchant);
    res.json({address:merchant, credit:_credit});
});

router.get('/modify', function (req, res, next) {
    res.render('credit-modify');
})

router.post('/modify', function(req, res, next) { //调整信用额度
    var _factory = new factory();
    var contractAddress = req.body.contractAddress;
    var merchant = req.body.merchant;
    var value = req.body.value;
    var _factory = new factory();
    var _status = _factory.setCredit(req.session, contractAddress, merchant, value);
    res.json({address: merchant, credit: value, status: true});
});

module.exports = router;

var express = require('express');
var router = express.Router();
var enterprise = require('../tools/enterprise');
var factory = require('../tools/factory');

router.get('/queue', function(req, res, next){
    var _factory = new factory();
    var _data = _factory.getQueue(req.session, req.query.contractAddress);
    console.log(_data);
    res.render('financing-queue', {data:_data});
});

router.post('/getAmount', function(req, res, next) {
    var _factory = new factory();
    var contractAddress = req.body.contractAddress;
    var _amount = _factory.getAmount(req.session, contractAddress);
    res.json({amount: _amount});
})

module.exports = router;
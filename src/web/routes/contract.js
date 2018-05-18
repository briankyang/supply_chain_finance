var express = require('express');
var router = express.Router();
var enterprise = require('../tools/enterprise');
var factory = require('../tools/factory');

router.get('/add', function(req, res, next){
    res.render('contract-add');
});

router.post('/add', function(req, res, next){
    if (req.body.contractType == "0"){
        (new enterprise()).newContract(req.session);
    }else if (req.body.contractType == "1") {
        (new factory()).newContract(req.session);
    }
    res.write("请稍后在个人中心查看合约地址");
})

module.exports = router;
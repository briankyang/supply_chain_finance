var express = require('express');

var web3 = require('../tools/web3');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res, next) {
  res.send('respond with a resource');
});

router.get('/login', function(req, res, next) {
  res.render('login');
});

router.get('/detail', function (req, res, next) {
  res.json({session : req.session});
});

router.post('/login', function(req, res, next){
  req.session.account = req.body.account;
  req.session.password = req.body.password;
  req.session.save();
  res.json({account:req.body.account, password:req.body.password});
});

router.get('/logout', function(req, res, next) {
  req.session.destroy();
  res.redirect('/');
});

router.get('/add', function(req, res, next) {
  res.render('account-add');
});

router.post('/add', function(req, res, next) {
  var pass = req.body.pass;
  var _account = null;

  if (pass){ //校验密码
    _account = web3.personal.newAccount(pass);
  }

  req.session.account = _account;
  req.session.password = pass;
  req.session.save();
  // if (_account) { //如果创建账户成功，就继续创建相应的智能合约
  //   if (accountType == "0"){
  //     // (new enterprise()).newContract(account, req.session);//创建企业对应的智能合约,创建成功后合约地址保存在session中
  //   }else if (accountType == "1") {
  //     // (new factory()).newContract(account, req.session);//创建保理对应的智能合约
  //   }
  // }
  res.json({account: _account, password: pass})
});

module.exports = router;

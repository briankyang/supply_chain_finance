var express = require('express');
var router = express.Router();
var factory = require('../tools/factory');
var enterprise = require('../tools/enterprise');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});


router.get('/request', function(req, res, next) {
  //...直接从账款那边跳转过来，传来账款数据等信息，在前台页面进行渲染
});

router.post('/requres', function(req, res, next) {
  var factoryAddress = req.session.factoryAddress;
  var merchantAddress = req.session.merchantAddress;
  var value = req.session.value;
  var expireTime = req.session.expireTime;
  var _factory = new factory();
  var _enterprise = new enterprise();

  _factory.requestFinancing(req.session, factoryAddress, merchantAddress, value, expireTime);

});

module.exports = router;

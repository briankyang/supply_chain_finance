var createError = require('http-errors');
var express = require('express');
var path = require('path');
// var cookieParser = require('cookie-parser');
var logger = require('morgan');
var session = require('express-session');
var uuid = require('uuid/v1');
var redisStore = require('connect-redis');

var indexRouter = require('./routes/index');
var userRouter = require('./routes/user');
var creditRouter = require('./routes/credit');
var debtRouter = require('./routes/debt');
var financingRouter = require('./routes/financing');
var contractRouter = require('./routes/contract');
// var initRouter = require('./routes/init');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.set('trust proxy', 1);


app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
// app.use(cookieParser()); //新版express-session无需cookieParser
app.use(express.static(path.join(__dirname, 'public')));

app.use(session({
  secret:"secret",
  resave:true,
  saveUninitialized:true,
  cookie: {
    maxAge: 30 * 60 * 1000,
    secure: false,
    httpOnly: false
  }
}));

//每次接收请求后，更新session时间
app.use(function(req, res, next) {
  req.session._garbage = Date();
  req.session.touch();
  next();
});

app.use('/', indexRouter);
app.use('/user', userRouter);
app.use('/account', userRouter);
app.use('/financing', financingRouter);
app.use('/debt', debtRouter);
app.use('/credit', creditRouter);
app.use('/contract', contractRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});
module.exports = app;

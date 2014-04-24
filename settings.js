// Generated by CoffeeScript 1.7.1
(function() {
  var Instagram, RedisStore, app, appPort, callback, db, express, http, io, mongoHostname, mongoose, server;

  express = require('express');

  exports.express = express;

  mongoHostname = process.env.MONGO_URL || 'mongodb://localhost/test';

  mongoose = require('mongoose');

  mongoose.connect(mongoHostname);

  exports.mongoose = mongoose;

  db = mongoose.connection;

  db.on("error", console.error.bind(console, "connection error:"));

  db.once("open", callback = function() {
    return console.log('connected to mongodb');
  });

  exports.REDIS_PORT = process.env.REDIS_PORT || 6379;

  exports.REDIS_HOST = process.env.REDIS_HOST || '127.0.0.1';

  exports.REDIS_URL = process.env.REDIS_URL;

  RedisStore = require('connect-redis')(express);

  exports.redisStore = RedisStore;

  appPort = process.env.PORT || 3000;

  http = require('http');

  app = express();

  app.set('view engine', 'jade');

  server = http.createServer(app).listen(appPort);

  exports.app = app;

  exports.server = server;

  exports.appPort = appPort;

  exports.httpClient = require('http');

  exports.HOSTNAME = process.env.IG_HOSTNAME;

  exports.debug = true;

  io = require('socket.io');

  io = io.listen(server);

  exports.io = io;

  exports.CLIENT_ID = process.env.IG_CLIENT_ID || 'CLIENT_ID';

  exports.CLIENT_SECRET = process.env.IG_CLIENT_SECRET || 'CLIENT_SECRET';

  exports.SUB_ENDPOINT = 'https://api.instagram.com/v1/subscriptions';

  exports.SUB_CALLBACK = exports.HOSTNAME + '/callbacks/tag/';

  Instagram = require('instagram-node-lib');

  exports.inst = Instagram;

}).call(this);

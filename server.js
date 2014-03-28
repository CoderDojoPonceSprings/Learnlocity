var url     = require('url'),
    http    = require('http'),
    https   = require('https'),
    fs      = require('fs'),
    qs      = require('querystring'),
    express = require('express'),
    app 	= express(),
    http 	= require('http'),
    server  = http.createServer(app),
    io      = require('socket.io').listen(server),
    mongo   = require('mongodb').MongoClient,
    _       = require('underscore');

// Set up our mongo data and decorator
var msgs = null;

function decorateMessage(msg) {
  msg.timestamp = new Date();
  return msg;
}

// Load config defaults from JSON file.
// Environment variables override defaults.
function loadConfig() {
  var config = JSON.parse(fs.readFileSync(__dirname+ '/config.json', 'utf-8'));
  for (var i in config) {
    config[i] = process.env[i.toUpperCase()] || config[i];
  }
  console.log('Configuration');
  console.log(config);
  return config;
}

var config = loadConfig();

function authenticate(code, cb) {
  var data = qs.stringify({
    client_id: config.oauth_client_id,
    client_secret: config.oauth_client_secret,
    code: code
  });

  var reqOptions = {
    host: config.oauth_host,
    port: config.oauth_port,
    path: config.oauth_path,
    method: config.oauth_method,
    headers: { 'content-length': data.length }
  };

  var body = "";
  var req = https.request(reqOptions, function(res) {
    res.setEncoding('utf8');
    res.on('data', function (chunk) { body += chunk; });
    res.on('end', function() {
      cb(null, qs.parse(body).access_token);
    });
  });

  req.write(data);
  req.end();
  req.on('error', function(e) { cb(e.message); });
}


// Convenience for allowing CORS on routes - GET only
app.all('*', function (req, res, next) {
  res.header('Access-Control-Allow-Origin', '*'); 
  res.header('Access-Control-Allow-Methods', 'GET, OPTIONS'); 
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

app.get('/authenticate/:code', function(req, res) {
  console.log('authenticating code:' + req.params.code);
  authenticate(req.params.code, function(err, token) {
    var result = err || !token ? {"error": "bad_code"} : { "token": token };
    console.log(result);
    res.json(result);
  });
});

app.use(express.static(__dirname + '/public'));

mongo.connect("mongodb://localhost:27017/learnlocity", function(err, db) {
  msgs = db.collection('msg');

  io.sockets.on('connection', function(socket) {
    socket.on('msg', function(msg) {
      var decoratedMessage = decorateMessage(msg);
      socket.broadcast.emit("msg", decoratedMessage);
      msgs.insert(decoratedMessage, function(err, result) {
        if (err) {
          console.log('Error:');
          console.log(err);
        }
      });
    });
    socket.on('query', function(query, callback) {
      console.log('query is:');
      console.log(query);
       msgs.find(query).toArray(function(err, items) {
        if (err) {
          console.log('Error:');
          console.log(err);
        } else {
          callback(items);
        }
       });
    });
    socket.on('queryMissionUsersNow', function(mission, callback) {
      console.log('queryMissionUsersNow is:');
      console.log(mission);

      var now = new Date();
      var since = new Date(now - 1*60*1000);

      // TODO: better to aggregate or reduce in mongo than in underscore
      var query = {
        $or: [
          {
            mission: mission,
            type: 'mission.join',
            timestamp:{ $gte:since}
          },
          {
            mission: mission,
            type: 'mission.leave',
            timestamp:{ $gte:since}
          }
        ]
      };

      msgs.find(query).sort({timestamp:-1}).toArray(function(err, items) {
        if (err) {
          console.log('Error:');
          console.log(err);
        } else {
          var userGroups = _.groupBy(items, function(item) { return item.userName; });
          var mostRecents = _.map(userGroups, function(item) { return item[0] });
          var joins = _.chain(mostRecents).where({type:'mission.join'}).pluck('userName').value();
          var leaves = _.chain(mostRecents).where({type:'mission.leave'}).pluck('userName').value();
          var keeps = _.difference(joins, leaves);
          var missionUsersNow = _.filter(mostRecents, function(item) { return _.contains(keeps, item.userName) } );
          var response = {
            mission: mission,
            items: missionUsersNow
          };
          callback(response);
        }
       });
    });    
  }); 
});

var port = process.env.PORT || config.port || 80;

server.listen(port, null, function (err) {
  console.log('Learnlocity server listening at your service: http://localhost:' + port);
});
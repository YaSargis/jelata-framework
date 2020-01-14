path = require('path'),
rootFolder = path.resolve(__dirname),
http    = require( 'http'         ),
express = require( 'express'      ),
app     = express(),
REQUEST = new Date().getTime(),
server  = http.createServer( app ),
xlsx 	 = require('./xlsx')

server.listen(12317)
	
server.on('connection', function(socket) {
	socket.setTimeout(1000000); 
})
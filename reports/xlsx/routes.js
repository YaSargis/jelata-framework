var util = require('util');
var ff = require('fs');
var bodyParser = require('body-parser')

app.use(bodyParser.json({limit: '100mb'}))
app.use(bodyParser.urlencoded({limit: '100mb', extended: true}))

function log(mes){
	// log requests
	var gd = new Date()
	ff.appendFile(rootFolder + '/log.txt','\r\n' + gd+mes, function(err){console.log(err)})
}

// Perform substitution 
var jsonParser = bodyParser.json() 

// create application/x-www-form-urlencoded parser 
var urlencodedParser = bodyParser.urlencoded({ extended: false }) 

app.post( '/report', urlencodedParser,
	function ( request, response ) {
		var data = request.body.data
		var template = request.body.template
		var filename = request.body.filename
		
		if (filename == undefined || filename == null || filename == "None") {
			response.status(500).send({'message':'can not open template file'})
			return
		}
		
		try {	
			ff.readFile(template, function(err, dat) {
				if ( err ) {
					response.status(500).send({'message':'can not open template file'})
					return
				}
				var XlsxTemplate = require('xlsx-template')
				var tmp = new XlsxTemplate(dat)
				
				var sheetNumber = 1
		
				data = JSON.parse(data)
				
				var values = data 
				console.log('values',values)
				if ('outjson' in values) { 
					// for not multipages template				
					tmp.substitute(sheetNumber, values) 
				}
					
				else if ('page1' in values) {
					// for multipages templates
					key = 'page1'
					while (key in values) {
						tmp.substitute(sheetNumber, values[key]) 
						sheetNumber += 1
						key = 'page' + sheetNumber
					}
				} else {
					tmp.substitute(sheetNumber, values) 
				}

				// Get binary data 
				var dat = tmp.generate(),
					dt = require('docxtemplater'),
					doc = new dt(dat)
				
				doc.render()
				output = doc.getZip().generate({type:"nodebuffer"})

				response.setHeader('Cache-Control', 'public')
				response.setHeader('Content-Description', 'File Transfer')
				response.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')	
				response.setHeader('Content-disposition', 'attachment; filename=' + (filename || "rep.xlsx") )
				
				response.header('Content-Transfer-Encoding', 'binary')
				response.header("Content-Length" , dat.length)
				response.send(output)
				
				delete dt, XlsxTemplate, tmp, dat, output
			});	
		} catch (e) {
			console.error(e.message)
		}
	}
);


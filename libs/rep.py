from os import system
from json import loads, dumps
import urllib.request, urllib.error
from psycopg2 import extras
from uuid import uuid4
from tornado import gen
from tornado.httpclient import HTTPRequest, AsyncHTTPClient, HTTPError

from libs.basehandler import BaseHandler
from libs.service_functions import showError, default_headers, log
from settings import primaryAuthorization, reports_url
from io import StringIO
from xlsx2html import xlsx2html



@gen.coroutine		
def Report(self, url):
	"""
		Function for call node js report method and get xls or xlsx file
	"""
	args = {} #variable for arguments or body
	report_path = url[4:] #cut 4 symbols from url start, work only if it will be rep/
	sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie

	log(url, 'args: ' + str(self.request.arguments) + 
			'; sess: ' + sesid + '; type: 1')		
	if primaryAuthorization == "1" and sesid == '':
		self.set_status(401,None)
		self.write('{"message":"No session"}')
		return
	args = self.request.arguments 
	for k in args:
		args[k] = args.get(k)[0].decode('utf-8')
	if args.get('filename') is None:
		showError('{"message":"filename is empty"}', self)
		return
	injson = {'injson':args, 'sess':sesid, 'report_path':report_path}
	
	squery = 'select * from reports.fn_call_report(injson:=%s)'
	result = None
	try:
		result = yield self.db.execute(squery,(extras.Json(injson),))
	except Exception as e:
		log(url + '_Error',' args: ' + 
			str(extras.Json(args)) + '; sess: ' + 
			sesid + '; type: 1; Error:' + str(e))
		showError(str(e), self)
		return
	
	res = result.fetchone()[0]	
	data = res.get('outjson')

	reqBody = {'template':'..' + res.get('template_path'),'data':dumps(data), 'filename':args.get('filename')}
	
	http_client =  AsyncHTTPClient();
	req = HTTPRequest(
		url=reports_url,
		method='POST',
		headers={'Content-Type':'application/json'},
		body=dumps(reqBody),
		connect_timeout=200.0,
		request_timeout=200.0
	);	
	try:
		req = yield http_client.fetch(req)
	except HTTPError as e:
		if e.response and e.response.body:
			e = e.response.body.decode('utf-8')
		log(url + '_Error_NodeJs',' args: ' + 
			str(extras.Json(args)) + '; sess: ' + 
			sesid + '; type: 1; Error:' + str(e))
		showError(str(e), self)
		return
	except Exception as err:	
		system('cd reports && node index.js') # try start reports server
		try:
			req = yield http_client.fetch(req)
		except Exception as err:
			showError('No connection to the report server',self)
			return 
		
	if res.get('ishtml'):
		html_report = StringIO()
		reportFilePath = './files/' + str(uuid4()) + '.xlsx'
		reportFile = open(reportFilePath, 'wb')
		reportFile.write(req.buffer.read())
		reportFile.close()
		html = xlsx2html(reportFilePath, html_report)
		html_report.seek(0)
		html_report = html_report.read()
		self.set_header('Content-Type', 'text/html')
		html_report += (
			'<script>window.print()</script>' + 
			'<style type="text/css" media="print">' +
			'@page { size: auto;  margin: 0mm; } </style>'
		)
		self.write(html_report)
	else:
		self.set_header('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
		self.set_header('Cache-Control', 'public')
		self.set_header('Content-Disposition', 'attachment; filename=' + args.get('filename') + '.xlsx')
		self.set_header('Content-Description', 'File Transfer')
		self.write(req.body)
	self.set_status(200)
	

class Reporter(BaseHandler):
	"""
		Universal reports 
	"""
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		
		
	@gen.coroutine		
	def get(self, url):
		yield Report(self,url)
	


from json import loads, dumps
import urllib.request, urllib.error
from psycopg2 import extras
from tornado import gen
from tornado.httpclient import HTTPRequest, AsyncHTTPClient, HTTPError

from libs.basehandler import BaseHandler
from libs.service_functions import showError, default_headers, log
from settings import primaryAuthorization


@gen.coroutine		
def Report(self, url):
	"""
		Function for call node js report method and get xls or xlsx file
	"""
	args = {} #variable for arguments or body
	report_path = url[4:] #cut 4 symbols from url start, work only if it will be rep/
	sesid = self.get_cookie("sesid") or ''	#get session id cookie

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
	
	squery = "select * from reports.fn_call_report(injson:=%s)"
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

	reqBody = {'template':".." + res.get("template_path"),'data':dumps(data), 'filename':args.get('filename')}
	
	http_client =  AsyncHTTPClient();
	req = HTTPRequest(
		url="http://127.0.0.1:12317/report",
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
			e = e.response.body.decode("utf-8")
		log(url + '_Error_NodeJs',' args: ' + 
			str(extras.Json(args)) + '; sess: ' + 
			sesid + '; type: 1; Error:' + str(e))
		showError(str(e), self)
		return
	self.set_header('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
	self.set_header('Cache-Control', 'public')
	self.set_header('Content-Disposition', 'attachment; filename=' + args.get('filename') + '.xlsx')
	self.set_header('Content-Description', 'File Transfer')
	self.write(req.body)
	self.set_status(200)
	self.finish()

class Reporter(BaseHandler):
	"""
		Universal reports 
	"""
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
		
	@gen.coroutine		
	def get(self, url):
		yield Report(self,url)
	


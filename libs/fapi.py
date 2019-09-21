from uuid import uuid4
from json import loads, dumps
from psycopg2 import extras
from tornado import gen

from libs.basehandler import BaseHandler
from libs.service_functions import showError, default_headers, log
from settings import maindomain, primaryAuthorization

def savefile(self):
	"""
		save files
	"""
	files = self.request.files
	value = []
	x = True
	i = 0
	if 'file_0' not in files:
		self.set_status(500,None)
		self.write('{"message":"file not found (file_0)"}')
		return
	while x:
		file = files.get('file_'+str(i))
		if not file:
			x = False
		else:
			file = file[0]
			bfile = file.body
			bfname = str(uuid4()) + file.filename
			value.append({'thumbnail':maindomain + '/files/' + bfname,
				'original':maindomain + '/files/' + bfname,
				'src':maindomain + '/files/' + bfname,
				'thumbnailWidth':100,
				'thumbnailHeight':100,
				'uri':'/files/' + bfname,
				'filename':file.filename, 
				'content_type':file.content_type, 
				'size':len(bfile)})
			xf = open('./files/' + bfname,'wb')
			xf.write(bfile)
			xf.close()
		i += 1
	
	return value
	
@gen.coroutine		
def onRequest(self, url, type):
	"""
		Function for get,post,put and delete requests on universal api (for class FApi)
	"""
	args = {} #variable for arguments or body
	method = url[4:] #cut 4 symbols from url start, work only if it will be api/
	files = [] #variable for files
	sesid = self.get_cookie("sesid") or ''	#get session id cookie
	if type != 1 and self.request.headers.get('Content-Type').find('multipart/form-data') == -1:
		log(url, 'args: ' + str(self.request.arguments) + '; body: ' + str(self.request.body.decode('utf-8')) + 
			'; sess: ' + sesid + '; type: ' + str(type))
	else:
		log(url, 'args: ' + str(self.request.arguments) + 
			'; sess: ' + sesid + '; type: ' + str(type))		
	if primaryAuthorization == "1" and sesid == '':
		self.set_status(401,None)
		self.write('{"message":"No session"}')
		return
	args = self.request.arguments 
	for k in args:
		args[k] = args.get(k)[0].decode('utf-8')
		
	if type in (2,4):
		files = self.request.files#.get("files") #get request files	
		body = {}

		if files:
			value = args.get('value') 
			if not value:
				value = '[]'
			value = loads(value)
			value = value + savefile(self)
			args['value'] = dumps(value)
		else:	
			body = loads(self.request.body.decode('utf-8')) #request body, expecting application/json type
			
		for k in args:
			body[k] = args.get(k)
			
		args = body	
		for k in args:
			if args[k] == "":
				args[k] = None
	squery = "select * from framework.fn_fapi(injson:=%s,apititle:=%s,apitype:=%s,sessid:=%s,primaryauthorization:=%s)"
	result = None
	try:
		result = yield self.db.execute(squery,(extras.Json(args),method,str(type),sesid,primaryAuthorization,))
	except Exception as e:
		log(url + '_Error',' args: ' + 
			str(extras.Json(args)) + '; sess: ' + 
			sesid + '; type: ' + str(type) + '; Error:' + str(e))
		showError(str(e), self)
		return

	result = result.fetchone()[0]	
	self.set_header("Content-Type",'application/json charset="utf-8"')
	self.write(dumps(result, indent=4, default=lambda x:str(x),ensure_ascii=False))
	self.set_status(200,None)	
	self.finish()

class FApi(BaseHandler):
	"""
		Universal API for all methods except authentication
	"""
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
	@gen.coroutine		
	def get(self, url):
		yield onRequest(self,url,1)
	@gen.coroutine		
	def post(self, url):
		yield onRequest(self,url,2)
	@gen.coroutine		
	def put(self, url):
		yield onRequest(self,url,3)
	@gen.coroutine		
	def delete(self, url):
		yield onRequest(self,url,4)

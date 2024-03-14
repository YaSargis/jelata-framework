from os import listdir
from json import loads, dumps, load
from tornado import gen
from psycopg2 import extras

from libs.basehandler import BaseHandler
from libs.service_functions import showError, default_headers, log
from settings import primaryAuthorization, developerRole

class Admin(BaseHandler):
		def set_default_headers(self):
			default_headers(self)

		def options(self,url):
			self.set_status(200,None)
			self.finish()
					
		@gen.coroutine
		def get(self, url): 
			sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
			if primaryAuthorization == '1' and sesid is None:
				self.set_status(401,None)
				self.write('{"message":"No session"}')
				return
			squery = 'select * from framework.fn_userjson(%s)'
			userdetail = []
			try:
				userdetail = yield self.db.execute(squery,(sesid,))
			except Exception as e:				
				showError(str(e), self)
				log('/admin/getsettings_Error',str(e))
				return	
			userdetail = userdetail.fetchone()[0]	
			
			if userdetail is None:
				self.set_status(401,None)
				self.write('{"message":"no session or session was killed"}')
				return
			roles = userdetail.get('roles')

			if int(developerRole) not in roles:
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return
			settingsFile = {}
			try:
				df = open('./settings.json') 
				settingsFile = load(df)
				df.close()
			except Exception as e:
				showError(str(e), self)
				log('/admin/getsettings_Error',str(e))
				return
			squery = 'select * from framework.fn_mainsettings_save(%s)'
			try:
				userdetail = yield self.db.execute(squery,(extras.Json(settingsFile),))
			except Exception as e:				
				showError(str(e), self)
				return	
			
			log('/admin/getsettings','settingsFile: ' + str(settingsFile) + ' userdetail: ' + str(userdetail))	
			self.write('{"message":"OK"}')
			
		@gen.coroutine	
		def post(self, url):
			sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
			if primaryAuthorization == '1' and sesid is None:
				self.set_status(401,None)
				self.write('{"message":"No session"}')
				return
			squery = 'select * from framework.fn_userjson(%s)'
			userdetail = []
			try:
				userdetail = yield self.db.execute(squery,(sesid,))
			except Exception as e:				
				showError(str(e), self)
				return	
			userdetail = userdetail.fetchone()[0]	
			if userdetail is None:
				self.set_status(401,None)
				self.write('{"message":"no session or session was killed"}')
				return
			roles = userdetail.get('roles')

			if int(developerRole) not in roles:
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return
			body = loads(self.request.body.decode('utf-8')) 
			#settingsFile = body.get('settings')
			settingsFile = body

			squery = 'select * from framework.fn_mainsettings_save(%s)'
			
			try:
				userdetail = yield self.db.execute(squery,(extras.Json(settingsFile),))
			except Exception as e:				
				showError(str(e), self)
				return	
			if settingsFile:
				try:
					df = open('./settings.json','wt') 
					df.write(dumps(settingsFile))
					df.close()
					
					df = open('./settings.py','at')
					df.write(' ')
					df.close
				except Exception as e:
					showError(str(e), self)
					return
			log('/admin/savesettings',' settingsFile:' + str(settingsFile) + ' userdetail: ' + str(userdetail))		
			self.write('{"message":"OK"}')

class Logs(BaseHandler):
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
					
	@gen.coroutine
	def get(self, url):
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
		if primaryAuthorization == '1' and sesid is None:
			self.set_status(401,None)
			self.write('{"message":"No session"}')
			return
		squery = 'select * from framework.fn_userjson(%s)'
		userdetail = []
		try:
			userdetail = yield self.db.execute(squery,(sesid,))
		except Exception as e:				
			showError(str(e), self)
			log('/admin/getsettings_Error',str(e))
			return	
		userdetail = userdetail.fetchone()[0]	
		
		if userdetail is None:
			self.set_status(401,None)
			self.write('{"message":"no session or session was killed"}')
			return
		roles = userdetail.get('roles')
		if int(developerRole) not in roles:
			self.set_status(403,None)
			self.write('{"message":"access denied"}')
			return
		
		args = self.request.arguments
		
		for k in args:
			args[k] = args.get(k)[0].decode('utf-8')			
		
		substr = args.get('substr') or ''
		pagenum = int(args.get('pagenum') or 1) 
		pagesize = int(args.get('pagesize') or 20) 
		off = (pagenum * pagesize) - pagesize
		
		logs = listdir(path = './logs')
		lgs = []
			
		for x in logs:
			if (x.find(substr) != -1):
				lgs.append({'filename':x})
		
		lgs = lgs[off:]
		lgs = lgs[:pagesize]
		self.write(dumps(lgs))
		
class Log(BaseHandler):
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
					
	@gen.coroutine
	def get(self, url):
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
		if primaryAuthorization == '1' and sesid is None:
			self.set_status(401,None)
			self.write('{"message":"No session"}')
			return
		squery = 'select * from framework.fn_userjson(%s)'
		userdetail = []
		try:
			userdetail = yield self.db.execute(squery,(sesid,))
		except Exception as e:				
			showError(str(e), self)
			log('/admin/getsettings_Error',str(e))
			return	
		userdetail = userdetail.fetchone()[0]	
		
		if userdetail is None:
			self.set_status(401,None)
			self.write('{"message":"no session or session was killed"}')
			return
		roles = userdetail.get('roles')
		if int(developerRole) not in roles:
			self.set_status(403,None)
			self.write('{"message":"access denied"}')
			return
		
		args = self.request.arguments
		
		for k in args:
			args[k] = args.get(k)[0].decode('utf-8')	
		
		filename = args.get('filename')
		
		if filename is None:
			self.set_status(500,None)
			self.write('{"message":"enter filename"}')
			return
			
		filepath = './logs/' + filename	
		f = open(filepath,encoding='utf-8')
		file_text = f.read()
		f.close()
		
		file_arr = file_text.split('\n')
		res_json = []
		
		for x in file_arr:
			if x.find('||') != -1:
				res_json.append({'log_line': x})
			else:
				index = len(res_json) - 1
				if index >= 0:
					res_json[index] = {'log_line':res_json[index].get('log_line') + ' || ' + x}
		
		
		self.write(dumps(res_json))
		

class CSS(BaseHandler):
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
					
	@gen.coroutine
	def post(self, url):
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
		if primaryAuthorization == '1' and sesid is None:
			self.set_status(401,None)
			self.write('{"message":"No session"}')
			return
		squery = 'select * from framework.fn_userjson(%s)'
		userdetail = []
		try:
			userdetail = yield self.db.execute(squery,(sesid,))
		except Exception as e:				
			showError(str(e), self)
			return	
		userdetail = userdetail.fetchone()[0]	
		if userdetail is None:
			self.set_status(401,None)
			self.write('{"message":"no session or session was killed"}')
			return
		roles = userdetail.get('roles')
		if int(developerRole) not in roles:
			self.set_status(403,None)
			self.write('{"message":"access denied"}')
			return
			
		css_file = open('./user.css','rt')	
		css_text = css_file.read()
		css_file.close()
		squery = 'select * from framework.fn_mainsettings_usercss(%s)'
		result = None
		try:
			result = yield self.db.execute(squery,(css_text,))
		except Exception as e:				
			showError(str(e), self)
			return	
		
		self.write('{"message":"OK"}')
		
	
	@gen.coroutine
	def put(self, url):
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
		if primaryAuthorization == '1' and sesid is None:
			self.set_status(401,None)
			self.write('{"message":"No session"}')
			return
		squery = 'select * from framework.fn_userjson(%s)'
		userdetail = []
		try:
			userdetail = yield self.db.execute(squery,(sesid,))
		except Exception as e:				
			showError(str(e), self)
			return	
		userdetail = userdetail.fetchone()[0]	
		if userdetail is None:
			self.set_status(401,None)
			self.write('{"message":"no session or session was killed"}')
			return
		roles = userdetail.get('roles')
		if int(developerRole) not in roles:
			self.set_status(403,None)
			self.write('{"message":"access denied"}')
			return
			
		body = loads(self.request.body.decode('utf-8')) 
		css_text = body.get('usercss')
		
		if css_text is None:
			self.set_status(500,None)
			self.write('{"message":"text is empty"}')
			return
		
		css_file = open('./user.css','wt')	
		css_text = css_file.write(css_text)
		css_file.close()
		
		'''squery = 'select * from framework.fn_mainsettings_usercss(%s)'
		result = None
		try:
			result = yield self.db.execute(squery,(css_text,))
		except Exception as e:				
			showError(str(e), self)
			return	'''
		
		self.write('{"message":"OK"}')
		
		

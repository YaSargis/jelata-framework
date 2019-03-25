from json import loads, dumps, load
from tornado import gen

from basehandler import BaseHandler
from service_functions import showError, default_headers, log
from settings import primaryAuthorization, developerRole

class Admin(BaseHandler):
		def set_default_headers(self):
			default_headers(self)

		def options(self,url):
			self.set_status(200,None)
			self.finish()
					
		@gen.coroutine
		def get(self, url): 
			sesid = self.get_cookie("sesid") or ''	#get session id cookie
			if primaryAuthorization == "1" and sesid is None:
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
				settingsFile = dumps(load(df))
				df.close()
			except Exception as e:
				showError(str(e), self)
				log('/admin/getsettings_Error',str(e))
				return
			log('/admin/getsettings','settingsFile: ' + str(settingsFile) + '; userdetail: ' + str(userdetail))	
			self.write(settingsFile)
			
		@gen.coroutine	
		def post(self, url):
			sesid = self.get_cookie("sesid") or ''	#get session id cookie
			if primaryAuthorization == "1" and sesid is None:
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
			settingsFile = body.get('settings')
			sesid = self.get_cookie("sesid") or ''	#get session id cookie
			if primaryAuthorization == "1" and sesid is None:
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
			if settingsFile:
				try:
					df = open('./settings.json','wt') 
					df.write(dumps(settingsFile))
					df.close()
				except Exception as e:
					showError(str(e), self)
					return
			log('/admin/savesettings',' settingsFile:' + str(settingsFile) + '; userdetail: ' + str(userdetail))		
			self.write(settingsFile)
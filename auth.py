from json import loads
from hashlib import sha224
from tornado import gen

from basehandler import BaseHandler
from service_functions import showError, default_headers, log

class Auth(BaseHandler):
	"""
		Authorization methods
	"""
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		
	@gen.coroutine
	def post(self, url):
		method = url[5:] #cut 4 symbols from url start, work only if it will be auth/
		log(url,str(self.request.body))
		if method == "logout":
			sesid = self.get_cookie("sesid")
			if sesid:
				squery = "select * from framework.fn_logout(%s)"
				result = None
				try:
					result = yield self.db.execute(squery,(sesid,))
				except Exception as e:
					showError(str(e), self)
					log(url + '_Error',str(e))
					return	
				self.clear_cookie("sesid")	
			self.write('{"message":"OK"}')
			
		elif method == "auth_f":
			body = loads(self.request.body.decode('utf-8'))
			
			login = body.get('login')
			passw = body.get('pass')
			passw = sha224(passw.encode('utf-8')).hexdigest()
			
			if login is None or passw is None:
				self.write('{"message":"login or password is null"}')
				self.set_status(500,None)
				return
				
			squery = 'select * from framework.fn_sess(%s,%s);'
			try:
				result = yield self.db.execute(squery,(login,passw,))
			except Exception as e:
				showError(str(e), self)
				log(url + '_Error',str(e))
				return
			result = result.fetchone()[0]
			self.set_cookie("sesid", result)	
			self.write('{"message":"OK"}')		
		else:	
			self.set_status(404,None)
			self.write('{"message":"method not found"}')
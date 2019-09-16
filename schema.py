from json import loads, dumps
from tornado import gen
from basehandler import BaseHandler
from sql_migration import getList
from service_functions import showError, default_headers, curtojson, log
from settings import primaryAuthorization, developerRole

class Schema(BaseHandler):
	"""
		for SQL query build methods
	"""
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
				
	@gen.coroutine	
	def post(self, url):
		args = self.request.arguments 
		for k in args:
			args[k] = args.get(k)[0].decode('utf-8') 
		path = args.get('path')
		if path is None:
			showError("HINT:path not specified +++___", self)
			return
		body = loads(self.request.body.decode('utf-8')) 

		method = url[7:].replace('/','').lower()
		sesid = self.get_cookie("sesid") or ''	#get session id cookie
		log(url, 'path: '+ path + '; body: ' +str(body) + ' sessid:' + str(sesid) )

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
		#userdetail = userdetail.get('outjson')	
		if method == 'list':
			squery = """SELECT row_to_json (d) FROM (select * 
						from framework.views 
						where path = %s and viewtype in ('table', 'tiles') ) as d"""			
			result = []
			try:
				result = yield self.db.execute(squery,(path,))
			except Exception as e:				
				showError(str(e), self)
				return
			result = result.fetchone()
			if not result:
				self.set_status(500,None)
				self.write('{"message":"view is not found"}')
				return
			result = result[0]	
			if len(result.get('roles')) > 0:
				x = False
			else:
				x = True
			for col in result.get('roles'):
				if col.get("value") in userdetail.get('roles') and not x:
					x = True
			if not x:	
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return	
			user = {}
			if body.get('print'):
				result['pagination'] = False
				user['fam'] = userdetail.get('fam')
				user['im'] = userdetail.get('im')
				user['ot'] = userdetail.get('ot')
			query = getList(result,body, userdetail=userdetail)	
			squery = query[0]
			scounquery = query[1]
			data = []
			try:
				data = yield self.db.execute(squery)
			except Exception as e:				
				showError(str(e), self)
				log(url + '_Error', str(e))
				return
			
			data = curtojson([x for x in data],[x[0] for x in data.description])	
			count = 0
			try:
				count = yield self.db.execute(scounquery)
			except Exception as e:				
				showError(str(e), self)
				log(url + '_Error_count', str(e))
				return
			
			count = count.fetchone()[0]

			self.write(dumps({
								'foundcount':count, 
								'data':data, 
								'config':result.get('config'), 
								'filters':result.get('filters'),
								'acts':result.get('acts'),
								'classname':result.get('classname'),
								'table':result.get('tablename'),
								'title':result.get('title'),
								'viewtype':result.get('viewtype'),
								'pagination':result.get('pagination'),
								'ispagecount':result.get('pagecount'),
								'ispagesize':result.get('ispagesize'),
								'isfoundcount':result.get('foundcount'),
								'subscrible':result.get('subscrible'),
								'isorderby':result.get('orderby'),
								'viewid':result.get('id'),
								'checker':result.get('checker'),
								'user':user
							}))
			
		elif method == 'getone':
			squery = """SELECT row_to_json (d) FROM (select * 
						from framework.views 
						where path = %s and viewtype in ('form full', 'form not mutable') ) as d"""			
			result = []
			try:
				result = yield self.db.execute(squery,(path,))
			except Exception as e:				
				showError(str(e), self)
				return
			result = result.fetchone()
			if not result:
				self.set_status(500,None)
				self.write('{"message":"view is not found"}')
				return
			result = result[0]
			if len(result.get('roles')) > 0:
				x = False
			else:
				x = True
			for col in result.get('roles'):
				if col.get("value") in userdetail.get('roles') and not x:
					x = True
			if not x:	
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return	
			query = getList(result,body, userdetail=userdetail)	
			squery = query[0]
			data = []
			try:
				data = yield self.db.execute(squery)
			except Exception as e:				
				showError(str(e), self)
				log(url + '_Error', str(e))
				return
			
			data = curtojson([x for x in data],[x[0] for x in data.description])	
			if len(data)>1:
				self.set_status(500,None)
				self.write('{"message":"getone can\'t return more then 1 row"}')
				return
			#count = count.fetchone()[0]
			self.set_status(200,None)
			self.write(dumps({
								'data':data, 
								'config':result.get('config'), 
								'acts':result.get('acts'),
								'classname':result.get('classname'),
								'table':result.get('tablename'),
								'subscrible':result.get('subscrible'),
								'title':result.get('title'),
								'viewtype':result.get('viewtype'),
								'id':result.get('id')
							}))
		elif method == 'squery':
			squery = """SELECT row_to_json (d) FROM (select * 
						from framework.views where path = %s) as d"""			
			result = []
			roles = userdetail.get('roles')
			if int(developerRole) not in roles:
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return
			try:
				result = yield self.db.execute(squery,(path,))
			except Exception as e:				
				showError(str(e), self)
				log(url + '_Error', str(e))
				return
			result = result.fetchone()
			if not result:
				self.set_status(500,None)
				self.write('{"message":"view is not found"}')
				return
			result = result[0]
			#self.write(dumps(result))
			query = getList(result,body, userdetail=userdetail)	
			squery = query[0]
			self.write(dumps({'squery':squery + "; "}))
		else:
			self.set_status(404,None)
			self.write('{"message":"method not found"}')
			return

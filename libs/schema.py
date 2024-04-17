from json import loads, dumps
from tornado import gen
from tornado.httpclient import HTTPError, HTTPRequest, AsyncHTTPClient
from libs.basehandler import BaseHandler
from libs.sql_migration import getList
from libs.service_functions import showError, default_headers, curtojson, log
from settings import primaryAuthorization, developerRole, maindomain

AsyncHTTPClient.configure('tornado.simple_httpclient.SimpleAsyncHTTPClient', max_clients=1000)
http_client =  AsyncHTTPClient()


class Schema(BaseHandler):
	'''
		for SQL query build methods
	'''
	def set_default_headers(self):
		default_headers(self)

	def options(self,url):
		self.set_status(200,None)
		self.finish()
	
	@gen.coroutine	
	def get(self, url):
		args = self.request.arguments
		for k in args:
			args[k] = args.get(k)[0].decode('utf-8')
		
		path = args.get('path')
		if path is None:
			showError('HINT:path not specified +++___', self)
			return
		
		method = url[7:].replace('/','').lower()
		
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
		userdetail['sessid'] = sesid
		squery = 'SELECT framework."fn_view_getByPath_showSQL"(%s)'

		result = []
		roles = (userdetail.get('roles') or [])
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
		query = getList(result, {}, userdetail=userdetail)
		squery = query[0]
		self.write(squery)		
	@gen.coroutine
	def post(self, url):
		args = self.request.arguments
		for k in args:
			args[k] = args.get(k)[0].decode('utf-8')
		path = args.get('path')
		if path is None:
			showError('HINT:path not specified +++___', self)
			return
		body = loads(self.request.body.decode('utf-8'))

		method = url[7:].replace('/','').lower()
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')	#get session id cookie
		#log(url, 'path: '+ path + '; body: ' + str(body) + ' sessid:' + str(sesid) )

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
		userdetail['sessid'] = sesid
		#userdetail = userdetail.get('outjson')
		if method == 'list':

			squery = 'SELECT framework."fn_view_getByPath"(%s,%s)'
			result = []
			try:
				result = yield self.db.execute(squery,(path,'list',))
			except Exception as e:
				showError(str(e), self)
				return
	
			result = result.fetchone()[0]
			if not result:
				self.set_status(500,None)
				self.write('{"message":"view is not found"}')
				return
			#result = result[0]
			if len(result.get('roles')) > 0:
				x = False
			else:
				x = True
			for col in result.get('roles'):
				if col.get('value') in (userdetail.get('roles') or []) and not x:
					x = True
			if not x:
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return
			user = {}
			
			# if exist initial action onLoad
			actions = result.get('acts')
			onLoad = None

			for act in actions:
				if act.get('type') == 'onLoad':
					onLoad = act
			
			if onLoad:
				req_url = onLoad.get('act')
				if 'inputs' in body and onLoad.get('parametrs') is not None:
					req_url += '?'
					for param in onLoad.get('parametrs'):
						req_url += param.get('paramtitle') + '=' + (str(body.get('inputs').get(param.get('paraminput')) or '') ) + '&'
				if req_url[:4] != 'http':
					req_url = maindomain + req_url
					
				if onLoad.get('actapitype').lower() == 'get':
					req = HTTPRequest(
						url = req_url,
						method = onLoad.get('actapitype'),
						headers = {'Cookie':'sesid=' + sesid}
					)
				else:
					req_body = {}
					if onLoad.get('parametrs') is not None:
						for param in onLoad.get('parametrs'):
							req_body[param.get('paramtitle')] = body.get('inputs').get(param.get('paraminput'))
					req = HTTPRequest(
						url = req_url,
						body = dumps(req_body),
						method = onLoad.get('actapitype'),
						headers = {'Cookie':'sesid=' + sesid}
					)
				try:
					response = yield http_client.fetch(req)
				except HTTPError as e:
					if e.response and e.response.body:
						e = e.response.body.decode('utf-8')
					showError(str(e), self)
					log(req_url + '_Error_onLoad', str(e))
					log(req_url + '_Error_act', str(onLoad))
					return
			# if exist initial action onLoad
			data = []
			count = 0
			config = result.get('config')
			filters = result.get('filters')
			acts = result.get('acts')
			title = result.get('title')
			classname = result.get('classname')
			pagination = result.get('pagination')
			pagecount = result.get('pagecount')
			ispagesize = result.get('ispagesize')
			rmnu = result.get('rmnu')
			isfoundcount = result.get('isfoundcount')
			subscrible = result.get('subscrible')
			orderby = result.get('orderby')
			checker = result.get('checker')
			if result.get('viewtype').find('api_') == -1:
				query = getList(result, body, userdetail=userdetail)
				acts = result.get('acts')
				config = result.get('config')
				squery = query[0]
				scounquery = query[1]
				
				try:
					data = yield self.db.execute(squery)
				except Exception as e:
					showError(str(e), self)
					log(url + '_query', squery)
					log(url + '_Error', str(e))
					return

				data = curtojson([x for x in data],[x[0] for x in data.description])
				
				try:
					count = yield self.db.execute(scounquery)
				except Exception as e:
					showError(str(e), self)
					log(url + '_Error_count', str(e))
					
					return

				count = count.fetchone()[0]
			else:
				req_url = result.get('tablename')
				if req_url[:4] != 'http':
					req_url = maindomain + req_url
				req = HTTPRequest(
					url = req_url,
					body = dumps(body),
					method = 'POST',
					headers = {'Cookie': ( self.request.headers.get('Cookie') or '') + '; sesid=' + sesid }
				)
				try:
					response = yield http_client.fetch(req)
				except HTTPError as e:
					if e.response and e.response.body:
						e = e.response.body.decode('utf-8')
					showError(str(e), self)
					log(req_url + ' api error', str(e))
					log(url + '_error_act', str(onLoad))
					return
				data = loads(response.body.decode('utf-8'))
				if data is not None:
					if 'foundcount' in data:
						count = data.get('foundcount')
					else:
						count = None

					if 'config' in data and data.get('config') is not None:
						config = data.get('config')
					
					if 'acts' in data and data.get('acts') is not None:
						acts = data.get('acts')

					if 'filters' in data and data.get('filters') is not None:
						filters = data.get('filters')
						
					if 'classname' in data:
						classname = data.get('classname')
						
					if 'title' in data:
						title = data.get('title')
						
					if 'pagination' in data:
						pagination = data.get('pagination')

					if 'pagecount' in data:
						pagecount = data.get('pagecount')
						
					if 'ispagesize' in data:
						ispagesize = data.get('ispagesize')
						
					if 'isfoundcount' in data:
						isfoundcount = data.get('isfoundcount')
					
					if 'rmnu' in data:
						rmnu = data.get('rmnu')
						
					if 'subscrible' in data:
						subscrible = data.get('subscrible')
						
					if 'orderby' in data:
						orderby = data.get('orderby')
						
					if 'checker' in data:
						checker = data.get('checker')
						
					if 'outjson' in data:
						data = data.get('outjson')

				else:
					data = []
				useroles = userdetail.get('roles') or []
				if acts:
					filteredActs = []
					for act in acts:
						if 'roles' in act and len(act.get('roles')) > 0:
							fAct = []
							for obj in act.get('roles'):
								fAct.append(obj.get('value'))	
								fAct.append(developerRole)
							if len(list(set(fAct) & set(useroles))) > 0:
								filteredActs.append(act)
						else:
							filteredActs.append(act)
					acts = filteredActs
				if count is None:
					count = len(data)
				
			self.write(dumps({
				'foundcount': count, 'data': data, 'config': config, 'filters': filters, 'acts': acts, 
				'classname': classname, 'title': title, 'viewtype': result.get('viewtype'), 'pagination': pagination, 
				'ispagecount': pagecount, 'ispagesize': ispagesize, 'isfoundcount': isfoundcount, 'subscrible': subscrible,
				'isorderby': orderby, 'viewid': result.get('id'), 'checker': checker, 'user':user, 'rmnu': rmnu
			}))

		elif method == 'getone':

			squery = 'SELECT framework."fn_view_getByPath"(%s,%s)' 
			result = []
			try:
				result = yield self.db.execute(squery,(path,'getone',))
			except Exception as e:
				showError(str(e), self)
				return
			result = result.fetchone()[0]
			if not result:
				self.set_status(500,None)
				self.write('{"message":"view is not found"}')
				return
			#result = result[0]
			
			if len(result.get('roles')) > 0:
				x = False
			else:
				x = True
			for col in result.get('roles'):
				if col.get('value') in (userdetail.get('roles') or []) and not x:
					x = True
			if not x:
				self.set_status(403,None)
				self.write('{"message":"access denied"}')
				return
				
			# if exist initial action onLoad
			actions = result.get('acts')
			onLoad = None

			for act in actions:
				if act.get('type') == 'onLoad':
					onLoad = act
			
			if onLoad:
				req_url = onLoad.get('act')
				if 'inputs' in body and onLoad.get('parametrs') is not None:
					req_url += '?'
					for param in onLoad.get('parametrs'):
						req_url += param.get('paramtitle') + '=' + (str(body.get('inputs').get(param.get('paraminput')) or '') ) + '&'
				if req_url[:4] != 'http':
					req_url = maindomain + req_url
					
				if onLoad.get('actapitype').lower() == 'get':
					req = HTTPRequest(
						url = req_url,
						method = onLoad.get('actapitype'),
						headers = {'Cookie':'sesid=' + sesid}
					)
				else:
					req_body = {}
					if onLoad.get('parametrs') is not None:
						for param in onLoad.get('parametrs'):
							req_body[param.get('paramtitle')] = body.get('inputs').get(param.get('paraminput'))

					req = HTTPRequest(
						url = req_url,
						body = dumps(req_body),
						method = onLoad.get('actapitype'),
						headers = {'Cookie':'sesid=' + sesid}
					)
				try:
					response = yield http_client.fetch(req)
				except HTTPError as e:
					if e.response and e.response.body:
						e = e.response.body.decode('utf-8')
					showError(str(e), self)
					log(req_url + '_Error_onLoad', str(e))
					log(url + '_Error_act', str(onLoad))
					return
			# if exist initial action onLoad
			data = []
			config = result.get('config')
			filters = result.get('filters')
			acts = result.get('acts')
			title = result.get('title')
			classname = result.get('classname')
			subscrible = result.get('subscrible')
			
			if result.get('viewtype').find('api_') == -1:
				query = getList(result, body, userdetail=userdetail)
				acts = result.get('acts')
				config = result.get('config')
				squery = query[0]
			
				try:
					data = yield self.db.execute(squery)
				except Exception as e:
					showError(str(e), self)
					log(url + '_Error', str(e))
					return

				#xx  = [x for x in data]
				#for x in data.description:
				#	print('x:', x)
				try:
					data = curtojson([x for x in data],[x[0] for x in data.description])
				except Exception as e:
					showError(str(e), self)
					log(url + '_Error_dataparse err:', str(e) + ' squery: ' + squery)
					return
			else:
				req_url = result.get('tablename')
				if req_url[:4] != 'http':
					req_url = maindomain + req_url
				req = HTTPRequest(
					url = req_url,
					body = dumps(body),
					method = 'POST',
					headers = {'Cookie': ( self.request.headers.get('Cookie') or '') + '; sesid=' + sesid }
				)
				try:
					response = yield http_client.fetch(req)
				except HTTPError as e:
					if e.response and e.response.body:
						e = e.response.body.decode('utf-8')
					showError(str(e), self)
					log(req_url + ' api error', str(e))
					log(url + '_error_act', str(onLoad))
					return
				data = loads(response.body.decode('utf-8'))
				if data is not None:
					if 'config' in data and data.get('config') is not None:
						config = data.get('config')
					
					if 'acts' in data and data.get('acts') is not None:
						acts = data.get('acts')

					if 'filters' in data and data.get('filters') is not None:
						filters = data.get('filters')
						
					if 'classname' in data:
						classname = data.get('classname')
						
					if 'title' in data:
						title = data.get('title')
						
					if 'subscrible' in data:
						subscrible = data.get('subscrible')


					if 'outjson' in data:
						data = data.get('outjson')

				else:
					data = []
				useroles = userdetail.get('roles') or []
				if acts:
					filteredActs = []
					for act in acts:
						if 'roles' in act and len(act.get('roles')) > 0:
							fAct = []
							for obj in act.get('roles'):
								fAct.append(obj.get('value'))	
								fAct.append(developerRole)
							if len(list(set(fAct) & set(useroles))) > 0:
								filteredActs.append(act)
						else:
							filteredActs.append(act)
					acts = filteredActs	
			if len(data) > 1:
				self.set_status(500,None)
				self.write('{"message":"getone can\'t return more then 1 row"}')
				return
			#count = count.fetchone()[0]
			self.set_status(200,None)
			self.write(dumps({
				'data': data, 'config': config, 'acts': acts, 'classname': classname,
				'table': result.get('tablename'), 'subscrible': subscrible,
				'title': title, 'viewtype': result.get('viewtype'), 'id': result.get('id')
			}))
		elif method == 'squery':
			squery = '''
				SELECT row_to_json (d) 
				FROM (
					SELECT *
					FROM framework.views where path = %s
				) as d
			'''
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
			query = getList(result, body, userdetail=userdetail)
			squery = query[0]
			self.write(dumps({'squery':squery + '; '}))
		else:
			self.set_status(404,None)
			self.write('{"message":"method not found"}')
			return

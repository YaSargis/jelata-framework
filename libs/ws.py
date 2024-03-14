from json import loads, dumps
from time import sleep
from psycopg2 import extras
from tornado import gen, websocket
#from tornado.ioloop import PeriodicCallback
from libs.basehandler import BaseHandler
from settings import maindomain, primaryAuthorization
from libs.service_functions import showError, log, default_headers
#import subprocess


class WebSocketViews(websocket.WebSocketHandler, BaseHandler):
	opened = True
	def check_origin(self, origin):
		return True
	def set_default_headers(self):
		default_headers(self)
	@gen.coroutine		
	def on_message(self, message):
		try:
			message = loads(message)
		except Exception as e:
			self.write_message('{"error":"wrong data"}')
			return	

		#log('ws', 'message:' + str(message))
		#print('self.sending', self.opened)
		viewpath = message.get('viewpath')
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')
		if viewpath is None:
			self.write_message('{"error":"view path is None"}')
			return
		
		squery = '''
			SELECT * 
			FROM framework.fn_fapi(injson:=%s,apititle:='notifs',apitype:='1',sessid:=%s,primaryauthorization:=%s)
		'''
		result = None
		oldresult = []

		while self.opened:
			yield gen.sleep(5)
			#print('self.ws_connection', self.ws_connection)		
			try:
				result = yield self.db.execute(squery,( extras.Json(message),sesid,str(primaryAuthorization),))
			except Exception as err:
				err = str(err)
				self.opened = False
				self.write_message('{"error":"' + (err[err.find('HINT:')+5:err.find('+++___')]).split('\n')[0] + '"}')
				self.close()
				return

			result = result.fetchone()[0].get('outjson')
			if len(oldresult) != len(result):
				oldresult = result
				self.write_message(dumps(result))
		self.close()		
		return

	def on_close(self):
		#print('Connection closed')
		#log('ws_closed', 'SUCCESS 1')
		self.opened = False
		#print('self.sending', self.opened)
		self.stream.close()
		self.close()
		#self.finish()			
		return
		

class WebSocketGlobal(websocket.WebSocketHandler, BaseHandler):
	opened = True
	def check_origin(self, origin):
		return True
	def set_default_headers(self):
		default_headers(self)
	@gen.coroutine		
	def on_message(self, message):
		#log('ws_global', 'message:' + str(message))
		#subprocess.run(['ss --tcp state CLOSE-WAIT --kill'], shell=True)
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')
		#print('ws sesid:', sesid)
		squery = '''
			SELECT * 
			FROM framework.fn_notifications_bysess(_sess:=%s)
		'''
		result = None
		oldresult = []
		while self.opened:
			yield gen.sleep(5)			
			try:
				result = yield self.db.execute(squery,(sesid,))
			except Exception as err:
				err = str(err)
				self.opened = False
				self.write_message('{"error":"' + (err[err.find('HINT:')+5:err.find('+++___')]).split('\n')[0] + '"}')
				self.close()
				return

			result = result.fetchone()[0]
			if len(oldresult) != len(result):
				oldresult = result
				self.write_message(dumps(result))
		self.close()			
		return

	def on_close(self):
		#print('Connection closed')
		#log('ws_closed', 'SUCCESS 2')
		self.opened = False
		#print('self.sending', self.opened)
		self.close()
		#self.finish()			
		return
		
class WebSocketMessages(websocket.WebSocketHandler, BaseHandler):
	'''
		Dialogs notifications
	'''
	opened = True
	def check_origin(self, origin):
		return True

	@gen.coroutine		
	def on_message(self, message):
		
		try:
			message = loads(message)
		except Exception as e:
			self.write_message('{"error":"wrong data"}')
			return		

		#log('ws_messages_chats', 'message:' + str(message))
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')
		
		squery = '''
			SELECT * 
			FROM framework.fn_fapi(injson:=%s,apititle:='chats',apitype:='1',sessid:=%s,primaryauthorization:=%s)
		'''
		result = None
		oldresult = None
		while self.opened:
			yield gen.sleep(2)			
			try:
				result = yield self.db.execute(squery,( extras.Json(message),sesid,str(primaryAuthorization),))
			except Exception as err:
				err = str(err)
				self.write_message('{"error":"chats' + (err[err.find('HINT:')+5:err.find('+++___')]).split('\n')[0] + '"}')
				self.close()
				return

			result = result.fetchone()[0].get('outjson')
			if str(oldresult) != str(result):
				oldresult = result
				self.write_message(dumps(result))
		#self.finish()			
		return

	def on_close(self):
		#print('Connection closed')
		#log('ws_closed', 'SUCCESS 3')
		self.opened = False
		#print('self.sending', self.opened)
		self.close()
		#self.finish()			
		return
		
class WebSocketMessageNotifications(websocket.WebSocketHandler, BaseHandler):
	'''
		Dialogs new messages notifications
	'''
	opened = True
	def check_origin(self, origin):
		return True

	@gen.coroutine		
	def on_message(self, message):
		try:
			message = loads(message)
		except Exception as e:
			self.write_message('{"error":"wrong data"}')
			return		
		#log('ws_messages', 'message:' + str(message))
		sesid = self.get_cookie('sesid') or self.request.headers.get('Auth')
		
		squery = "select * from framework.fn_fapi(injson:=%s,apititle:='chats_messages',apitype:='1',sessid:=%s,primaryauthorization:=%s)"
		result = None
		oldresult = None
		while self.opened:
			yield gen.sleep(2)			
			try:
				result = yield self.db.execute(squery,( extras.Json(message),sesid,str(primaryAuthorization),))
			except Exception as err:
				err = str(err)
				self.write_message('{"error":"chats_messages' + (err[err.find('HINT:')+5:err.find('+++___')]).split('\n')[0] + '"}')
				self.close()
				return

			result = result.fetchone()[0].get('outjson')
			if str(oldresult) != str(result):
				oldresult = result
				self.write_message(dumps(result))
		#self.finish()			
		return

	def on_close(self):
		#print('Connection closed')
		#log('ws_closed', 'SUCCESS 4')
		self.opened = False
		#print('self.sending', self.opened)
		self.close()
		#self.finish()			
		return
		
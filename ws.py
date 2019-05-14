from json import loads, dumps
from time import sleep
from psycopg2 import extras
from tornado import gen, websocket
from tornado.ioloop import PeriodicCallback
from basehandler import BaseHandler
from settings import maindomain, primaryAuthorization
from service_functions import showError, log

class WebSocket(websocket.WebSocketHandler, BaseHandler):
	def check_origin(self, origin):
		return True

	@gen.coroutine		
	def on_message(self, message):
		try:
			message = loads(message)
		except Exception as e:
			self.write_message('{"error":"wrong data"}')
			return		
		log('ws', 'message:' + str(message))
		viewpath = message.get('viewpath')
		ids = message.get('ids')
		sesid = self.get_cookie("sesid") or ''
		if viewpath is None:
			self.write_message('{"error":"view path is None"}')
			return
		
		squery = "select * from framework.fn_fapi(injson:=%s,apititle:='notifs',apitype:='1',sessid:=%s,primaryauthorization:=%s)"
		result = None
		oldresult = []
		while True:
			yield gen.sleep(5)			
			try:
				result = yield self.db.execute(squery,( extras.Json(message),sesid,primaryAuthorization,))
			except Exception as err:
				err = str(err)
				self.write_message('{"error":"' + (err[err.find("HINT:")+5:err.find("+++___")]).split("\n")[0] + '"}')
				return

			result = result.fetchone()[0].get('outjson')
			if len(oldresult) != len(result):
				oldresult = result
				self.write_message(dumps(result))
		return

	def on_close(self):
		print("Connection closed")
from tornado import web
from tornado.ioloop import IOLoop
from tornado.httpserver import HTTPServer
from tornado.options import parse_command_line

from momoko import Pool
from settings import poolsize, dsn, port, template

from libs.auth import Auth
from libs.admin import Admin, Logs, Log, CSS
from libs.schema import Schema
from libs.fapi import FApi, UploadFiles
from libs.ws import WebSocketViews, WebSocketMessages, WebSocketMessageNotifications, WebSocketGlobal
from libs.rep import Reporter

tPath = '../jelataframework/template/'

if template is not None and template in ('ant', 'materialize'):
	tPath += template
else:
	tPath += 'ant'

class MainHandler(web.RequestHandler):
	def get(self,url):
		self.render(tPath + '/index.html')


if __name__ == '__main__':
	parse_command_line()
	
	# tornado web application (https://pypi.org/project/tornado/)
	application = web.Application([
		(r'/()', web.StaticFileHandler, {'path':tPath,'default_filename': 'index.html'}),
		(r'/(list.*)', MainHandler),
		(r'/(getone.*)', MainHandler),
		(r'/(calendar.*)', MainHandler),
		(r'/(home.*)', MainHandler),
		(r'/(report.*)', MainHandler),
		(r'/(trees.*)', MainHandler),
		(r'/(composition.*)', MainHandler),
		(r'/(tiles.*)', MainHandler),
		(r'/(login.*)', MainHandler),
		(r'/(logout.*)', MainHandler),
		(r'/(chats.*)', MainHandler),
		(r'/(api.*)', FApi),
		(r'/(upload_file.*)', UploadFiles),
		(r'/(auth.*)', Auth),
		(r'/(schema.*)', Schema),
		(r'/(admin.*)', Admin),
		(r'/(usercss.*)', CSS),
		(r'/(logs.*)', Logs),
		(r'/(log.*)', Log),
		(r'/(rep.*)', Reporter),
		(r'/(ws.*)', WebSocketViews),
		(r'/(global_ws.*)', WebSocketGlobal),
		(r'/(messages.*)', WebSocketMessageNotifications),
		(r'/(chats.*)', WebSocketMessages),
		(r'/(.*.html)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.jpg)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.png)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.svg)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.ttf)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.woff)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.woff2)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.pdf)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.docx)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.doc)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.xls)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.xlsx)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.txt)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.jpeg)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.gif)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.js)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.css)', web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(.*.ttf)', web.StaticFileHandler, {'path':'../jelataframework/'} )

	], debug=True)

	ioloop = IOLoop.instance()
	
	#create connections pool, Pool function from momoko lib (https://pypi.org/project/Momoko/)	
	application.db = Pool(
		dsn=dsn,
		size=poolsize,
		ioloop=ioloop,
	)

	# this is a one way to run ioloop in sync
	future = application.db.connect()
	ioloop.add_future(future, lambda f: ioloop.stop())
	ioloop.start()
	future.result() 

	http_server = HTTPServer(application)
	http_server.listen(port, '')
	ioloop.start()		
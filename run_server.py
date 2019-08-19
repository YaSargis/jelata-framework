from tornado import web
from tornado.ioloop import IOLoop
from tornado.httpserver import HTTPServer
from tornado.options import parse_command_line

from momoko import Pool
from settings import poolsize, dsn, port

from auth import Auth
from admin import Admin
from schema import Schema
from fapi import FApi
from ws import WebSocket

from rep import Reporter

class MainHandler(web.RequestHandler):
    def get(self,url):
        self.render('../jelataframework/index.html')
		
if __name__ == '__main__':
	parse_command_line()
	
	# tornado web application (https://pypi.org/project/tornado/)
	application = web.Application([
		(r"/()", web.StaticFileHandler, {'path':'../jelataframework/',"default_filename": "index.html"}),
		(r"/(list.*)", MainHandler),
		(r"/(getone.*)", MainHandler),
		(r"/(form.*)", MainHandler),
		(r"/(projectsettings.*)", MainHandler),
		(r"/(viewlist.*)", MainHandler),
		(r"/(view.*)", MainHandler),
		(r"/(home.*)", MainHandler),
		(r"/(jdocumentation.*)", MainHandler),
		(r"/(jdocumentation_rus.*)", MainHandler),
		(r"/(trees.*)", MainHandler),
		(r"/(composition.*)", MainHandler),
		(r"/(userorgs.*)", MainHandler),
		(r"/(login.*)", MainHandler),
		(r"/(logout.*)", MainHandler),
		(r"/(newview.*)", MainHandler),
		(r"/(documentation.*)", MainHandler),
		(r"/(empty.*)", MainHandler),
		(r"/(misc.*)", MainHandler),
		(r"/(sigmasource.*)", MainHandler),
		(r"/(charts.*)", MainHandler),
		(r"/(messages.*)", MainHandler),
		(r"/(menus.*)", MainHandler),
		(r"/(overlays.*)", MainHandler),
		(r"/(panels.*)", MainHandler),
		(r"/(data.*)", MainHandler),
		(r"/(sample.*)", MainHandler),
		(r"/(report.*)", MainHandler),
		(r"/(forms.*)", MainHandler),
		(r"/(printlist.*)", MainHandler),
		(r"/(getoneprint.*)", MainHandler),
		(r"/(compo.*)", MainHandler),
		(r"/(.*.html)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.jpg)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.png)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.svg)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.ttf)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.woff)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.woff2)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.pdf)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.docx)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.doc)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.xls)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.xlsx)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.jpeg)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.gif)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.js)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r"/(.*.css)", web.StaticFileHandler, {'path':'../jelataframework/'} ),
		(r'/(api.*)', FApi),
		(r'/(rep.*)', Reporter),
		(r'/(auth.*)', Auth),
		(r'/(schema.*)', Schema),
		(r'/(admin.*)', Admin),
		(r'/(ws.*)', WebSocket)
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
	future.result() # raises exception on connection error

	http_server = HTTPServer(application)
	http_server.listen(port, '')
	ioloop.start()		
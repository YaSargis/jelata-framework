from tornado import web

class BaseHandler(web.RequestHandler):
	'''
		Tornado (https://pypi.org/project/tornado/) request handler class with database connection 
	'''
	@property
	def db(self):
		'''
			return application database object 
		'''
		return self.application.db
	
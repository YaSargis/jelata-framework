from psycopg2 import connect
from settings import maindomain, dsn
from libs.service_functions import curtojson
from requests import post

def test_view_call():
	'''
		Send requests for all views and save result in log file
	'''
	# get views list
	con = connect(dsn)
	cur = con.cursor()
	cur.execute('''
		SELECT 
			*,
			(SELECT c.title
			 FROM framework.config as c
			 WHERE 
				viewid = v.id and 
				c.col = 'id' and not c.related and 
				c.fn is null) as id_title 		
		FROM framework.views as v;''')
	rows = [x for x in cur]
	cols = [x[0] for x in cur.description]
	views = curtojson(rows,cols)
	
	# get developer user session
	cur.execute('''
		SELECT 
			id	
		FROM framework.sess as s
		WHERE s.userid = '1' and killed is null
		LIMIT 1;''')
	rows = [x for x in cur]
	cols = [x[0] for x in cur.description]
	sessions = curtojson(rows,cols)
	sessid = sessions[0].get('id')
	
	
	for view in views:
		view_path = maindomain
		body = {'inputs':{}}
		if (view.get('viewtype')).find('form') != -1:
			view_path += '/schema/getone?path='
			body['inputs'][view.get('id_title')] = '0'
		else:
			view_path += '/schema/list?path='	
			body['pagination'] = {'pagenum':1, 'pagesize':15}
			body['filters'] = {}	
		view_path += view.get('path') 
		
		# copy sesid from framework.sess
		# if authetification failed status
		headers = {'Cookie':'sesid=' + sessid} 
		request_res = post(view_path, json=body, headers=headers) 
		
		print(view_path, request_res.status_code )
	


test_view_call()
from psycopg2 import connect
from settings import maindomain, dsn
from libs.service_functions import curtojson

def test_view_call():
	'''
		Send requests for all views and save result in log file
	'''
	# get views list
	con = connect(dsn)
	cur = con.cursor()
	cur.execute("SELECT * FROM framework.views;")
	rows = [x for x in cur]
	cols = [x[0] for x in cur.description]
	query_result = curtojson(rows,cols)
	print('query_squery:',query_result)
	



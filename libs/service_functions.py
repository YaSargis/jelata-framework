from json import loads, dumps
from settings import *
from uuid import UUID
from datetime import datetime, date, time
from decimal import Decimal
from pathlib import Path
		
def datetimeToFormat(dt):
	hour = str(dt.hour)
	minute = str(dt.minute)
	second = str(dt.second)
	day = str(dt.day)
	month = str(dt.month)
	
	if len(hour) == 1:
		hour = '0' + hour
	if len(minute) == 1:
		minute = '0' + minute	
	if len(second) == 1:
		second = '0' + second	
	if len(day) == 1:
		day = '0' + day
	if len(month) == 1:
		month = '0' + month	
	return (
		day + '.' + month +  '.' + str(dt.year) + ' ' + hour+ ':' + minute + ':' + second
	)	

def dateToFormat(dt):
	day = str(dt.day)
	month = str(dt.month)

	if len(day) == 1:
		day = '0' + day
	if len(month) == 1:
		month = '0' + month	
	return (day + "." + month + 
			"." + str(dt.year) )	
			
def ifnull(s):
	'''
		if None return null
		else return 's'
	'''	
	if s is None:
		s = 'null'
	else:
		if isinstance(s,bool):
			s = int(s)
		s = "'" + str(s) + "'"
	return s
	
def curtojson(rows,cols):
	hts = []
	for row in rows:
		ht = {}
		for prop, val in zip(cols, row):
			if (type(val) is UUID or type(val) is Decimal or 
				type(val) is time):
				ht[prop] = str(val)
			elif type(val) is datetime:
				ht[prop] = datetimeToFormat(val)
			elif type(val) is date:
				ht[prop] = dateToFormat(val)
			else:
				ht[prop] = val
		hts.append(ht)
	rsl = dumps(hts , indent=1,  ensure_ascii=False)
	rsl = loads(rsl)
	return rsl

def refObj(oldarray,newarray):
	i = 0
	while i < len(newarray):
		j = 0
		isnotin = True
		while j < len(oldarray):
			if oldarray[j].get('col') == newarray[i].get('col') and 'related' not in oldarray[j] and 'tpath' not in oldarray[i]:
				isnotin = False
			j += 1
		if isnotin:
			oldarray.append(newarray[i])
		i += 1	
	i = 0		
	while i < len(oldarray):
		j = 0
		isin = True
		while j < len(newarray):
			if (newarray[j].get('col') == oldarray[i].get('col') and 'related' not in oldarray[i]) or 'tpath' in oldarray[i]:
				isin = False
			j += 1
		if isin:
			oldarray.remove(oldarray[i])	
		i += 1		
	return oldarray		

def showError(err,self):
	"""
		transforming postgres error and send right error text and status
		err - error text, self - context
	"""
	if err.find('HINT:') > -1:
		err = (err[err.find('HINT:')+5:err.find('+++___')]).split('\n')[0]
	else:
		err = err.split("\n")[0]
	self.set_header("Content-Type",'application/json charset="utf-8"')
	if err.find('m404err') != -1:
		self.write('{"message":"method not found"}')
		self.set_status(404,None)	
		return
	elif err.find('m401err') != -1:
		self.write('{"message":"authentication failed"}')
		self.set_status(401,None)	
		return
	elif err.find('m403err') != -1:
		self.write('{"message":"access denied"}')
		self.set_status(403,None)
		return
	else:		
		self.write(dumps({'message': err}))
		self.set_status(500,None)	
		return

def log(from_c, txt):		
	nowstr = (str(datetime.today().year) + '-' + str(datetime.today().month) + '-' +
		str(datetime.today().day) + '-' + str(datetime.today().hour))
	fullnowstr = (str(datetime.today().year) + '-' + str(datetime.today().month) + '-' + 
		str(datetime.today().day) + ' ' + str(datetime.today().hour) + ':' + 
		str(datetime.today().minute) + ':' + str(datetime.today().second))	

	logfile = open('./logs/' + nowstr + '.log', 'at', encoding = "utf-8")

	logfile.write('\n' + fullnowstr + ' || ' + from_c + ' || ' + txt)	
	logfile.close()
	
def default_headers(self):
	'''
		Default headers for requests
	'''
	orig = self.request.headers.get('Origin')
	self.set_header('Access-Control-Allow-Origin',str(orig))	
	self.set_header('Access-Control-Allow-Credentials','true')
	self.set_header('withCredentials','true')
	self.set_header('Access-Control-Allow-Headers','withCredentials, Auth, Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers')	
	self.set_header('Access-Control-Allow-Methods','GET, POST, PUT, DELETE, OPTIONS')		
from json import loads, dumps
from settings import developerRole
from service_functions import log

def formatInj(val):
	if val is not None:
		val = str(val)
		val = val.replace("'","''")
	return val

def getList(result,body, userdetail=None):
	squery = ' '
	gropby = ' '
	sgroupby = None
	config = result.get("config")
	order_by = []
	filters = result.get("filters")
	useroles = []
	if userdetail:
		useroles = userdetail.get('roles') or []
		print(userdetail)
	joins = ""
	orderby = ""
	where = ""
	gropbyChecker = [a for a in config if a.get('fn') and  a.get('fn').get('functype')=='groupby' and a.get('visible') ]
	for col in config:
		roles = []
		if col.get('roles'):
			roles = col.get('roles')
			if isinstance(col.get('roles'), str):
				roles = loads(roles)
		newroles = []	
		if roles:
			for obj in roles:
				newroles.append(obj.get('value'))	
				newroles.append(developerRole)	
		if (newroles is None or len(newroles) == 0 or (len(newroles)>0 
			and len(list(set(newroles) & set(useroles)))>0)):
			if not col.get('fn'):
				if not col.get('depency'):
					if 'related' not in col:	
						if col.get('type') != 'password':
							squery += 't1."' + col.get("col") + '" as "' + col.get("title") + '", '
							gropby += 't1."' + col.get("col") + '" ,' 
						else:
							squery += "'' as \"" + col.get("title") + "\", "
							gropby += "'' ,"							
					else:
						squery += "t" + str(col.get("t")) + '."' + col.get("col") + '" as "' + col.get("title") + '", '
						gropby += "t" + str(col.get("t")) + '."' + col.get("col") + '",'
				else:
					relcols = ''
					if str(col.get("relationcolums")) != '[]':	
						if col.get('depfunc'):
							for k in col.get("relationcolums"):
								relcols += 't' + str(col.get('t')) + '.' + k.get('value') + ','
							relcols = relcols[:len(relcols) - 1]
							squery += ("(SELECT " + col.get('depfunc') + 
								"(" + relcols + ") FROM " + col.get("relation") + 
								" as t" + str(col.get("t")) + " WHERE t" + 
								str(col.get("t")) + "." + col.get('depencycol') + 
								' = t1.id  ) as "' + col.get("title") + '",')
							gropby += (" t1.id ,")
						else:
							for k in col.get("relationcolums"):
								relcols += 't' + str(col.get('t')) + '.' + k.get('value') + ','
							relcols = relcols[:len(relcols) - 1]
							squery += ("coalesce((SELECT array_to_json(array_agg(row_to_json(d))) FROM  ((SELECT " + 
								relcols + 
								" FROM " + col.get("relation") + 
								" as t" + str(col.get("t")) + 
								" WHERE t" + str(col.get("t")) + 
								"." + col.get('depencycol') + 
								' = t1.id  )) as d),\'[]\') as "' + col.get("title") + 
								'", ')
							gropby += (" t1.id ,")
			else:
				squery += col.get("fn").get('label') + "( " 
				if col.get("fn").get('functype') == "groupby":
					sgroupby = gropby
					squery += " distinct "
				else:
					for cl in col.get("fncolumns"):
						gropby += "t" + str(cl.get('t')) + "." + cl.get('label') + ","
				for cl in col.get("fncolumns"):
					squery += "t" + str(cl.get('t')) + "." + cl.get('label') + ","
				squery = squery[:len(squery)-1]
				squery += ') as "' + col.get("title") + '", ' 				

		if col.get("relation") and not col.get('depency') and not col.get('related'):
			if 'join' in col:
				if col.get("join"):
					joins += " JOIN " + col.get("relation") + " as t" + str(col.get("t")) + " on t1." + col.get("col") + " = t" + str(col.get("t")) + ".id" 
				else:
					joins += " LEFT JOIN " + col.get("relation") + " as t" + str(col.get("t")) + " on t1." + col.get("col") + " = t" + str(col.get("t")) + ".id" 
			else:
				joins += " LEFT JOIN " + col.get("relation") + " as t" + str(col.get("t")) + " on t1." + col.get("col") + " = t" + str(col.get("t")) + ".id" 
		
		if col.get("tpath"):
			i = 1
			tpath = col.get("tpath")
			while i < len(tpath):
				if col.get("join"):
					if joins.find(" as " + tpath[i].get("t")) == -1:
						joins += " JOIN " + tpath[i].get("table") + " as " + tpath[i].get("t") + " on " + tpath[i-1].get("t") + "." + tpath[i].get("col") + " = " + tpath[i].get("t") + ".id" 
				else:
					if joins.find(tpath[i].get("t")) == -1:
						joins += " LEFT JOIN " + tpath[i].get("table") + " as " + tpath[i].get("t") + " on " + tpath[i-1].get("t") + "." + tpath[i].get("col") + " = " + tpath[i].get("t") + ".id" 
				i += 1
			if 	joins.find(" as t" + str(col.get("t"))) == -1:
				joins += " LEFT JOIN " + col.get("table") + " as t" + str(col.get("t")) + " on t" + str(col.get("t")) + ".id = " + tpath[i-1].get("t") + "." + col.get('relatecolumn')  
		
		if col.get("defaultval"):
			defv = col.get("defaultval")
			if defv[:5] == 'func:':
				defv = " = " + defv[5:] + " "
			elif defv in ('is null','is not null'):
				defv = ' ' + defv 
			elif defv == "_orgs_":
				userorgs = str(userdetail.get('orgs'))
				defv = " in (select value::varchar from json_array_elements_text('" + userorgs + "') "
			elif defv == "_userid_":
				#if userdetail is not None and len(userdetail) > 0:
				userid = str(userdetail.get('id'))	
				#if userid and len(userid)>0:
				defv = " = '" + userid + "' "	
			elif defv == "_orgid_":
				orgid = str(userdetail.get('orgid'))	
				defv = " = '" + orgid + "' "				
			else :
				defv = " = '" + defv + "'"
			if "related" in col:
				where += "and t" + str(col.get("t")) + "." + col.get("col") + "::varchar " + defv + " "				
			else:
				where += "and t1." + col.get("col") + "::varchar " + defv + " "	
				
		if 'inputs' in body:
			order_by = body.get("inputs").get("orderby") or []
			if body.get("inputs").get(col.get("title")):
				if body.get("inputs").get(col.get("title")) == '_orgs_':
					body["inputs"][col.get("title")] = userdetail.get('orgs')
				elif body.get("inputs").get(col.get("title")) == '_userid_':
					body["inputs"][col.get("title")] = userdetail.get('id')
				elif body.get("inputs").get(col.get("title")) == '_orgid_':
					body["inputs"][col.get("title")] = userdetail.get('orgid')	
				if 'related' not in col:
					where += 'and t1."' + col.get("col") + '" = \'' + formatInj(body.get("inputs").get(col.get("title"))) + "' "
				else:
					where += 'and t' + str(col["t"]) + '."' + col["col"] + '" = \'' + formatInj(body.get("inputs").get(col.get("title"))) + "' "
				body.get("inputs")[col.get("title")] = None	
				
	if len(filters) > 0:
		for col in filters:
			if 'filters' in body:
				if (col.get("type") == "typehead" and col.get("title") in body.get("filters")) or str(col.get("column")) in body.get("filters"): 
					if col.get("type") == "select":
						if body.get("filters").get(col.get("column")):
							where += "and t" + str(col.get("t") or '1') + "." + col.get("column") + " = '" + formatInj(body.get("filters").get(col.get("column"))) + "' "
					elif col.get("type") == "substr":
						where += "and coalesce(t" + str(col.get("t") or '1') + "." + col.get("column") + "::varchar,'') like '%" + formatInj(body.get("filters").get(col.get("column"))) + "%' "
					elif col.get("type") == "period":
						if formatInj(body.get("filters").get(col.get("column")).get("date1")) is not None and formatInj(body.get("filters").get(col.get("column")).get("date2")) is not None:
							where += ("and t" + str(col.get("t") or '1') + "." + col.get("column") + "::date >= '" + 
								formatInj(body.get("filters").get(col.get("column")).get("date1")) + 
								"' and t" + str(col.get("t") or '1') + "." + col.get("column") + 
								"::date <= '" + formatInj(body.get("filters").get(col.get("column")).get("date2")) + "' ")									
					elif col.get("type") == "multiselect":
						if len(body.get("filters").get(col.get("column"))) > 0 :
							where += ("and (t" + str(col.get("t") or '1') + "." + col.get("column") + 
								"::varchar in ( select (value::varchar::json)->>'value'::varchar from json_array_elements_text('" + 
								dumps(body.get("filters").get(col.get("column"))) + "')) or ( select count(*) from json_array_elements_text('" + 
								dumps(body.get("filters").get(col.get("column"))) + "') where (value::varchar::json)->>'value' is null )>0)")
					elif col.get("type") == "multijson":
						if len(body.get("filters").get(col.get("column"))) > 0:
							where += ("and  ( select count(*) from json_array_elements_text('" + 
								dumps(body.get("filters").get(col.get("column"))) + "') as a JOIN json_array_elements_text(t" + str(col.get("t") or '1') + "." + 
								col.get("column") + ") as b on (a.value::varchar::json)->>'value'::varchar = b.value::varchar or (a.value::varchar::json->>'value') is null )>0 ")
					elif col.get("type") == "check":
						ch = 'false'
						if body.get("filters").get(col.get("column")):
							ch = 'true'
						where += "and coalesce(t" + str(col.get("t") or '1') + "." + col.get("column") + ",false) = " + str(ch) + " "
					elif col.get("type") == "typehead":
						
						v = formatInj(body.get("filters").get(col.get("title")))
						if v:
							where += "and ("
							if len(v.split(" "))>2:
								i = 0
								v = v.split(" ")
								cols = col.get("column")
								while i < len(cols):
									if len(v) >= i+1:
										where += " and "
										if cols[i].get("t"):
											where += " lower(t" + str(cols[i].get("t") or '1') + "." + cols[i].get("label") + "::varchar) like lower('" + str(v[i]) + "%') "
										else:	
											where += " lower(" + cols[i].get("label") + "::varchar) like lower('" + str(v[i]) + "') "
									i += 1	
								where = where.replace("( and","(") + " ) "	
							else:
								for x in col.get("column"):	
									where += " or "
									if x.get("t"):
										where += " lower(t" + str(x.get("t") or '1') + "." + x.get("label") + "::varchar) like lower('%" + str(v) + "%') "
									else:	
										where += " lower(" + x.get("label") + "::varchar) like lower('%" + str(v) + "%') "
								where = where.replace("( or","(") + " ) "
							
	pagenum = 1
	pagesize = 30
	rownum = ''
	pagewhere = ''
	pageselect = ''
	if sgroupby:
		sgroupby = ' GROUP BY ' + sgroupby[:len(sgroupby)-1]
	else:
		sgroupby = ''
	if result.get("pagination"):
		if body.get('pagination') and 'pagenum' in body.get('pagination'):
			pagenum = int(body.get('pagination').get('pagenum'))
		if body.get('pagination') and 'pagesize' in body.get('pagination'):
			pagesize = int(body.get('pagination').get('pagesize'))
		
		page1 = (pagenum * pagesize) - pagesize + 1
		page2 = pagenum * pagesize
		pageselect = 'SELECT * FROM (' 
		pagewhere += ') as pz WHERE pz.rownum between ' + str(page1) + ' and ' + str(page2) + '   '
	
	rownum += 'ROW_NUMBER() over ( order by '
	
	if len(order_by) > 0:
		for col in order_by:
			t = "1"
			if col.get("related"):
				t = str(col.get("t"))
			rownum += "t" + t + "." + col.get("col") + " " + col.get("desc") + ","
		rownum = rownum[:len(rownum) - 1]
	else:
		rownum += 't1.id'
	rownum += ") as rownum "	
	
	if len(where)>0:
		where = ' WHERE ' + where[3:]	
	squery = (pageselect + 'SELECT ' + rownum + ', ' + squery[:len(squery)-2] + 
		" FROM " + result.get("tablename") + " as t1 " + joins + where + sgroupby +
		pagewhere)#orderby	
	count =  "SELECT count(*) as count FROM " + result.get("tablename") + " as t1 " + joins + where #orderby	

	log('sql_migration', squery + ' userdetail: ' + str(userdetail))
	return squery, count
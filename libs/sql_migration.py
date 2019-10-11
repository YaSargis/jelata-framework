from json import loads, dumps
from settings import developerRole
from libs.service_functions import log

def formatInj(val):
	if val is not None:
		val = str(val)
		val = val.replace("'","''")
	return val

def getList(result,body, userdetail=None):
	squery = ' '
	gropby = ' '
	sgroupby = None
	config = result.get('config')
	order_by = []
	filters = result.get('filters')
	useroles = []
	if userdetail:
		useroles = userdetail.get('roles') or []
	
	#check filters roles
	if filters:
		filteredFilters = []
		for filter in filters:
			if 'roles' in filter and len(filter.get('roles')) > 0:
				fRoles = []
				for obj in filter.get('roles'):
					fRoles.append(obj.get('value'))	
					fRoles.append(developerRole)
				if len(list(set(fRoles) & set(useroles)))>0:
					filteredFilters.append(filter)
			else:
				filteredFilters.append(filter)
		filters = filteredFilters
		result['filters'] = filteredFilters
	
	#check acts roles	
	if result.get('acts'):
		filteredActs = []
		for act in result.get('acts'):
			if 'roles' in act and len(act.get('roles')) > 0:
				fAct = []
				for obj in act.get('roles'):
					fAct.append(obj.get('value'))	
					fAct.append(developerRole)
				if len(list(set(fAct) & set(useroles)))>0:
					filteredActs.append(act)
			else:
				filteredActs.append(act)
		result['acts'] = filteredActs
		
	joins = ''
	orderby = ''
	where = ''
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
			colT = str(col.get('t'))
			if 'relation' not in col or col.get('relation') is None:
				colT = '1'
			sColT = str(col.get('t'))
			if 'table' not in col or col.get('table') is None:
				sColT = '1'
			if not col.get('fn'):
				if not col.get('depency'):
					squery += 't' +	sColT + '."' + col.get('col') + '" as "' + (col.get('key') or col.get('title')) + '", '
					gropby += 't' + sColT + '."' + col.get('col') + '",'
				else:
					relcols = ''
					if str(col.get('relationcolums')) != '[]':	
						if col.get('depfunc'):
							for k in col.get('relationcolums'):
								relcols += 't' + colT + '."' + k.get('value') + '",'
							relcols = relcols[:len(relcols) - 1]
							squery += ('(SELECT ' + col.get('depfunc') + 
								'(' + relcols + ') FROM ' + col.get('relation') + 
								' as t' + colT + ' WHERE t' + 
								colT + '.' + col.get('depencycol') + 
								' = t1.id  ) as "' + (col.get('key') or col.get('title')) + '",')
							gropby += ' t1.id ,'
						else:
							for k in col.get('relationcolums'):
								relcols += 't' + colT + '."' + k.get('value') + '",'
							relcols = relcols[:len(relcols) - 1]
							squery += ('coalesce((SELECT array_to_json(array_agg(row_to_json(d))) FROM  ((SELECT ' + 
								relcols + 
								' FROM ' + col.get('relation') + 
								' as t' + colT + 
								' WHERE t' + colT + 
								'."' + col.get('depencycol') + 
								'" = t1.id  )) as d),\'[]\') as "' + (col.get('key') or col.get('title')) + 
								'", ')
							gropby += ' t1.id ,'
			else:
				squery += col.get('fn').get('label') + '( ' 
				if col.get('fn').get('functype') == 'groupby':
					sgroupby = gropby
					squery += ' distinct '
				else:
					for cl in col.get('fncolumns'):
						gropby += 't' + str(cl.get('t')) + '."' + cl.get('label') + '",'
				for cl in col.get('fncolumns'):
					squery += 't' + str(cl.get('t')) + '."' + cl.get('label') + '",'
					if col.get('fn').get('label') == 'concat':
						squery += "' ',"
				squery = squery[:len(squery)-1]
				squery += ') as "' + (col.get('key') or col.get('title')) + '", ' 				

		if col.get('relation') and not col.get('depency') and not col.get('related'):
			if 'join' in col:
				if col.get('join'):
					joins += ' JOIN ' + col.get('relation') + ' as t' + colT + ' on t1."' + col.get('col') + '" = t' + colT + '."' + (col.get('relcol') or 'id') + '"'
				else:
					joins += ' LEFT JOIN ' + col.get('relation') + ' as t' + colT + ' on t1."' + col.get('col') + '" = t' + colT + '."' + (col.get('relcol') or 'id') + '"'
			else:
				joins += ' LEFT JOIN ' + col.get('relation') + ' as t' + colT + ' on t1."' + col.get('col') + '" = t' + colT + '."' + (col.get('relcol') or 'id')  + '"'
		
		if col.get('tpath'):
			i = 1
			tpath = col.get('tpath')
			while i < len(tpath):
				if col.get('join'):
					if joins.find(' as ' + tpath[i].get('t')) == -1:
						joins += ' JOIN ' + tpath[i].get('table') + ' as ' + tpath[i].get('t') + ' on ' + tpath[i-1].get('t') + '."' + tpath[i].get('col') + '" = ' + tpath[i].get('t') + '."' + (col.get('relcol') or 'id') + '"'
				else:
					if joins.find(tpath[i].get('t')) == -1:
						joins += ' LEFT JOIN ' + tpath[i].get('table') + ' as ' + tpath[i].get('t') + ' on ' + tpath[i-1].get('t') + '."' + tpath[i].get('col') + '" = ' + tpath[i].get('t') + '."' + (col.get('relcol') or 'id') + '"'
				i += 1
			if 	joins.find(' as t' + colT) == -1:
				joins += ' LEFT JOIN ' + col.get('table') + ' as t' + colT + ' on t' + colT + '."' + (col.get('relcol') or 'id') + '" = ' + tpath[i-1].get('t') + '."' + col.get('relatecolumn') + '"'  
		
		if col.get('defaultval'):
			colname = ''
			if 'fn' not in col:	
				colname = 't' + sColT + '."' + col.get("col") + '"'
			else:
				colname =  col.get('fn').get('label') + '( '
				for cl in col.get('fncolumns'):
					colname += 't' + str(cl.get('t')) + '."' + cl.get('label') + '",'
				colname = colname[:len(colname)-1]
				colname += ')'
			defv = ''
			if len(col.get('defaultval'))>0: 
				defv = '('
			for d in col.get('defaultval'):
				def_v = d.get('value')
				act_v = d.get('act').get('value')
				bool_v = d.get('bool').get('value')
				if act_v == 'like' or act_v == 'not like':
					if def_v == '_userid_':
						userid = str(userdetail.get('id'))	
						defv += bool_v + ' ' + colname + ' ' + act_v + " '%" + userid + "%' "	
					elif def_v == '_orgid_':
						orgid = str(userdetail.get('orgid'))	
						defv += bool_v + ' ' + colname + ' ' + act_v + " '%" + orgid + "%' "						
					else :
						defv += bool_v + ' ' + colname + ' ' + act_v + " '%" + def_v + "%' "
				elif act_v == 'is null' or act_v == 'is not null':		
						defv += bool_v + ' ' + colname + ' ' + act_v 
				elif act_v == 'in' or act_v == 'not in':
					if def_v == '_orgs_':
						userorgs = str(userdetail.get('orgs'))
						if col.get('type') == 'array':
							defv += bool_v + " (select count(*) from json_array_elements_text('" + userorgs + "') as j1" + ' join json_array_elements_text("' + colname + '") as j2 on j1.value::varchar=j2.value::varchar)>0 '
						else:
							defv += bool_v + ' "' + colname +  '"::varchar ' + act_v + "(select value::varchar from json_array_elements_text('" + userorgs + "')) "
					elif def_v == '_userid_':
						userid = str(userdetail.get('id'))	
						defv += bool_v + ' "' + colname + '"::varchar ' + act_v + " ('" + userid + "') "	
					elif def_v == bool_v + '_orgid_':
						orgid = str(userdetail.get('orgid'))	
						defv += bool_v + ' "' + colname +  '"::varchar ' + act_v + " ('" + orgid + "') "		
					elif def_v.find(',') != -1:	
						defv += bool_v + ' "' + colname +  '"::varchar ' + act_v + " (select value::varchar from json_array_elements_text('[" + def_v + "]')) "
						defv = defv.replace('[','["').replace(',','","').replace(']','"]')		
					else :
						defv += bool_v + ' "' + colname +  '"::varchar ' + act_v + " ('" + def_v + "') "
				else:
					if def_v == '_orgs_':
						userorgs = str(userdetail.get('orgs'))
						defv += bool_v + ' ' + colname + '::varchar ' + act_v + " (select value::varchar from json_array_elements_text('" + userorgs + "')) "
					elif def_v == '_userid_':
						userid = str(userdetail.get('id'))	
						defv += bool_v + ' "' + colname + '" ' + act_v + " '" + userid + "' "	
					elif def_v == '_orgid_':
						orgid = str(userdetail.get('orgid'))	
						defv += bool_v + ' "' + colname +  '" ' + act_v + " '" + orgid + "' "		
					else :
						defv += bool_v + ' "' + colname + '" ' + act_v + " '" + def_v + "' "
			if len(defv) > 0:
				defv = defv.replace('(or','( ')
				defv = defv.replace('(and','( ')
				defv += ')'
			where += 'and ' + defv + ' ' 			
			
		if col.get('required'):
			where += 'and t' + sColT + '."' + col.get('col') + '" = ' + (body.get('inputs').get(col.get('title')) or 'null')

		if 'inputs' in body:
			order_by = body.get('inputs').get('orderby') or []
			if body.get('inputs').get(col.get('title')):
				if body.get('inputs').get(col.get('title')) == '_orgs_':
					body['inputs'][col.get('title')] = userdetail.get('orgs')
				elif body.get('inputs').get(col.get('title')) == '_userid_':
					body['inputs'][col.get('title')] = userdetail.get('id')
				elif body.get('inputs').get(col.get('title')) == '_orgid_':
					body['inputs'][col.get('title')] = userdetail.get('orgid')	


				where += 'and t' + sColT + '."' + col.get('col') + '" = \'' + formatInj(body.get('inputs').get(col.get('title'))) + "' "
				body['inputs'][col.get('title')] = None	
				
	if len(filters) > 0:
		for col in filters:
			if 'filters' in body:
				if (col.get('type') == 'typehead' and col.get('title') in body.get('filters')) or str(col.get('column')) in body.get('filters'): 
					if col.get('type') == 'select':
						if body.get('filters').get(col.get('column')):
							where += 'and t' + colT + '."' + col.get('column') + '"' + " = '" + formatInj(body.get('filters').get(col.get('column'))) + "' "
					elif col.get("type") == "substr":
						where += 'and upper(coalesce(t' + colT + '."' + col.get('column') + '"' + "::varchar,'')) like upper('%" + formatInj(body.get('filters').get(col.get('column'))) + "%') "
					elif col.get('type') == 'period':
						if formatInj(body.get('filters').get(col.get('column')).get('date1')) is not None and formatInj(body.get('filters').get(col.get('column')).get('date2')) is not None:
							where += ('and t' + colT + '."' + col.get('column') + '"' + "::date >= '" + 
								formatInj(body.get('filters').get(col.get('column')).get('date1')) + 
								"' and t" + colT + '."' + col.get('column') + '"' +
								"::date <= '" + formatInj(body.get('filters').get(col.get('column')).get('date2')) + "' ")									
					elif col.get('type') == 'multiselect':
						if len(body.get('filters').get(col.get('column'))) > 0 :
							where += ('and (t' + colT+ '."' + col.get('column') + '"' +
								"::varchar in ( select (value::varchar::json)->>'value'::varchar from json_array_elements_text('" + 
								dumps(body.get('filters').get(col.get('column'))) + "')) or ( select count(*) from json_array_elements_text('" + 
								dumps(body.get('filters').get(col.get('column'))) + "') where (value::varchar::json)->>'value' is null) > 0)")
					elif col.get('type') == 'multijson':
						if len(body.get('filters').get(col.get('column'))) > 0:
							where += ("and  ( select count(*) from json_array_elements_text('" + 
								dumps(body.get('filters').get(col.get('column'))) + "') as a JOIN json_array_elements_text(t" + colT + '."' + 
								col.get("column") + '"' + ") as b on (a.value::varchar::json)->>'value'::varchar = b.value::varchar or (a.value::varchar::json->>'value') is null) > 0 ")
					elif col.get('type') == 'check' and body.get('filters').get(col.get('column')) is not None:
						ch = 'false'
						if body.get('filters').get(col.get('column')) == True:
							ch = 'true'
						where += 'and coalesce(t' + colT + '."' + col.get('column') + '"' + ',false) = ' + str(ch) + ' '
					elif col.get('type') == 'typehead':						
						v = formatInj(body.get('filters').get(col.get('title')))
						if v:
							where += 'and ('
							if len(v.split(' '))>2:
								i = 0
								v = v.split(' ')
								cols = col.get('column')
								while i < len(cols):
									if len(v) >= i+1:
										where += ' and '
										if cols[i].get('t'):
											where += ' lower(t' + str(cols[i].get('t') or '1') + '."'+ cols[i].get('label') + '"' + "::varchar) like lower('" + str(v[i]) + "%') "
										else:	
											where += ' lower(' + cols[i].get('label') + "::varchar) like lower('" + str(v[i]) + "') "
									i += 1	
								where = where.replace('( and','(') + ' ) '	
							else:
								for x in col.get('column'):	
									where += ' or '
									if x.get('t'):
										where += ' lower(t' + str(x.get('t') or '1') + '."' + x.get('label') + '"' + "::varchar) like lower('%" + str(v).strip() + "%') "
									else:	
										where += ' lower(' + x.get('label') + "::varchar) like lower('%" + str(v).strip() + "%') "
								where = where.replace('( or','(') + ' ) '
							
	pagenum = 1
	pagesize = 30
	rownum = ''
	pagewhere = ''
	pageselect = ''
	if sgroupby:
		sgroupby = ' GROUP BY ' + sgroupby[:len(sgroupby)-1]
	else:
		sgroupby = ''
	if result.get('pagination'):
		if body.get('pagination') and 'pagenum' in body.get('pagination'):
			pagenum = int(body.get('pagination').get('pagenum'))
		if body.get('pagination') and 'pagesize' in body.get('pagination'):
			pagesize = int(body.get('pagination').get('pagesize'))
		
		page1 = (pagenum * pagesize) - pagesize
		pageselect = 'SELECT * FROM (' 
		pagewhere += ' LIMIT ' + str(pagesize) + ' OFFSET ' + str(page1) + ') as pz  '
	
	rownum += 'ROW_NUMBER() over ( order by '
	
	if len(order_by) > 0:
		for col in order_by:
			t = '1'
			if col.get('related'):
				t = str(col.get('t'))
			if not col.get('fn'):	
				rownum += 't' + t + '."' + col.get('col') + '" ' + col.get('desc') + ','
			else:
				rownum += col.get('fn').get('value') + '('
				for x in col.get('fncols'):
					rownum += 't' + str(x.get('t')) + '."' + x.get('label') + '",'
				rownum = rownum[:len(rownum) - 1] 	
				rownum += ') ' + col.get('desc') + ','
		rownum = rownum[:len(rownum) - 1]
	else:
		rownum += 't1.id'
	rownum += ') as rownum '	
	if result.get('viewtype').find('form') != -1:
		pagewhere = ' LIMIT 2 '
	elif not result.get('pagination'):
		pagewhere = ' LIMIT 300 '
	if len(where) > 0:
		where = ' WHERE ' + where[3:]	
	squery = (pageselect + 'SELECT ' + rownum + ', ' + squery[:len(squery)-2] + 
		' FROM ' + result.get('tablename') + ' as t1 ' + joins + where + sgroupby +
		pagewhere)#orderby	
	count =  'SELECT count(*) as count FROM ' + result.get('tablename') + ' as t1 ' + joins + where #orderby	

	log('sql_migration', squery + ' userdetail: ' + str(userdetail))
	return squery, count

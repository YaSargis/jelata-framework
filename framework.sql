--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.14
-- Dumped by pg_dump version 9.5.1

-- Started on 2019-03-25 09:09:37

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 318950)
-- Name: framework; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA framework;


ALTER SCHEMA framework OWNER TO postgres;

--
-- TOC entry 1 (class 3079 OID 12393)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2451 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 2 (class 3079 OID 318953)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 2452 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = framework, pg_catalog;

--
-- TOC entry 262 (class 1255 OID 318990)
-- Name: fn_allviews(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_allviews(injson json, OUT outjson json, OUT foundcount bigint) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
  pagenum smallint;
  pagesize smallint;
  substr varchar(50);
  _off smallint;
BEGIN
  pagenum = injson->>'pagenum';
  pagesize = injson->>'pagesize';
  substr = injson->>'substr';
  
  pagenum = coalesce(pagenum,'1');
  pagesize = coalesce(pagesize,'15');
  substr = upper(concat('%',coalesce(substr,'%'),'%')); 
 _off=(pagenum*pagesize)-pagesize;
  foundcount = (SELECT count(v.id)
  FROM framework.views as v
  WHERE upper(v.title) like substr or upper(v.tablename) like substr
  );
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM	
    (SELECT 
    	ROW_NUMBER() over ( order by v.id ) as rownum,
    	v.id,
    	v.title,
        v.viewtype,
        v.descr,
        v.tablename,
        v.path,
        v.subscrible,
        '' as viewlink
    FROM framework.views as v
    WHERE upper(v.title) like substr or upper(v.tablename) like substr
	ORDER BY v.id
	LIMIT pagesize OFFSET _off) as d
  INTO outjson;
  
  outjson = COALESCE(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_allviews(injson json, OUT outjson json, OUT foundcount bigint) OWNER TO postgres;

--
-- TOC entry 263 (class 1255 OID 318991)
-- Name: fn_autocomplete(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_autocomplete(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
  col varchar;
  val varchar;
  _table varchar;
  squery varchar;
  _val varchar;
BEGIN

	col = injson->>'col';
    val = injson->>'val';
    _table = injson->>'table';
    
    IF val is not null and length(val) >= 3 THEN
    	_val = concat('%',upper(_val),'%');
    	squery = concat(squery,
        	'SELECT array_to_json(array_agg(row_to_json(d))) FROM (SELECT ' , 
            col , ' as value, ' , col , ' 
        	as label FROM ' , _table , ' WHERE upper(' , 
            col , ')::varchar like $1::varchar ) as d');
            	
       EXECUTE format(squery) USING _val INTO outjson;
       
       outjson = coalesce(outjson,
       					(SELECT row_to_json(d) 
                         FROM (SELECT val as value, val as label) as d));
            
    END IF;        

	outjson = coalesce(outjson,'[]');

END;
$_$;


ALTER FUNCTION framework.fn_autocomplete(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 318992)
-- Name: fn_branchestree_recurs(integer, integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_branchestree_recurs(_parentid integer, _treesid integer, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN

	SELECT
    	array_to_json(array_agg(row_to_json(d))) 
      FROM
      (SELECT
          tb.id as key, 
          tb.icon,
          tb.parentid,
          tb.treesid,
          tb.title as label,
 
          framework.fn_branchestree_recurs(tb.id,tb.treesid) as children
      FROM framework.treesbranches as tb
      WHERE tb.treesid = _treesid and tb.title is not null and 
      coalesce(tb.parentid,0) = coalesce(_parentid,0)) as d
      INTO outjson;
      
     -- outjson = coalesce(outjson,'[]');


END;
$$;


ALTER FUNCTION framework.fn_branchestree_recurs(_parentid integer, _treesid integer, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 318993)
-- Name: fn_compo(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_compo(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id int;
BEGIN

	_id = injson->>'id';
    
    
    SELECT row_to_json(d)
    FROM
    (SELECT *
     FROM framework.compos as c
     WHERE c.id = _id) as d
     INTO outjson;


	outjson = coalesce(outjson,'{}');

END;
$$;


ALTER FUNCTION framework.fn_compo(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 266 (class 1255 OID 318994)
-- Name: fn_compo_bypath(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_compo_bypath(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _path varchar(350);
BEGIN

	_path = injson->>'path';
    
    
    SELECT row_to_json(d)
    FROM
    (SELECT *
     FROM framework.compos as c
     WHERE c.path = _path) as d
     INTO outjson;


	outjson = coalesce(outjson,'{}');

END;
$$;


ALTER FUNCTION framework.fn_compo_bypath(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 267 (class 1255 OID 318995)
-- Name: fn_compo_save(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_compo_save(injson json, OUT _id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  _config json;
  _title varchar(350);
  _path varchar(350);
  _userid int;
  _newdata json;
BEGIN
  _config = injson->>'config';
  _title = injson->>'title';
  _path = injson->>'path';
  _id = injson->>'id';
  _userid = injson->>'userid';
  
  IF _id is null THEN
  	IF _config is null THEN
    	perform raiserror('config is null');
    END IF;

  	IF _title is null THEN
    	perform raiserror('title is null'); 
    END IF;

  	IF _path is null THEN
        perform raiserror('path is null');
    END IF;
    
    _id = nextval('framework.compos_id_seq'::regclass);
    
    INSERT INTO framework.compos (
      id ,
      title ,
      path,
      config
    )
    VALUES (
      _id ,
      _title ,
      _path,
      _config
    );
    
    
    SELECT row_to_json(d)
    FROM
    (SELECT
    	*
    FROM framework.compos) as d
    WHERE id = _id
    INTO _newdata;
    
  	INSERT INTO framework.logtable (
      tablename,
      tableid,
      opertype,
      userid,
      newdata
    ) VALUES (
      'framework.compos',
      _id::varchar(150),
      '1',
      _userid ,
     _newdata   
    );    
  ELSE
    SELECT row_to_json(d)
    FROM
    (SELECT
    	*
    FROM framework.compos) as d
    WHERE id = _id
    INTO _newdata;
    
  	UPDATE framework.compos
    SET
      title = coalesce(title,_title),
      path = coalesce(path,_path),
      config = coalesce(config, _config)  	
    WHERE id = _id;
  	    

    
  	INSERT INTO framework.logtable (
      tablename,
      tableid,
      opertype,
      userid,
      newdata
    ) VALUES (
      'framework.compos',
      _id::varchar(150),
      '2',
      _userid ,
     _newdata   
    ); 
  END IF;    
END;
$$;


ALTER FUNCTION framework.fn_compo_save(injson json, OUT _id integer) OWNER TO postgres;

--
-- TOC entry 268 (class 1255 OID 318996)
-- Name: fn_createconfig(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_createconfig(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  tabname varchar(350);
BEGIN

	tabname = injson->>'tabname';
  SELECT
  	array_to_json(array_agg(row_to_json(d))) 
  FROM (
  SELECT ROW_NUMBER() OVER (order by  f.column_id) as t, * FROM 
  (SELECT 
  	distinct
      t.column_name as col,		
      substring(coalesce(pgd.description, t.column_name),1,128) as title ,
       framework.fn_htmldatatype(t.data_type) as type,
      true as visible,
	      /*	CASE WHEN y.table_schema is not null 
            THEN  concat(y.table_schema , '.' , y.table_name)
             ELSE y.table_schema
        END*/
       (SELECT concat(y.table_schema , '.' , y.table_name)
        FROM information_schema.table_constraints as c
               JOIN information_schema.key_column_usage AS x ON 
      				c.constraint_name = x.constraint_name and x.column_name = t.column_name                        
	  			 JOIN information_schema.constraint_column_usage 
        AS y ON y.constraint_name = c.constraint_name and x.column_name = t.column_name 
        WHERE c.table_name = t.table_name
      	and c.table_schema = t.table_schema and c.constraint_type = 'FOREIGN KEY'
        LIMIT 1)	
      as relation,		
      '[]' as relationcolums,
      false as "join",
      false as onetomany,
      
      null as defaultval,
      '100%' as width,
      t.ordinal_position as column_id,
     false as depency,
     null as depencycol,
    '[]' as roles,
    '' as classname        
 FROM information_schema.columns as t
 	  left join pg_catalog.pg_statio_all_tables as st on 
      		st.schemaname = t.table_schema 
      		and st.relname = t.table_name	
 	  left join pg_catalog.pg_description pgd on pgd.objoid=st.relid
			and pgd.objsubid=t.ordinal_position
       /*left join information_schema.table_constraints as c on c.table_name = t.table_name
      	and c.table_schema = t.table_schema and c.constraint_type = 'FOREIGN KEY'
         
      LEFT JOIN information_schema.key_column_usage AS x ON 
      c.constraint_name = x.constraint_name and x.column_name = t.column_name                        
	  LEFT JOIN information_schema.constraint_column_usage 
        AS y ON y.constraint_name = c.constraint_name and x.column_name = t.column_name */
                                 
 WHERE concat(t.table_schema,'.',t.table_name) = tabname

 
 UNION ALL
 SELECT 
     x.table_name  as col,
     --,		
      x.table_name as title ,
      'array' as type,
      false as visible,
	  concat(x.table_schema , '.' , x.table_name) as relation,
      '[]' as relationcolums,
      false as join,
      true as onetomany,
      
      null as defaultval,
      '100%' as width,
     (SELECT count(t.*) FROM information_schema.columns as t                                 
     WHERE concat(t.table_schema,'.',t.table_name) = tabname) + 1 as column_id,
     true as depency,
     x.column_name as depencycol,
    '[]' as roles,
    '' as classname  
    
          
 FROM  information_schema.key_column_usage as x

        --  and t.column_name = x.column_name
       left join information_schema.referential_constraints as c
       on c.constraint_name = x.constraint_name and c.constraint_schema = x.constraint_schema
       left join information_schema.key_column_usage y
          on y.ordinal_position = x.position_in_unique_constraint
          and y.constraint_name = c.unique_constraint_name
                                 
 WHERE concat(y.table_schema,'.',y.table_name) = tabname
 	and y.table_name is not null
 
 ) as f
 ORDER BY f.column_id, relation) as d
 INTO outjson;
 
 outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_createconfig(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 269 (class 1255 OID 318997)
-- Name: fn_deleterow(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_deleterow(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _tablename varchar(350);
  _id varchar;
  _squery varchar;
  _oldata json;
  _userid varchar(150);
_viewid int;
_userroles json;
_viewroles json;
BEGIN
  _tablename = injson->>'tablename';	
  _id = trim(injson->>'id');
  _userid = injson->>'userid';
  _viewid = injson->>'viewid';
  
    IF _viewid is NULL
    THEN
      perform raiserror('view id is null');
    END IF; 
    
    SELECT 
    	roles
    FROM framework.views 
    WHERE id = _viewid
    INTO _viewroles;
    IF _viewroles is null THEN
    	perform raiserror('view is not found');
    END IF;
    SELECT 
    	roles
    FROM framework.users 
    WHERE id::varchar = _userid
    INTO _userroles;
    
    IF (SELECT count(*) FROM json_array_elements_text(_viewroles)) > 0 and 
    (SELECT count(*) 
     FROM json_array_elements_text(_viewroles) as v
     	JOIN json_array_elements_text(_userroles) as r on (v.value::json->>'value')::varchar = r.value::varchar
     ) = 0 THEN
    	PERFORM raiserror('m403err');
    END IF;
    
    IF _tablename is NULL
    THEN
      perform raiserror('table is null');
    END IF; 
    
    

   
   IF (SELECT count(*)
   FROM information_schema.columns as t
   WHERE concat(t.table_schema,'.',t.table_name) = _tablename ) = 0 THEN
   	 perform raiserror('can not find out the column type. check table and column names');
   END IF;
  
  IF coalesce(_id,'') = '' THEN
	perform raiserror('id is null');
  END IF;
  

 _squery = concat('
   SELECT row_to_json(d)
   FROM
   (
    SELECT * 
    FROM ',_tablename,'  
    WHERE upper(id::varchar) = upper($1)
  ) as d');
  
    EXECUTE format(_squery) USING _id::varchar INTO _oldata; 
  	INSERT INTO framework.logtable (
      tablename,
      tableid,
      opertype,
      userid,
      oldata
    ) VALUES (
      _tablename ,
      _id ,
      '3',
      _userid::int,
      _oldata  
    );
  
  _squery = concat('DELETE FROM ', _tablename, ' WHERE upper(id::varchar) = upper($1); ');
  EXECUTE format(_squery) USING _id::varchar;
END;
$_$;


ALTER FUNCTION framework.fn_deleterow(injson json) OWNER TO postgres;

--
-- TOC entry 270 (class 1255 OID 318998)
-- Name: fn_fapi(json, character varying, smallint, character, smallint); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_fapi(injson json, apititle character varying, apitype smallint, sessid character, primaryauthorization smallint DEFAULT NULL::smallint, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
	_userid varchar; -- user id
    fn_title varchar(350); -- function name
    _useroles json; -- user roles
    mroles json; -- method roles
    squery varchar; -- for dynamic sql query
    role_id smallint;
    _roles json;
BEGIN
	primaryauthorization = coalesce(primaryauthorization,0);
	SELECT
    	s.procedurename,
        s.roles
    FROM framework.spapi as s
    WHERE s.methodname = apititle and s.methodtype = apitype
    INTO fn_title, mroles;
     
    IF fn_title is NULL THEN
    	PERFORM raiserror('m404err');
    END IF; 
    
	SELECT 
    	s.userid::varchar,
        u.roles
    FROM framework.sess as s
    	JOIN framework.users as u on u.id = s.userid and u.isactive
    WHERE s.id = sessid and s.killed is null
    INTO _userid, _roles;
    
    IF mroles is not null and mroles::varchar <> '[]' THEN
    	IF _userid is null THEN
        	perform raiserror('m401err');
        END IF;
        
        IF (select count(*)  
           from json_array_elements_text(mroles) as a1
           		JOIN json_array_elements_text(_roles) as ur 
                	on a1.value::varchar(15)::smallint = ur.value::varchar(15)::smallint
              	)=0 THEN
        	perform raiserror('m403err');
        END IF;        
    END IF;   
    
    IF primaryauthorization = 1 and _userid is null THEN
    	perform raiserror('m401err');
    END IF; 
    

    
    SELECT injson::jsonb || 
    	   (SELECT row_to_json(d) FROM (SELECT _userid as userid) as d)::jsonb
    INTO injson;

    squery = concat('
        SELECT 
           row_to_json(d) 
         FROM
            ( 
               select *
               from ',fn_title,'($1)
            ) as d;'
    );
    
    EXECUTE format(squery) INTO outjson USING injson;
    
	outjson = coalesce(outjson,'[]');
END;
$_$;


ALTER FUNCTION framework.fn_fapi(injson json, apititle character varying, apitype smallint, sessid character, primaryauthorization smallint, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 271 (class 1255 OID 318999)
-- Name: fn_formparams(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_formparams(injson json, OUT tables json, OUT filtertypes json, OUT viewtypes json, OUT columntypes json) RETURNS record
    LANGUAGE plpgsql
    AS $$
--DECLARE

BEGIN

  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT 
      concat(TABLE_SCHEMA,'.',TABLE_NAME) as value,
      concat(TABLE_SCHEMA,'.',TABLE_NAME) as label, *
  FROM INFORMATION_SCHEMA.TABLES
  ORDER BY TABLE_SCHEMA, TABLE_NAME) as d
  INTO tables;
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (  SELECT 
  	ft.ftname as value,
    ft.ftname as label
  FROM framework.filtertypes as ft) as d
  INTO filtertypes;
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (
    SELECT vtypename as value, vtypename as label 
    FROM framework.viewtypes
    ) as d
    INTO viewtypes;
    
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM (
  SELECT 
  	typename as value, 
  	typename as label 
  FROM framework.columntypes
    ) as d
    INTO columntypes;
END;
$$;


ALTER FUNCTION framework.fn_formparams(injson json, OUT tables json, OUT filtertypes json, OUT viewtypes json, OUT columntypes json) OWNER TO postgres;

--
-- TOC entry 272 (class 1255 OID 319000)
-- Name: fn_formselect(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_formselect(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _config json;
  _inputs json;
  _val varchar;
  _id varchar;
  _relationcolums json;
  _relation varchar;
  squery varchar;
  col1 varchar;
  col2 varchar;
  pv json;
  select_condition json;
  _oper varchar(20);
  operval varchar;
  _ismulti boolean;
  _userid int;
  _orgs varchar;
  _orgid varchar;
BEGIN
	
  _config = injson->>'config';
  _inputs = injson->>'inputs';
  _val = injson->> 'val';
  _userid = injson->>'userid';
  _id = injson->>'id';
  _ismulti = injson->>'ismulti';
  _relation = coalesce(_config->>'multiselecttable',_config->>'relation');
  _relationcolums = coalesce(coalesce(_config->>'multicolums',_config->>'relationcolums'),'[]');
  --perform raiserror(_relationcolums::varchar);
  
  _ismulti = coalesce(_ismulti,false);

    
  IF _relation is null or _relationcolums is null or (SELECT count(*) 
  													  FROM json_array_elements_text(_relationcolums)) = 0 
  THEN
  	PERFORM raiserror('Something wrong here. Please check the config');	
  END IF;
  
  col1 = (_relationcolums->0)::json->>'value';
 
   IF (SELECT count(*)
   FROM information_schema.columns as t
   WHERE concat(t.table_schema,'.',t.table_name) = _relation and 
   		 t.column_name = col1) = 0 THEN
         PERFORM raiserror('error in config can not find table or col');
   END IF;      
 
  IF (SELECT count(*) FROM json_array_elements_text(_relationcolums)) = 1
  THEN 		
  
        squery = concat(squery,' SELECT ', col1, 
        	' as value, ',col1, ' as label FROM ', 
            _relation);  
            
  ELSE
		col2 = (_relationcolums->1)::json->>'value';
        IF (SELECT count(*)
        FROM information_schema.columns as t
        WHERE concat(t.table_schema,'.',t.table_name) = _relation and 
               t.column_name = col2) = 0 THEN
               PERFORM raiserror('error in config can not find table or col2');
        END IF; 
        IF  upper(col1) <> 'ID' THEN
			squery = concat(squery,' SELECT ' , 
            	col1 , 
                ' as value, concat(' , col1 ,
                ','' '', ', col2);
		ELSE
			squery =concat( squery,' SELECT ' , col1 , 
            	' as value, ' , col2);

  		END IF;
        
        SELECT 
        	array_to_json(array_agg(row_to_json(d)))
        FROM (
        SELECT value
        FROM
        (select 
        	row_number() over (order by 1) as n, * 
        from json_array_elements_text(_relationcolums) )as p
        where p.n not in (1,2)) as d
        INTO _relationcolums;
        
        /*FOR pv in (SELECT * FROM json_array_elements_text(_relationcolums))
        LOOP
        	squery = concat(squery, ', '' '' , ' ,pv->>'value');
        END LOOP;*/
		IF 	upper(col1)<> 'ID' THEN
			squery = concat(squery,') ');
        END IF;    
		squery = concat(squery, ' as label FROM ', _relation);

		IF _val is not null THEN
        	IF not _ismulti THEN
              _val = concat('%',upper(_val),'%');
              squery = concat(squery,' WHERE (upper(' , col2 , '::varchar) like $1 or upper(' , 
                              col1 , '::varchar) like $1'); 
              FOR pv in (SELECT * FROM json_array_elements_text(_relationcolums))
              LOOP
                  squery = concat(squery, ' or upper(' , pv->>'value' , '::varchar) like $1 ');
              END LOOP;   
            ELSE
            	squery = concat(squery, ' WHERE (upper(' , col2 , '::varchar) in 
                						(select upper(value::varchar) 
                                         from json_array_elements_text($1))' );
                FOR pv in (SELECT * FROM json_array_elements_text(_relationcolums))
                LOOP
                    squery = concat(squery, ' or upper(' , pv->>'value' , '::varchar) like 
                    					(select upper(value::varchar) 
                                         from json_array_elements_text($1)) ');
                END LOOP;                           
            END IF;
            squery = concat(squery, ') '); 
			IF _id is not null THEN
				squery = concat(squery,' and ' , col1 , ' = ''' , replace(_id::varchar ,'''',''''''), '''');
            END IF;    
		ELSE
			IF _id is not null THEN
				squery = concat(squery,' WHERE ', col1 , ' = ''' , replace(_id::varchar ,'''','''''') , ''' '); 
                --perform raiserror(squery);
            END IF;    	
        END IF;        
  END IF;	
  select_condition = _config->>'select_condition';
  IF _inputs is not null 
  	and select_condition is not null THEN
   -- perform raiserror('KAKA');
    IF squery not like '%WHERE%' THEN
    	squery = concat(squery,' WHERE ');
    ELSE
    	squery = concat(squery,' and ');
    END IF;    
        /*IF _val = '_userid_' THEN
    	_val = _userid;
    END IF;
    IF _val = '_orgs_' THEN
    	SELECT
        	u.orgs::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid
        INTO _val;
    END IF;
    IF _val = '_orgid_' THEN
    	SELECT
        	u.orgid::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid
        INTO _val;
    END IF;*/
    
    SELECT
       	u.orgs::varchar, u.orgid::varchar 
    FROM framework.users as u
    WHERE u.id = _userid
    INTO _orgs,_orgid;


    FOR pv in (SELECT * FROM json_array_elements_text(select_condition))
    LOOP
    	col1 = (pv->>'col')::json->>'label';
        _oper = (pv->>'operation')::json->>'value';
        operval = replace(replace(replace(replace(coalesce(pv->>'const'
        	, (_inputs->>((pv->>'value')::json->>'value'))),'''',''''''),'_orgid_',_orgid),'_userid_',_userid::varchar),'_orgs_',_orgs);
        IF (SELECT count(*)
        FROM information_schema.columns as t
        WHERE concat(t.table_schema,'.',t.table_name) = _relation and 
              t.column_name = col1) = 0 THEN
               PERFORM raiserror('error in config can not find table or col');
        END IF;  
        IF _oper not in ('like', 'in', 'not in', 'is null', 'is not null') THEN
	
          squery = concat(squery, ' ', col1, 
                          _oper , '''' , 
                          operval, ''' and');
        END IF;   
        IF _oper in ('is null','is not null') THEN
          squery = concat(squery, ' ', col1,' ', 
                          _oper , ' and');	
        END IF;    
        IF _oper = 'like' THEN
            squery = concat(squery, ' upper(', col1,') ',  
                          _oper , ' upper(''%%' , 
                          operval, '%%'') and');
        END IF;       
        IF _oper in ('in','not in') THEN
            squery = concat(squery, ' ', col1,' ',  
                          _oper , ' (', 
                (SELECT string_agg(concat('''',o.name::varchar,''''), ', ')
                 FROM json_array_elements(concat('[',operval,']')::json) as o), ') and');              
        END IF;  
            
    END LOOP;
    squery = substring(squery,1,length(squery)-3); 
  END IF;
  
  squery = concat('SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ',
  	squery, ' ) as d');
  --END IF;  
 -- perform raiserror(squery);
  EXECUTE format(squery) USING _val INTO outjson;-- USING injson;
     
  outjson = coalesce(outjson,'[]');
  
END;
$_$;


ALTER FUNCTION framework.fn_formselect(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 319002)
-- Name: fn_getacttypes(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getacttypes(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	SELECT 
      array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT 
    	actname as value, 
        actname as label 
    FROM framework.acttypes) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_getacttypes(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 319003)
-- Name: fn_getfunctions(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getfunctions(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (
  SELECT 
    f.funcname as label,
    f.funcname as value,
    f.functype
  FROM framework.functions as f
  UNION ALL
  SELECT 
  	format('%I.%I', ns.nspname, p.proname) as label,
    format('%I.%I', ns.nspname, p.proname) as name,
    'user' as functype 
  FROM pg_proc p 
  INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
  WHERE ns.nspname not in ('pg_catalog','information_schema')
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_getfunctions(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 275 (class 1255 OID 319004)
-- Name: fn_getselect(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getselect(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tabname varchar(350);
  _tabcolums varchar(1500);
  _squery varchar(1800);
BEGIN

	_tabname = injson->>'tabname';
    _tabcolums = injson->>'tabcolums';
    
  IF 
    (SELECT 
           count(t.*)
    FROM information_schema.columns as t                                         
    WHERE concat(t.table_schema,'.',t.table_name) = _tabname and 
    upper(t.column_name) = upper(_tabcolums)) = 0 THEN
  	perform raiserror('can not find table or column, please check input data');
  END IF;  

  _squery = concat(
  	'
    SELECT array_to_json(array_agg(row_to_json(d))) FROM
    (SELECT id as value, ' ,_tabcolums , ' as label FROM ', _tabname,') as d'
  );
  
  EXECUTE format(_squery) INTO outjson; 
  outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_getselect(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 319005)
-- Name: fn_htmldatatype(character varying); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_htmldatatype(sqldatatype character varying, OUT htmltype character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    htmltype = 'text';
	IF sqldatatype in (
    		'int',
            'integer', 
            'smallint', 
            'real', 
            'money', 
            'float', 
            'decimal', 
            'numeric', 
            'smallmoney', 
            'bigint',
            'double precision'
    ) THEN
    	 htmltype = 'number';
    END IF;     
	IF sqldatatype in (
    	'date',
        'time',
        'datetime2',
        'datetimeoffset',
        'smalldatetime',
        'datetime',
        'timestamp',
        'timestamp without time zone',
        'timestamp with time zone'
    ) THEN
    	 htmltype = 'date';
	END IF; 
    IF sqldatatype in ('bit','boolean') THEN
    	 htmltype = 'checkbox' ;   
    END IF; 
    	 
    
        
   -- RETURN htmltype
END;
$$;


ALTER FUNCTION framework.fn_htmldatatype(sqldatatype character varying, OUT htmltype character varying) OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 319006)
-- Name: fn_logout(character); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_logout(sesid character, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN

	UPDATE framework.sess
	SET killed = now()
    WHERE id = sesid;
    
    outjson = '{"message":"OK"}';

END;
$$;


ALTER FUNCTION framework.fn_logout(sesid character, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 278 (class 1255 OID 319007)
-- Name: fn_mainmenu(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_mainmenu(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _roles json;	
BEGIN
	_userid = injson->>'userid';
		
	SELECT
    	u.roles
    FROM framework.users as u
    WHERE u.id = _userid
    INTO _roles;
	
	SELECT
    	array_to_json(array_agg(row_to_json(d))) 
    FROM
      (SELECT 
        m.*,
        (SELECT count(m2.id) FROM framework.mainmenu as m2 WHERE m2.parentid = m.id) as childs
      FROM framework.mainmenu as m
      WHERE  
      ((SELECT count(*)
      			FROM json_array_elements_text(_roles) as r
                WHERE r.value::varchar = '0'
           		)>0     
      
      			 or 
      		 (SELECT count(*)
                			FROM json_array_elements_text(m.roles) as r
                             JOIN json_array_elements_text(_roles) as r2 on r2.value::varchar = r.value ::varchar 
                            )>0)
      ORDER BY m.orderby
      ) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_mainmenu(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 319008)
-- Name: fn_mainmenu_recurs(json, integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_mainmenu_recurs(_roles json, _parentid integer, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	SELECT
    	array_to_json(array_agg(row_to_json(d))) 
    FROM
      (SELECT 
        m.*,
        m.title as label,
        m.path as to,
        framework.fn_mainmenu_recurs(_roles,m.id) as items,
        (SELECT count(m2.id) FROM framework.mainmenu as m2 WHERE m2.parentid = m.id) as childs
      FROM framework.mainmenu as m
      WHERE  ((SELECT count(*)
      			FROM json_array_elements_text(_roles) as r
                WHERE r.value::varchar = '0'
           		)>0     
      
      			 or 
      		 (SELECT count(*)
                			FROM json_array_elements_text(m.roles) as r
                             JOIN json_array_elements_text(_roles) as r2 on r2.value::varchar = r.value ::varchar 
                            )>0)
      	and coalesce(m.parentid,0) = coalesce(_parentid,0)
      ORDER BY m.orderby
      ) as d
    INTO outjson;
END;
$$;


ALTER FUNCTION framework.fn_mainmenu_recurs(_roles json, _parentid integer, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 319009)
-- Name: fn_mainmenusigma(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_mainmenusigma(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _roles json;
  _usermenu json;
  _userdetail json;
BEGIN
	_userid = injson->>'userid';
		
	SELECT
    	u.roles
    FROM framework.users as u
    WHERE u.id = _userid
    INTO _roles;
	

    
	IF _userid is null THEN
    	SELECT 
				'[{"label": "Notifications", "icon": "pi pi-fw pi-inbox", "to":"/list/notifs"},
				{"label": "login", "icon": "pi pi-fw pi-power-off", "to": "/logout"}]' as usermenu
        INTO _usermenu;        
        
		SELECT row_to_json(d)
        FROM
        (SELECT 
        	'' as login,
            'unknown' as fam,
            '' as im,
            '' as ot,
            0 as orgid,
            '' as orgname,
            '' as photo,
            '{}' as usersettings) as d
         INTO _userdetail;   
    ELSE
    	SELECT 
				'[{"label": "Account", "icon": "pi pi-fw pi-user", "to": "/getone/account?id=_userid_"},
				{"label": "Notifications", "icon": "pi pi-fw pi-inbox", "to":"/list/notifs?userid=_userid_"},
                {"label": "My organization", "icon": "pi pi-fw pi-inbox", "to":"/getone/myorg?id=_orgid_"},
				{"label": "logout", "icon": "pi pi-fw pi-power-off", "to": "/logout"}]' as usermenu
        INTO _usermenu;  
        
        SELECT row_to_json(d)
        FROM
        (SELECT 
        	u.login,
            u.fam,
            u.im,
            u.ot,
            u.orgs,
            u.orgid,
        	o.orgname,
            (u.photo->0)::json->>'src' as photo,
            u.usersettings
        FROM framework.users as u
			JOIN framework.orgs as o on u.orgid = o.id 
        WHERE u.id = _userid) as d
        INTO _userdetail;
    END IF;    

    outjson = framework.fn_mainmenu_recurs(_roles, 0);

	SELECT
    	row_to_json(d)
    FROM
    (SELECT 
    	outjson as mainmenu,
        _userdetail as userdetail,
        coalesce(_usermenu,'[]') as usermenu) as d
    INTO outjson;    
    
    --outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_mainmenusigma(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 319010)
-- Name: fn_notif_setsended(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_notif_setsended(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	_id int; 
BEGIN
	_id = injson->>'id';
    
    UPDATE framework.viewsnotification
    SET sended = now(),
    	issend = true
    WHERE id = _id;
END;
$$;


ALTER FUNCTION framework.fn_notif_setsended(injson json) OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 319011)
-- Name: fn_refreshconfig(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_refreshconfig(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _oldconfig JSON;
  _newconfig JSON;
  _tabname varchar(350);
  ov json;
  nw json;
  isnotin boolean;
  isin boolean;
  i int;
BEGIN
	_oldconfig = injson->>'config';
	_tabname = injson->>'tabname';
    
    SELECT * FROM framework.fn_createconfig(injson) INTO _newconfig;
   -- perform raiserror(_newconfig::varchar);
    FOR nw in (SELECT * FROM json_array_elements_text(_newconfig))
    LOOP 
    	isnotin = true;
        FOR ov in (SELECT * FROM json_array_elements_text(_oldconfig))
        LOOP
			IF (ov->>'col')::varchar = (nw->>'col')::varchar and 
            	ov->>'related' is null and ov->>'tpath' is null
                 THEN
				isnotin = false;   
            END IF;
        END LOOP;
        
        IF isnotin THEN
        	SELECT _oldconfig::jsonb || nw::jsonb
            INTO _oldconfig;
		END IF;
    END LOOP;
    i = 0;
    FOR ov in (SELECT * FROM json_array_elements_text(_oldconfig))
    LOOP
    	
    	isin = true;
        FOR nw in (SELECT * FROM json_array_elements_text(_newconfig))
        LOOP
			IF (nw->>'col')::varchar = (ov->>'col')::varchar THEN
				isin = false;
            END IF;

        END LOOP;
        IF isin THEN
        	SELECT _oldconfig::jsonb - i
            INTO _oldconfig;
		END IF;
        i = i+1;
    END LOOP;
	
    outjson = _oldconfig;
    
    

END;
$$;


ALTER FUNCTION framework.fn_refreshconfig(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 319012)
-- Name: fn_savevalue(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_savevalue(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
_tablename varchar(300);
_col varchar(350);
_value varchar;
_id varchar(300);
_userid varchar(150);
_relatecolumn varchar(150);
_relatetable varchar(350);
_squery varchar;
_err varchar;
_oldata json;
_newdata json;
_id_int int;
_col_type varchar(300);
rel_id varchar(36);
_id_type varchar(150);
rel_id_type varchar(150);
_viewid int;
_userroles json;
_viewroles json;
_type varchar(150);
BEGIN
  _tablename = injson->>'tablename';
  _col = (injson->>'config')::json->>'col';
  _value = injson->>'value';
  _id = injson->>'id';
  _userid = injson->>'userid';
  _relatecolumn = (injson->>'config')::json->>'relatecolumn';
  _relatetable = injson->>'relatetable';
  _viewid = injson->>'viewid';
  _type = (injson->>'config')::json->>'type';
    IF _value = '_userid_' THEN
    	_value = _userid;
    END IF;
    IF _value = '_orgs_' THEN
    	SELECT
        	u.orgs::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid
        INTO _value;
    END IF;
    IF _value = '_orgid_' THEN
    	SELECT
        	u.orgid::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid
        INTO _value;
    END IF;
    IF _viewid is NULL
    THEN
      perform raiserror('view id is null');
    END IF; 
    
    SELECT 
    	roles
    FROM framework.views 
    WHERE id = _viewid
    INTO _viewroles;
    
    SELECT 
    	roles
    FROM framework.users 
    WHERE id::varchar = _userid
    INTO _userroles;
    
    IF _viewroles is null THEN
    	perform raiserror('view is not found');
    END IF;
    
    IF (SELECT count(*) FROM json_array_elements_text(_viewroles)) > 0 and 
    (SELECT count(*) 
     FROM json_array_elements_text(_viewroles) as v
     	JOIN json_array_elements_text(_userroles) as r on (v.value::json->>'value')::varchar = r.value::varchar
     ) = 0 THEN
    	PERFORM raiserror('m403err');
    END IF;
    
    IF _tablename is NULL
    THEN
      perform raiserror('table is null');
    END IF; 
    
    IF _col is NULL
    THEN
      perform raiserror('col is null');
    END IF;
      
    IF _relatetable is not null and _id is null
    THEN
      perform raiserror('id can`t be null if relation');
    END IF;
   
   SELECT t.data_type
   FROM information_schema.columns as t
   WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
   		 t.column_name = _col
   INTO _col_type; 	
   
   IF _col_type is null THEN
   	 perform raiserror('can not find out the column type. check table and column names');
   END IF;
  
  SELECT 
     t.data_type
  FROM information_schema.columns as t                                         
  WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
  upper(t.column_name) = 'ID'
  INTO _id_type;
  
  IF _type = 'password' THEN
     drop extension pgcrypto;
     create extension pgcrypto;
     SELECT encode(digest(_value, 'sha224'),'hex') INTO _value;
  END IF;
  
  IF _relatetable is not null
  THEN    
  	
  	 IF _relatecolumn is null THEN
     	perform raiserror('can''t find relate column');
     END IF;	
      
     SELECT 
         t.data_type
     FROM information_schema.columns as t                                         
     WHERE concat(t.table_schema,'.',t.table_name) = _relatetable and 
     upper(t.column_name) = 'ID'
     INTO rel_id_type;
     
     IF rel_id_type is null THEN
       perform raiserror('can not find out the relation ID type. check table and column names');
     END IF;
     
      _squery = concat(_squery,'
          SELECT 
               ',_relatecolumn,'::',_id_type,'
          FROM ',_relatetable,'
          WHERE id::',rel_id_type,' = $1::',rel_id_type,';
      ');
      
      EXECUTE format(_squery) USING _id INTO rel_id;
      
      IF trim(coalesce(rel_id,'')) = ''
      THEN
          perform raiserror('id of relation table can not be NULL');
      END IF;
      
      _squery = concat('
          SELECT row_to_json(d) FROM	
          (SELECT 
            ',_col,'
          FROM ',_tablename,'
          WHERE id = $1::',_id_type,' ) as d;');
          
      EXECUTE format(_squery) USING rel_id INTO _oldata;
      
      _squery = concat('SELECT row_to_json(d) FROM 
          (SELECT $1 as ',_col,') as d;');
      
      EXECUTE format(_squery) USING _value INTO _newdata; 
     
      INSERT INTO framework.logtable (
         tablename,
         tableid,
         opertype,
         userid,
         oldata,
         newdata,
         colname
      ) VALUES (
         _tablename ,
         rel_id,
         2,
         _userid::int,
         _oldata,
         _newdata,
         _col      
      ); 
     IF (SELECT count(t.*)
      FROM information_schema.columns as t
      WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
           t.column_name = 'userid')>0 THEN
     _squery = concat('          
          UPDATE ', _tablename, ' 
          SET ',_col,' = $2::',_col_type,' , userid = $3 
          WHERE id::',_id_type,' = $1::',_id_type,'; 
      ');	
      EXECUTE format(_squery) USING rel_id,_value, _userid::int;
      ELSE
	  	     _squery = concat('          
          UPDATE ', _tablename, ' 
          SET ',_col,' = $2::',_col_type,'
          WHERE id::',_id_type,' = $1::',_id_type,'; 
      ');
      EXECUTE format(_squery) USING rel_id,_value;
     END IF; 
       
     
   
  ELSE  

    IF _id is NULL
    THEN
      IF _value is null 
      THEN
        perform raiserror('value is null');
      END IF;
      	
      IF _id_type = 'character' 
      THEN
      	   _id = uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36);
      ELSE
      	   EXECUTE format(concat('SELECT nextval(''',_tablename,'_id_seq''::regclass);')) INTO _id_int ;
           _id = _id_int::varchar;
      END IF;   
     IF (SELECT count(t.*)
      FROM information_schema.columns as t
      WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
           t.column_name = 'userid')>0 THEN
        _squery = concat('INSERT INTO ', _tablename, '(id,',_col,', userid) 
                          VALUES ($1::',_id_type,',$2::',_col_type,',$3); ');  
                            
        EXECUTE format(_squery) USING _id,_value, _userid::int;
     ELSE
        _squery = concat('INSERT INTO ', _tablename, '(id,',_col,') 
                          VALUES ($1::',_id_type,',$2::',_col_type,'); ');  
                          
     	EXECUTE format(_squery) USING _id,_value;
     END IF;   
         
      _squery = concat('SELECT row_to_json(d) FROM 
                        (SELECT $1 as ',_col,') as d;');
              
       EXECUTE format(_squery) USING _value INTO _newdata;
                 
       INSERT INTO framework.logtable (
             tablename,
             tableid,
             opertype,
             userid,
             newdata,
             colname
       ) VALUES (
             _tablename ,
             _id,
              '1',
             _userid::int,
             _newdata ,
             _col
       );             
           	
  	ELSE
    
    	IF trim(coalesce(_id,'')) = '' THEN
        	perform raiserror('id is null');
        END IF;
     IF (SELECT count(t.*)
      FROM information_schema.columns as t
      WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
           t.column_name = 'userid')>0 THEN
         _squery = concat( ' UPDATE ', _tablename, ' 
         					 SET ',_col,' = $2::',_col_type,' , userid = $3
                             WHERE id::',_id_type,' = $1::',_id_type,';                                
                              ');
							
         EXECUTE format(_squery) USING _id,_value, _userid::int; 
      ELSE
         _squery = concat( ' UPDATE ', _tablename, ' 
         					 SET ',_col,' = $2::',_col_type,' 
                             WHERE id::',_id_type,' = $1::',_id_type,';                                
                              ');
		--PERFORM raiserror(_value::varchar);
         EXECUTE format(_squery) USING _id,_value; 
        -- commit;
      END IF;   
         _squery = concat('SELECT row_to_json(d) FROM	
                      (SELECT 
                        ',_col,'
                      FROM ',_tablename,'
                      WHERE id = $1::',_id_type,') as d;');
         EXECUTE format(_squery) USING _id INTO _oldata;    
    
  

         --perform raiserror(_squery);
        _squery = concat('SELECT row_to_json(d) FROM 
                  (SELECT $1 as ',_col,') as d;');                
        EXECUTE format(_squery) USING _value INTO _newdata;
          
        INSERT INTO framework.logtable (
              tablename,
              tableid,
              opertype,
              userid,
              oldata,
              newdata,
              colname
        ) VALUES (
              _tablename ,
              _id,
               2,
              _userid::int,
              _oldata,
              _newdata,
              _col
        );         
    END IF;
  END IF; 
  
  --EXECUTE format(_squery) USING _id,_value;--INTO outjson;    
  
  SElECT
  	row_to_json(d)
  FROM (
  	SELECT _id as id,
    	_value as value
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'{}');
  
END;
$_$;


ALTER FUNCTION framework.fn_savevalue(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 284 (class 1255 OID 319014)
-- Name: fn_sess(character varying, character varying); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_sess(_login character varying, pass character varying, OUT sessid character) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
  user_id int;
  _orgid int;
BEGIN

	SELECT 
    	u.id,
        u.orgs->0
    FROM framework.users as u
    WHERE u.isactive and u.login = _login and u.password = pass
    INTO user_id, _orgid;
    
    IF user_id is null THEN
    	perform raiserror('User not active or not found. Check login password combination');
    END IF;
    
    sessid = uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36);
    
    INSERT INTO framework.sess
    (
    	id,
        userid
    )
    VALUES 
    (
    	sessid,
        user_id
    );
    
    UPDATE framework.users
    SET orgid = _orgid
    WHERE orgid is null and id = user_id;

END;
$$;


ALTER FUNCTION framework.fn_sess(_login character varying, pass character varying, OUT sessid character) OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 319015)
-- Name: fn_tabcolumns(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tabname varchar(150);
BEGIN
  _tabname = injson->>'tabname';

  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 286 (class 1255 OID 319016)
-- Name: fn_trees_bypath(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_trees_bypath(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _path varchar(350);
  _roles json;
BEGIN
  _userid = injson->>'userid';
  _path = injson->>'path';
  SELECT
  	u.roles
  FROM framework.users as u
  WHERE u.id = _userid
  INTO _roles;
  
  
  SELECT 
  	row_to_json(d)
  FROM
  (SELECT 
  	t.id,
    t.title,
    t.descr,
    
    framework.fn_branchestree_recurs(0,t.id) as branches,
	(SELECT
    	array_to_json(array_agg(row_to_json(d))) 
      FROM
      (SELECT
          tb.id as key, 
          tb.icon,
          tb.parentid,
          tb.treesid,
          tb.title as label,
      	  tb.treeviewtype,
          coalesce(v.path,c.path) as path,
          v.viewtype
      FROM framework.treesbranches as tb
      	LEFT JOIN framework.views as v on v.id = tb.viewid
        LEFT JOIN framework.compos as c on c.id = tb.compoid
      WHERE tb.treesid = t.id and tb.title is not null) as d) as  items  
  FROM framework.trees as t
  WHERE t.url = _path and (t.roles is null
  or 
  (SELECT count(*)
  FROM json_array_elements_text(t.roles) as t1) = 0 
  or
  (SELECT count(*)
  FROM json_array_elements_text(t.roles) as t1
  	JOIN json_array_elements_text(_roles) as t2 on 
    					t1.value::varchar::int = t2.value::varchar::int 
    					or t2.value::varchar::int = '0')>0)
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'{}');
  
END;
$$;


ALTER FUNCTION framework.fn_trees_bypath(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 287 (class 1255 OID 319017)
-- Name: fn_userjson(character); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_userjson(sessid character, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN

	SELECT row_to_json(d)
    FROM
    (SELECT
    	u.roles,
        orgs as orgs,
        u.id,
        u.fam,
        u.im,
        u.ot,
        u.login,
        u.usersettings,
        u.orgid
    FROM framework.sess as s
    	JOIN framework.users as u on u.id = s.userid
    WHERE upper(s.id) = upper(sessid) and u.isactive) as d
    INTO outjson;
    IF outjson is null THEN
    	perform raiserror('m401err');
    END IF;
    outjson = coalesce(outjson,'{}');
	

END;
$$;


ALTER FUNCTION framework.fn_userjson(sessid character, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 288 (class 1255 OID 319018)
-- Name: fn_userorg_upd(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_userorg_upd(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _orgid int;
  userid int;
BEGIN
	_orgid = injson->>'orgid';
	userid = injson->>'userid';
    
    UPDATE framework.users
    SET orgid = _orgid
    WHERE id = userid;

END;
$$;


ALTER FUNCTION framework.fn_userorg_upd(injson json) OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 319019)
-- Name: fn_userorgs(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_userorgs(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _orgs json;
  _roles JSON;
BEGIN
	_userid = injson->>'userid';
	
    SELECT
    	u.roles,
        u.orgs
    FROM framework.users as u
    WHERE u.id = _userid
    INTO _roles,_orgs;
    
    IF (SELECT count(*) 
        FROM json_array_elements_text(_roles) 
        WHERE VALUE::varchar = '0') = 0 THEN
    	SELECT
        	array_to_json(array_agg(row_to_json(d))) 
        FROM
        (SELECT
        	o.id as value,
            o.orgname as label
        FROM framework.orgs as o
        	JOIN json_array_elements_text(_orgs)  as o1 on o1.value::varchar::int = o.id) as d
        INTO outjson;    
    ELSE
    	SELECT
        	array_to_json(array_agg(row_to_json(d))) 
        FROM
        (SELECT
        	o.id as value,
            o.orgname as label
        FROM framework.orgs as o) as d
        INTO outjson;  
    END IF;    
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_userorgs(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 290 (class 1255 OID 319020)
-- Name: fn_view_byid(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_byid(injson json, OUT outjson json, OUT roles json) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_id int;
BEGIN
  _id = injson->>'id'; 	
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT id as value, rolename as label 
  FROM  framework.roles) as d
  INTO roles; 

  SELECT 
  	row_to_json(d)
  FROM
  (SELECT 
    	v.id,
        v.title,
        v.tablename,
        v.descr,
        v.path,
        v.pagination,
        v.viewtype,
        v.config,
        v.orderby,
        v.groupby,
        v.filters,
        v.acts,
        v.roles,
        v.classname,
        v.ispagesize,
        v.pagecount,
        v.foundcount,
        v.subscrible
    FROM framework.views as v
    WHERE v.id = _id) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'{}');
END;
$$;


ALTER FUNCTION framework.fn_view_byid(injson json, OUT outjson json, OUT roles json) OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 319021)
-- Name: fn_viewnotif_get(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_viewnotif_get(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _viewid int;
  _userid int;
  viewpath varchar;
  ids json;
BEGIN
	viewpath = injson->>'viewpath';
 	_userid = injson->>'userid';   
    ids = injson->>'ids';

	IF viewpath is null THEN
    	perform raiserror('no viewpath');
    END IF;
     
	SELECT 
    	v.id
    FROM framework.views as v
	WHERE v.path = viewpath
    INTO _viewid;
    
	IF _viewid is null THEN
    	perform raiserror('no viewid');
    END IF;
    
    SELECT array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT *
    FROM framework.viewsnotification as v
    	LEFT JOIN json_array_elements_text(ids) as n on (n.value::varchar = v.tableid or v.tableid is null)
    WHERE v.viewid = _viewid and 
    	 (v.foruser = _userid or v.foruser is null) and not v.isread and not v.issend
     ) as d    
     INTO outjson; 
	
    outjson = COALESCE(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_viewnotif_get(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 319022)
-- Name: fn_viewsave(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_viewsave(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id int ;
  _title varchar(150) ;
  _descr varchar(1500) ;
  _tablename varchar(350) ;
  _viewtype varchar(200) ;
  _pagination boolean ;
  _config JSON ;
  _path varchar(150) ;
  _orderby boolean ;
  _pagesize boolean ;
  _pagecount boolean ;
  _foundcount boolean ;
  _subscrible boolean;
  
  _groupby JSON ;
  _filters JSON ;
  _acts JSON ;
  _roles JSON ;
  _classname varchar(400) ;
  _userid varchar(250) ;
  _newdata json;
  _oldata json;
BEGIN
  _id  = injson->>'id';
  _title  = injson->>'title';
  _descr  = injson->>'descr';
  _tablename  = injson->>'tablename';
  _viewtype  = injson->>'viewtype';
  _pagination  = injson->>'pagination';
  _config = injson->>'config';
  _path = injson->>'path';
  _orderby = injson->>'orderby';
  _groupby = injson->>'groupby';
  _filters = injson->>'filters';
  _acts = injson->>'acts';
  _roles = injson->>'roles';
  _classname = injson->>'classname';
  _userid = injson->>'userid';
  _pagesize = injson->>'ispagesize';
  _pagecount = injson->>'pagecount';
  _foundcount = injson->>'foundcount';
  _subscrible = injson->>'subscrible';
 IF _id is null THEN
  
    IF coalesce(_title,'') = '' THEN
        PERFORM raiserror('title is null');
    END IF;
      
    IF coalesce(_descr,'') = '' THEN
        PERFORM raiserror('descr is null');
    END IF;
      
    IF coalesce(_tablename,'') = '' THEN
        perform raiserror('tablename is null');  
    END IF;
      
    IF coalesce(_viewtype,'') = '' THEN
        perform raiserror('viewtype is null');
    END IF;    

    _pagination = coalesce(_pagination,false);

    IF coalesce(_config::varchar,'[]') = '[]' THEN
    	perform raiserror('config is null');	
    END IF;
    
    IF _path is null THEN
    	perform raiserror('path is null');
    END IF;  
    
    _orderby = coalesce(_orderby,false);
    _pagesize = coalesce(_pagesize,true);
    _pagecount = coalesce(_pagecount,true);
    _foundcount = coalesce(_foundcount,true);
    _subscrible = coalesce(_subscrible,false);
    
    _groupby = coalesce(_groupby,'[]');
    _roles = coalesce(_roles,'[]');
    _filters = coalesce(_filters,'[]');
	_acts = coalesce(_acts,'[]');
    
    IF (SELECT 
        count(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE concat('',TABLE_SCHEMA,'.', TABLE_NAME) = _tablename) = 0
    THEN
      perform raiserror('table is not exist');
    END IF;
    
    _id = nextval('framework.views_id_seq'::regclass);
	   

    INSERT INTO framework.views (
    	id,
      title ,
      descr ,
      tablename ,
      viewtype ,
      pagination ,
      config ,
      "path" ,
      orderby ,
      groupby ,
      filters ,
      acts,
      roles,
      classname,
      ispagesize,
      pagecount,
      foundcount,
      subscrible
    )
    VALUES (
      _id,	
      _title ,
      _descr ,
      _tablename ,
      _viewtype ,
      _pagination ,
      _config ,
      _path ,
      _orderby ,
      _groupby ,
      _filters ,
      _acts,
      _roles,
      _classname,
      _pagesize,
      _pagecount,
      _foundcount ,
      _subscrible     
    );
    

    _newdata  = (
      SELECT row_to_json(d) 
      FROM 
      (SELECT *
      FROM framework.views  
      WHERE id = _id) as d
    );
  	INSERT INTO framework.logtable (
      tablename,
      tableid,
      opertype,
      userid,
      newdata
    ) VALUES (
      'framework.views',
      _id::varchar(150),
      '1',
      _userid::int ,
     _newdata   
    );
	outjson = (select row_to_json(d) from ( select _id as id) as d);
  ELSE
     _oldata = (
        SELECT row_to_json(d)
        FROM
        (SELECT * 
        FROM framework.views  
        WHERE id = _id) as d

      );

      
      UPDATE framework.views 
      SET
        title = coalesce(_title,title),
        descr = coalesce(_descr,descr),
        viewtype = coalesce(_viewtype,viewtype),
        pagination = coalesce(_pagination,pagination),
        config = coalesce(_config,config),
        "path" = coalesce(_path,"path"),
        orderby = coalesce(_orderby,orderby),
        groupby = coalesce(_groupby,'[]'),
        filters = coalesce(_filters,'[]'),
        acts = coalesce(_acts,'[]'),
        roles = coalesce(_roles,'[]'),
        classname = _classname,
        ispagesize = coalesce(_pagesize,ispagesize),
        pagecount = coalesce(_pagecount,pagecount),  
        foundcount = coalesce(_foundcount,foundcount),
        subscrible = coalesce(_subscrible,subscrible) 
      WHERE id = _id;
      
      _newdata = (
      	SELECT
        	row_to_json(d)
        FROM
        (SELECT * 
        FROM framework.views  
        WHERE id = _id) as d
       
      );
      
      IF _oldata::varchar <> _newdata::varchar THEN
        INSERT INTO framework.logtable (
          tablename,
          tableid,
          opertype,
          userid,
          oldata,
          newdata
        ) VALUES (
          'framework.views',
          _id::varchar(150),
          '2',
          _userid::int ,
         _oldata,
         _newdata   
        );
    END IF;
  END IF; 
END;
$$;


ALTER FUNCTION framework.fn_viewsave(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 319023)
-- Name: get_colcongif(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION get_colcongif(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  col varchar(350);
  _table varchar(350);
  
BEGIN
  col = injson->>'col';
  _table = injson->>'table';
  SELECT
  	row_to_json(d) 
  FROM
  (SELECT 
      	CASE WHEN y.table_schema is not null 
            THEN  concat(y.table_schema , '.' , y.table_name)
             ELSE y.table_schema
        END		
      as relation      
 FROM information_schema.columns as t
 	  left join pg_catalog.pg_statio_all_tables as st on 
      		st.schemaname = t.table_schema 
      		and st.relname = t.table_name	
 	  left join pg_catalog.pg_description pgd on pgd.objoid=st.relid
			and pgd.objsubid=t.ordinal_position
       left join information_schema.table_constraints as c on c.table_name = t.table_name
      	and c.table_schema = t.table_schema and c.constraint_type = 'FOREIGN KEY'
         
      LEFT JOIN information_schema.key_column_usage AS x ON 
      c.constraint_name = x.constraint_name and x.column_name = t.column_name                        
	  LEFT JOIN information_schema.constraint_column_usage 
        AS y ON y.constraint_name = c.constraint_name and x.column_name = t.column_name 
                                 
 WHERE concat(t.table_schema,'.',t.table_name) = _table and t.column_name = col) as d
 INTO outjson;
 
 outjson = coalesce(outjson,'{}');

END;
$$;


ALTER FUNCTION framework.get_colcongif(injson json, OUT outjson json) OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 294 (class 1255 OID 319025)
-- Name: fn_trees_add_org(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_trees_add_org() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _orgid int;
BEGIN
	SELECT 
    	orgid
    FROM framework.users
    WHERE id = NEW.userid
    INTO _orgid;
    
    UPDATE framework.trees
    SET orgid = _orgid
    WHERE id = NEW.id;
    
    return null;
END;
$$;


ALTER FUNCTION public.fn_trees_add_org() OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 319026)
-- Name: fn_treesbranch_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_treesbranch_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.compoid is not null and NEW.viewid is not null THEN
    	PERFORM raiserror('You cannot add compo and simple view at same branches');
    END IF;
	return 	NULL;

END;
$$;


ALTER FUNCTION public.fn_treesbranch_check() OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 319027)
-- Name: fn_user_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_user_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF (SELECT count(*) FROM json_array_elements_text(NEW.roles)) = 0 THEN
    	perform raiserror('no roles');
    END IF;
    
	IF coalesce(NEW.password,'') = '' THEN
    	perform raiserror('password can not be empty');
    END IF;
    return null;
END;
$$;


ALTER FUNCTION public.fn_user_check() OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 319028)
-- Name: raiserror(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION raiserror(_hint character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	RAISE EXCEPTION 'usererror' USING HINT=concat(_hint,'+++___');
END;
$$;


ALTER FUNCTION public.raiserror(_hint character varying) OWNER TO postgres;

SET search_path = framework, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 183 (class 1259 OID 319059)
-- Name: acttypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE acttypes (
    id smallint NOT NULL,
    actname character varying(150) NOT NULL
);


ALTER TABLE acttypes OWNER TO postgres;

--
-- TOC entry 184 (class 1259 OID 319062)
-- Name: columntypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE columntypes (
    id integer DEFAULT nextval(('framework.columntypes_id_seq'::text)::regclass) NOT NULL,
    typename character varying(100) NOT NULL
);


ALTER TABLE columntypes OWNER TO postgres;

--
-- TOC entry 185 (class 1259 OID 319066)
-- Name: columntypes_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE columntypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE columntypes_id_seq OWNER TO postgres;

--
-- TOC entry 186 (class 1259 OID 319068)
-- Name: compos; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE compos (
    id integer DEFAULT nextval(('framework.compos_id_seq'::text)::regclass) NOT NULL,
    title character varying(250) NOT NULL,
    path character varying(250) NOT NULL,
    config json DEFAULT '[]'::json NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE compos OWNER TO postgres;

--
-- TOC entry 187 (class 1259 OID 319077)
-- Name: compos_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE compos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE compos_id_seq OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 319079)
-- Name: filtertypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE filtertypes (
    id smallint NOT NULL,
    ftname character varying(150) NOT NULL
);


ALTER TABLE filtertypes OWNER TO postgres;

--
-- TOC entry 189 (class 1259 OID 319082)
-- Name: functions; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE functions (
    id smallint NOT NULL,
    funcname character varying(15) NOT NULL,
    functype character varying(15) NOT NULL
);


ALTER TABLE functions OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 319085)
-- Name: logtable; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE logtable (
    id integer DEFAULT nextval(('framework.logtable_id_seq'::text)::regclass) NOT NULL,
    tablename character varying(250) NOT NULL,
    tableid character varying(150) NOT NULL,
    opertype smallint NOT NULL,
    oldata json,
    newdata json,
    created timestamp without time zone DEFAULT now() NOT NULL,
    colname character varying(150),
    userid integer NOT NULL
);


ALTER TABLE logtable OWNER TO postgres;

--
-- TOC entry 191 (class 1259 OID 319093)
-- Name: logtable_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE logtable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE logtable_id_seq OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 319095)
-- Name: mainmenu; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE mainmenu (
    id integer NOT NULL,
    title character varying(150) DEFAULT 'untitled'::character varying NOT NULL,
    parentid integer,
    created timestamp without time zone DEFAULT now() NOT NULL,
    systemfield boolean DEFAULT false,
    orderby smallint DEFAULT 0 NOT NULL,
    path character varying(150) DEFAULT '/'::character varying NOT NULL,
    roles json,
    icon character varying(150)
);


ALTER TABLE mainmenu OWNER TO postgres;

--
-- TOC entry 193 (class 1259 OID 319106)
-- Name: mainmenu_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE mainmenu_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mainmenu_id_seq OWNER TO postgres;

--
-- TOC entry 2453 (class 0 OID 0)
-- Dependencies: 193
-- Name: mainmenu_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE mainmenu_id_seq OWNED BY mainmenu.id;


--
-- TOC entry 194 (class 1259 OID 319108)
-- Name: methodtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE methodtypes (
    id smallint NOT NULL,
    methotypename character varying(350) NOT NULL
);


ALTER TABLE methodtypes OWNER TO postgres;

--
-- TOC entry 195 (class 1259 OID 319111)
-- Name: opertypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE opertypes (
    id smallint NOT NULL,
    typename character varying(150) NOT NULL,
    alias character varying(150)
);


ALTER TABLE opertypes OWNER TO postgres;

--
-- TOC entry 196 (class 1259 OID 319114)
-- Name: orgs; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE orgs (
    id integer DEFAULT nextval(('framework.orgs_id_seq'::text)::regclass) NOT NULL,
    orgname character varying(350) NOT NULL
);


ALTER TABLE orgs OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 319118)
-- Name: orgs_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE orgs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE orgs_id_seq OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 319125)
-- Name: roles; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE roles (
    id smallint NOT NULL,
    rolename character varying(250) NOT NULL
);


ALTER TABLE roles OWNER TO postgres;

--
-- TOC entry 199 (class 1259 OID 319128)
-- Name: sess; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE sess (
    id character(36) NOT NULL,
    userid integer NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    killed timestamp without time zone
);


ALTER TABLE sess OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 319132)
-- Name: spapi; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE spapi (
    id integer NOT NULL,
    methodname character varying(350),
    procedurename character varying(350),
    created timestamp without time zone DEFAULT now() NOT NULL,
    methodtype smallint DEFAULT '1'::smallint NOT NULL,
    roles json
);


ALTER TABLE spapi OWNER TO postgres;

--
-- TOC entry 2454 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN spapi.id; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN spapi.id IS '№';


--
-- TOC entry 201 (class 1259 OID 319140)
-- Name: spapi_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE spapi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE spapi_id_seq OWNER TO postgres;

--
-- TOC entry 2455 (class 0 OID 0)
-- Dependencies: 201
-- Name: spapi_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE spapi_id_seq OWNED BY spapi.id;


--
-- TOC entry 202 (class 1259 OID 319148)
-- Name: trees; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE trees (
    id integer NOT NULL,
    title character varying(350),
    url character varying(350),
    descr text,
    roles json DEFAULT '[]'::json NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    userid integer,
    orgid integer
);


ALTER TABLE trees OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 319156)
-- Name: trees_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE trees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE trees_id_seq OWNER TO postgres;

--
-- TOC entry 2456 (class 0 OID 0)
-- Dependencies: 203
-- Name: trees_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE trees_id_seq OWNED BY trees.id;


--
-- TOC entry 204 (class 1259 OID 319158)
-- Name: treesbranches; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE treesbranches (
    id integer NOT NULL,
    treesid integer NOT NULL,
    title character varying(350),
    parentid integer,
    icon character varying(150),
    created timestamp without time zone DEFAULT now() NOT NULL,
    treeviewtype smallint,
    viewid integer,
    compoid integer
);


ALTER TABLE treesbranches OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 319165)
-- Name: treesbranches_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE treesbranches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE treesbranches_id_seq OWNER TO postgres;

--
-- TOC entry 2457 (class 0 OID 0)
-- Dependencies: 205
-- Name: treesbranches_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE treesbranches_id_seq OWNED BY treesbranches.id;


--
-- TOC entry 206 (class 1259 OID 319167)
-- Name: treeviewtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE treeviewtypes (
    id smallint NOT NULL,
    typename character varying(35) NOT NULL
);


ALTER TABLE treeviewtypes OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 319170)
-- Name: users; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE users (
    id integer NOT NULL,
    fam character varying(150) DEFAULT ''::character varying NOT NULL,
    im character varying(150) DEFAULT ''::character varying NOT NULL,
    ot character varying(150) DEFAULT ''::character varying,
    login character varying(150),
    password character varying,
    isactive boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    roles json DEFAULT '[]'::json NOT NULL,
    roleid smallint,
    photo json,
    orgs json DEFAULT '[]'::json NOT NULL,
    usersettings json DEFAULT '{}'::json NOT NULL,
    orgid integer
);


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 319184)
-- Name: users_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO postgres;

--
-- TOC entry 2458 (class 0 OID 0)
-- Dependencies: 208
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 209 (class 1259 OID 319186)
-- Name: views; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE views (
    id integer NOT NULL,
    title character varying(150) NOT NULL,
    descr character varying(1500),
    tablename character varying(350) NOT NULL,
    viewtype character varying(200) NOT NULL,
    pagination boolean DEFAULT false NOT NULL,
    config json DEFAULT '[]'::json NOT NULL,
    path character varying(150) DEFAULT ''::character varying NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    groupby json DEFAULT '[]'::json NOT NULL,
    filters json DEFAULT '[]'::json NOT NULL,
    acts json DEFAULT '[]'::json NOT NULL,
    roles json DEFAULT '[]'::json NOT NULL,
    classname character varying(400),
    orderby boolean DEFAULT false NOT NULL,
    ispagesize boolean DEFAULT true NOT NULL,
    pagecount boolean DEFAULT true NOT NULL,
    foundcount boolean DEFAULT true NOT NULL,
    subscrible boolean DEFAULT false NOT NULL
);


ALTER TABLE views OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 319205)
-- Name: views_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE views_id_seq OWNER TO postgres;

--
-- TOC entry 2459 (class 0 OID 0)
-- Dependencies: 210
-- Name: views_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE views_id_seq OWNED BY views.id;


--
-- TOC entry 211 (class 1259 OID 319207)
-- Name: viewsnotification; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE viewsnotification (
    id integer NOT NULL,
    viewid integer NOT NULL,
    col character varying(150),
    tableid character varying(36),
    notificationtext text DEFAULT ''::text,
    foruser integer,
    issend boolean DEFAULT false NOT NULL,
    isread boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    sended timestamp without time zone,
    readed timestamp without time zone
);


ALTER TABLE viewsnotification OWNER TO postgres;

--
-- TOC entry 2460 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE viewsnotification; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE viewsnotification IS 'notifications for views on ws 
you can add here notification for different views on triggers';


--
-- TOC entry 212 (class 1259 OID 319217)
-- Name: viewsnotification_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE viewsnotification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viewsnotification_id_seq OWNER TO postgres;

--
-- TOC entry 2461 (class 0 OID 0)
-- Dependencies: 212
-- Name: viewsnotification_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE viewsnotification_id_seq OWNED BY viewsnotification.id;


--
-- TOC entry 213 (class 1259 OID 319219)
-- Name: viewtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE viewtypes (
    id smallint NOT NULL,
    vtypename character varying(200) NOT NULL,
    viewlink character varying(350)
);


ALTER TABLE viewtypes OWNER TO postgres;

--
-- TOC entry 2208 (class 2604 OID 319261)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY mainmenu ALTER COLUMN id SET DEFAULT nextval('mainmenu_id_seq'::regclass);


--
-- TOC entry 2213 (class 2604 OID 319263)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY spapi ALTER COLUMN id SET DEFAULT nextval('spapi_id_seq'::regclass);


--
-- TOC entry 2216 (class 2604 OID 319264)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY trees ALTER COLUMN id SET DEFAULT nextval('trees_id_seq'::regclass);


--
-- TOC entry 2218 (class 2604 OID 319265)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches ALTER COLUMN id SET DEFAULT nextval('treesbranches_id_seq'::regclass);


--
-- TOC entry 2227 (class 2604 OID 319266)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 2241 (class 2604 OID 319267)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY views ALTER COLUMN id SET DEFAULT nextval('views_id_seq'::regclass);


--
-- TOC entry 2246 (class 2604 OID 319268)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewsnotification ALTER COLUMN id SET DEFAULT nextval('viewsnotification_id_seq'::regclass);


--
-- TOC entry 2413 (class 0 OID 319059)
-- Dependencies: 183
-- Data for Name: acttypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY acttypes (id, actname) FROM stdin;
1	API
2	Link
3	Print Data
4	Delete
\.


--
-- TOC entry 2414 (class 0 OID 319062)
-- Dependencies: 184
-- Data for Name: columntypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY columntypes (id, typename) FROM stdin;
1	text
2	number
3	date
4	checkbox
5	select
6	typehead
7	array
8	label
9	password
10	autocomplete
11	multiselect
12	multitypehead
1010	file
1011	files
1012	image
1013	images
2011	gallery
2012	filelist
2013	datetime
2014	time
13	color
14	colorpicker
\.


--
-- TOC entry 2462 (class 0 OID 0)
-- Dependencies: 185
-- Name: columntypes_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('columntypes_id_seq', 3, true);


--
-- TOC entry 2416 (class 0 OID 319068)
-- Dependencies: 186
-- Data for Name: compos; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY compos (id, title, path, config, created) FROM stdin;
1	testik	testik	[{"cols": [{"path": {"id": 18, "path": "testform", "descr": "test form", "label": "test form", "title": "test form", "value": "test form", "rownum": 6, "viewlink": null, "viewtype": "form full", "tablename": "framework.test"}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 16, "path": "test", "descr": "test", "label": "test", "title": "test", "value": "test", "rownum": 5, "viewlink": null, "viewtype": "table", "tablename": "framework.test"}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-02-28 11:55:32.191611
2	branches	branches	[{"cols": [{"path": {"id": 32, "path": "branchesform", "descr": "branches form", "label": "branches form", "title": "branches form", "value": "branches form", "rownum": 11, "viewlink": null, "viewtype": "form full", "tablename": "framework.treesbranches", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 30, "path": "branches", "descr": "branches", "label": "branches", "title": "branches", "value": "branches", "rownum": 10, "viewlink": null, "viewtype": "table", "tablename": "framework.treesbranches", "subscrible": true}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-03-14 13:48:10.468984
3	Медполисы человека	medpolis	[{"cols": [{"path": {"id": 64, "path": "medpolisform", "descr": "Медполис форма", "label": "Медполис форма", "title": "Медполис форма", "value": "Медполис форма", "rownum": 15, "viewlink": null, "viewtype": "form full", "tablename": "test.medpolis", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 62, "path": "medpolis", "descr": "Медполисы человеков", "label": "Медполисы", "title": "Медполисы", "value": "Медполисы", "rownum": 14, "viewlink": null, "viewtype": "table", "tablename": "test.medpolis", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-03-21 16:10:58.513913
\.


--
-- TOC entry 2463 (class 0 OID 0)
-- Dependencies: 187
-- Name: compos_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('compos_id_seq', 3, true);


--
-- TOC entry 2418 (class 0 OID 319079)
-- Dependencies: 188
-- Data for Name: filtertypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY filtertypes (id, ftname) FROM stdin;
1	select
2	substr
3	period
4	multiselect
5	check
6	typehead
7	multijson
\.


--
-- TOC entry 2419 (class 0 OID 319082)
-- Dependencies: 189
-- Data for Name: functions; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY functions (id, funcname, functype) FROM stdin;
1	concat	concat
3	+	concat
4	-	concat
5	*	concat
6	/	concat
7	count	groupby
8	sum	groupby
9	max	groupby
10	min	groupby
\.


--
-- TOC entry 2420 (class 0 OID 319085)
-- Dependencies: 190
-- Data for Name: logtable; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY logtable (id, tablename, tableid, opertype, oldata, newdata, created, colname, userid) FROM stdin;
\.


--
-- TOC entry 2464 (class 0 OID 0)
-- Dependencies: 191
-- Name: logtable_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('logtable_id_seq', 2007, true);


--
-- TOC entry 2422 (class 0 OID 319095)
-- Dependencies: 192
-- Data for Name: mainmenu; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY mainmenu (id, title, parentid, created, systemfield, orderby, path, roles, icon) FROM stdin;
9	SP API	2	2018-12-21 14:32:59.333	f	7	/list/spapi	[1]	\N
63	Menus	57	2019-03-15 09:29:46.75475	f	6	/menus	[0]	pi pi-fw pi-plus
8	Logs	\N	2018-12-17 16:59:24.177	f	5	/list/logs	[1]	\N
1	Home	\N	2018-11-29 10:11:10.33	f	1	/home	\N	pi pi-home
56	Sigma	\N	2019-03-15 09:25:38.734437	f	0	/	[0]	pi pi-fw pi-home
64	Messages	57	2019-03-15 09:30:12.903699	f	7	/messages	[0]	pi pi-fw pi-spinner
57	Components	56	2019-03-15 09:26:24.038004	f	1	/	[0]	pi pi-fw pi-globe
6	Compositions	2	2018-12-11 08:40:45.927	f	4	/list/compos	[0]	pi pi-table
65	Charts	57	2019-03-15 09:30:39.657018	f	8	/charts	[0]	pi pi-fw pi-chart-bar
4	Menu Settings	2	2018-11-30 12:44:57.98	t	9	/list/menusettings/	[0]	pi pi-bars
58	Sample Page	57	2019-03-15 09:27:06.583319	f	1	/sample	[0]	pi pi-fw pi-th-large
5	Users	\N	2018-11-30 15:19:17.057	f	6	/list/users	[0]	pi pi-users
59	Forms	57	2019-03-15 09:27:37.780909	f	2	/forms	[0]	pi pi-fw pi-file
66	Misc	57	2019-03-15 09:31:03.89889	f	8	/misc	[0]	pi pi-fw pi-upload
60	Data	57	2019-03-15 09:28:05.012457	f	3	/data	[0]	pi pi-fw pi-table
67	Documentation	56	2019-03-15 10:11:53.306876	f	2	/documentation	[0]	pi pi-fw pi-question
61	Panels	57	2019-03-15 09:28:44.88184	f	4	/panels	[0]	pi pi-fw pi-list
72	Framework Documentation	\N	2019-03-22 09:22:48.47185	f	4	/	[0]	\N
68	View Source	56	2019-03-15 10:12:39.958606	f	3	/sigmasource	[0]	pi pi-fw pi-search
62	Overlays	57	2019-03-15 09:29:15.673439	f	5	/overlays	[0]	pi pi-fw pi-clone
2	Project Settings	\N	2018-11-30 12:43:58.967	t	2	/	[0]	pi pi-globe
70	English	72	2019-03-21 12:28:58.473125	f	0	/jdocumentation	[0]	\N
71	Русский	72	2019-03-21 12:29:37.606743	f	2	/jdocumentation_rus	[0]	\N
69	Global Settings	2	2019-03-15 11:41:44.701615	f	0	/projectsettings	[0]	pi pi-cog
47	Trees	2	2019-03-14 11:33:25.912516	f	3	/list/trees	[0]	pi pi-sitemap
3	Views	2	2018-12-17 15:05:36.69	t	2	/viewlist	[1]	pi pi-star-o
\.


--
-- TOC entry 2465 (class 0 OID 0)
-- Dependencies: 193
-- Name: mainmenu_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('mainmenu_id_seq', 72, true);


--
-- TOC entry 2424 (class 0 OID 319108)
-- Dependencies: 194
-- Data for Name: methodtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY methodtypes (id, methotypename) FROM stdin;
1	get
2	post
3	put
4	delete
\.


--
-- TOC entry 2425 (class 0 OID 319111)
-- Dependencies: 195
-- Data for Name: opertypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY opertypes (id, typename, alias) FROM stdin;
1	add	add
2	update	edit
3	delete	delete
\.


--
-- TOC entry 2426 (class 0 OID 319114)
-- Dependencies: 196
-- Data for Name: orgs; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY orgs (id, orgname) FROM stdin;
1	OOO test
2	OOO test2
\.


--
-- TOC entry 2466 (class 0 OID 0)
-- Dependencies: 197
-- Name: orgs_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('orgs_id_seq', 2, true);


--
-- TOC entry 2428 (class 0 OID 319125)
-- Dependencies: 198
-- Data for Name: roles; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY roles (id, rolename) FROM stdin;
0	developer
1	oper
2	serjant
\.


--
-- TOC entry 2429 (class 0 OID 319128)
-- Dependencies: 199
-- Data for Name: sess; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY sess (id, userid, created, killed) FROM stdin;
\.


--
-- TOC entry 2430 (class 0 OID 319132)
-- Dependencies: 200
-- Data for Name: spapi; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY spapi (id, methodname, procedurename, created, methodtype, roles) FROM stdin;
2	mainmenu	framework.fn_mainmenu	2019-02-18 11:27:07	1	\N
8	createconfig	framework.fn_createconfig	2019-02-20 18:43:46	1	[0]
7	getactypes	framework.fn_getacttypes	2019-02-20 11:34:20	1	[0]
6	getfunctions	framework.fn_getfunctions	2019-02-20 11:28:12	1	[0]
5	tablecolums	framework.fn_tabcolumns	2019-02-20 11:13:53	1	[0]
4	view	framework.fn_view_byid	2019-02-20 11:02:43	1	[0]
3	formparams	framework.fn_formparams	2019-02-20 10:58:19	1	[0]
9	view	framework.fn_viewsave	2019-02-21 13:45:47	2	[0]
10	select	framework.fn_formselect	2019-02-21 16:02:11	2	\N
11	autocomplete	framework.fn_autocomplete	2019-02-21 16:25:42	2	\N
12	getcolumnconfig	framework.get_colcongif	2019-02-21 16:50:33	1	\N
13	saverow	framework.fn_savevalue	2019-02-22 11:12:43	2	\N
16	gettable	framework.fn_getselect	2019-02-26 12:26:42	1	\N
17	savefile	framework.fn_savevalue	2019-02-26 16:36:49	2	\N
18	compo	framework.fn_compo	2019-02-28 11:23:58	1	\N
19	compo	framework.fn_compo_save	2019-02-28 11:55:23	2	\N
20	compobypath	framework.fn_compo_bypath	2019-02-28 11:58:34	1	\N
21	deleterow	framework.fn_deleterow	2019-03-05 16:10:43	4	\N
22	notifs	framework.fn_viewnotif_get	2019-03-07 15:10:09	1	\N
23	mainmenusigma	framework.fn_mainmenusigma	2019-03-15 09:44:59	1	\N
24	userorgs	framework.fn_userorgs	2019-03-18 08:10:12	1	\N
25	userorgs	framework.fn_userorg_upd	2019-03-18 09:10:27	2	\N
26	treesbypath	framework.fn_trees_bypath	2019-03-18 14:05:40	1	\N
27	setsended	framework.fn_notif_setsended	2019-03-19 15:34:21.91661	2	\N
15	refreshconfig	framework.fn_refreshconfig	2019-02-25 18:03:41	2	[0]
1	allviews	framework.fn_allviews	2019-02-04 22:54:58	1	[0]
\.


--
-- TOC entry 2467 (class 0 OID 0)
-- Dependencies: 201
-- Name: spapi_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('spapi_id_seq', 27, true);


--
-- TOC entry 2432 (class 0 OID 319148)
-- Dependencies: 202
-- Data for Name: trees; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY trees (id, title, url, descr, roles, created, userid, orgid) FROM stdin;
\.


--
-- TOC entry 2468 (class 0 OID 0)
-- Dependencies: 203
-- Name: trees_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('trees_id_seq', 4, true);


--
-- TOC entry 2434 (class 0 OID 319158)
-- Dependencies: 204
-- Data for Name: treesbranches; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY treesbranches (id, treesid, title, parentid, icon, created, treeviewtype, viewid, compoid) FROM stdin;
\.


--
-- TOC entry 2469 (class 0 OID 0)
-- Dependencies: 205
-- Name: treesbranches_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('treesbranches_id_seq', 184, true);


--
-- TOC entry 2436 (class 0 OID 319167)
-- Dependencies: 206
-- Data for Name: treeviewtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY treeviewtypes (id, typename) FROM stdin;
1	simple view
2	composition view
\.


--
-- TOC entry 2437 (class 0 OID 319170)
-- Dependencies: 207
-- Data for Name: users; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY users (id, fam, im, ot, login, password, isactive, created, roles, roleid, photo, orgs, usersettings, orgid) FROM stdin;
1	admin	admin	admin	admin	78d8045d684abd2eece923758f3cd781489df3a48e1278982466017f	t	2018-12-28 12:57:07.76	[0,2]	0	[{"original": "http://185.117.153.61:8080/files/355f6af3-db46-4666-bd18-0b982dd9c720Terminator_Hauptseite.jpg", "src": "http://185.117.153.61:8080/files/355f6af3-db46-4666-bd18-0b982dd9c720Terminator_Hauptseite.jpg", "thumbnail": "http://185.117.153.61:8080/files/355f6af3-db46-4666-bd18-0b982dd9c720Terminator_Hauptseite.jpg", "size": 23993, "content_type": "image/jpeg", "filename": "Terminator_Hauptseite.jpg", "uri": "/files/355f6af3-db46-4666-bd18-0b982dd9c720Terminator_Hauptseite.jpg"}]	[1]	{}	2
\.


--
-- TOC entry 2470 (class 0 OID 0)
-- Dependencies: 208
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 1, false);


--
-- TOC entry 2439 (class 0 OID 319186)
-- Dependencies: 209
-- Data for Name: views; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY views (id, title, descr, tablename, viewtype, pagination, config, path, created, groupby, filters, acts, roles, classname, orderby, ispagesize, pagecount, foundcount, subscrible) FROM stdin;
3027	Views compositions	Views compositions	framework.compos	table	f	[{"t": 1, "col": "id", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "title", "join": 0, "type": "text", "roles": "[]", "title": "title", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "path", "join": 0, "type": "text", "roles": "[]", "title": "path", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "config", "join": 0, "type": "text", "roles": "[]", "title": "config", "width": "100%", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "created", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	compos	2018-12-11 08:37:44.077	[]	[{"type": "typehead", "roles": [{"label": "developer", "value": 0}], "title": "found", "column": [{"t": 1, "label": "path", "value": "path"}, {"t": 1, "label": "title", "value": "title"}], "classname": null}]	[{"act": "/compo/l", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "classname": null, "parametrs": [{"paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "isforevery": 1}, {"act": "/compo/l?id=0", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": null, "parametrs": [], "isforevery": 0}, {"act": "/composition", "icon": "fa fa-link", "type": "Link", "roles": [], "title": ", to compo", "classname": null, "parametrs": [{"paramtype": "link", "paramconst": null, "paramtitle": "path", "paramcolumn": {"t": 1, "label": "path", "value": "path"}}], "paramtype": "link", "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": 1}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
1026	Menu Edit	Menu Edit	framework.mainmenu	form full	f	[{"t": 1, "col": "id", "join": 0, "type": "label", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "title", "join": 0, "type": "text", "roles": [], "title": "title", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "parentid", "join": 0, "type": "select", "input": 0, "roles": "[]", "title": "parentid", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": "framework.mainmenu", "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "value": "id"}, {"label": "title", "value": "title"}]}, {"t": 4, "col": "roles", "join": 0, "type": "multiselect", "input": 0, "roles": "[]", "title": "roles", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 5, "col": "created", "join": 0, "type": "label", "input": 0, "roles": "[]", "title": "created", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "systemfield", "join": 0, "type": "checkbox", "input": 0, "roles": "[]", "title": "systemfield", "width": "100%", "output": 0, "depency": null, "visible": 0, "relation": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "orderby", "join": 0, "type": "number", "input": 0, "roles": "[]", "title": "orderby", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "path", "join": 0, "type": "text", "input": 0, "roles": "[]", "title": "path", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "test", "join": false, "type": "array", "roles": "[]", "title": "test", "width": "100%", "depency": true, "visible": false, "relation": "framework.test", "classname": null, "column_id": 10, "onetomany": true, "defaultval": null, "depencycol": "relat", "relationcolums": "[]"}, {"t": 9, "col": "icon", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	menuedit	2018-11-30 14:23:09.53	[]	[]	[{"act": "/list/menusettings", "icon": "fa fa-thumbs-up", "type": "Link", "roles": [], "title": "ready", "classname": "btn btn-success", "parametrs": [], "isforevery": 0}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
3036	Logs	logs	framework.logtable	table	t	[{"t": 1, "col": "id", "join": 0, "type": "number", "roles": [{"label": "developer", "value": 0}], "title": "id", "width": "100%", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "tablename", "join": 0, "type": "text", "roles": "[]", "title": "tablename", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "tableid", "join": 0, "type": "text", "roles": "[]", "title": "tableid", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "typename", "type": "text", "input": 0, "roles": [], "table": "framework.opertypes", "title": "typename", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "opertype", "relationcolums": "[]"}, {"t": 10, "col": "userid", "join": false, "type": "number", "roles": "[]", "title": "userid", "width": "100%", "depency": false, "visible": false, "relation": "framework.users", "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "login", "title": "login", "value": "login"}]}, {"t": 4, "col": "opertype", "join": 0, "type": "select", "roles": "[]", "title": "opertype", "width": "100%", "depency": null, "visible": 0, "relation": "framework.opertypes", "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "title": "typename", "value": "typename"}]}, {"t": 10, "col": "login", "type": "text", "input": 0, "roles": [], "table": "framework.users", "title": "login", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "userid", "relationcolums": "[]"}, {"t": 6, "col": "oldata", "join": 0, "type": "text", "roles": "[]", "title": "oldata", "width": "100%", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "newdata", "join": 0, "type": "text", "roles": "[]", "title": "newdata", "width": "100%", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "created", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	logs	2018-12-17 16:10:52.48	[]	[{"t": 1, "type": "substr", "roles": [], "table": null, "title": "table name", "column": "tablename", "classname": null}, {"t": 1, "type": "select", "roles": [], "table": "framework.opertypes", "title": "operation type", "column": "opertype", "classname": null}, {"t": 1, "type": "period", "roles": [], "table": null, "title": "created", "column": "created", "classname": null}, {"t": 1, "type": "substr", "roles": [], "table": null, "title": "id", "column": "tableid", "classname": "form-control"}]	[{"act": "/listprint/logs", "icon": "fa fa-print", "type": "Print Data", "roles": [], "title": "print", "classname": null, "parametrs": [], "paramtype": null, "isforevery": false}, {"act": "/getone/log", "icon": "fa fa-eye", "type": "Link", "roles": [], "title": "look", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "GET", "isforevery": true}]	[{"label": "developer", "value": 0}]	\N	t	t	f	t	f
4038	sp api form	sp api form	framework.spapi	form full	f	[{"t": 1, "col": "id", "join": 0, "type": "number", "roles": "[]", "title": "N", "width": "100%", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "procedurename", "join": 0, "type": "text", "roles": "[]", "title": "procedure name", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "methodname", "join": 0, "type": "text", "roles": "[]", "title": "method name", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "methodtype", "join": 0, "type": "select", "roles": "[]", "title": "methodtype", "width": "100%", "depency": null, "visible": true, "relation": "framework.methodtypes", "classname": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "methotypename", "value": "methotypename"}]}, {"t": 4, "col": "roles", "join": 0, "type": "multiselect", "roles": "[]", "title": "roles", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 5, "col": "created", "join": 0, "type": "label", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	spapiform	2018-12-21 15:40:13.427	[]	[]	[{"act": "/list/spapi", "icon": "fa  fa-arrow-left", "type": "Link", "roles": [], "title": "click twice", "classname": "btn btn-outline-secondary", "parametrs": [], "paramtype": "query", "isforevery": 0}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
1025	MainMenu	Menu list	framework.mainmenu	table	f	[{"t": 1, "col": "id", "join": 0, "type": "number", "input": 1, "roles": [], "title": "id", "width": "100%", "output": 1, "depency": null, "visible": 0, "relation": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "title", "join": 0, "type": "text", "input": 0, "roles": [], "title": "title", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "path", "join": 0, "type": "text", "input": 0, "roles": "[]", "title": "path", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "roles", "join": 0, "type": "text", "input": 0, "roles": "[]", "title": "roles", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "systemfield", "join": 0, "type": "checkbox", "input": 0, "roles": "[]", "title": "systemfield", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "icon", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "parentid", "join": 0, "type": "select", "input": 0, "roles": "[]", "title": "parentid", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": "framework.mainmenu", "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "title", "title": "title_", "value": "title"}]}, {"t": 3, "col": "title", "type": "text", "input": 0, "roles": [], "table": "framework.mainmenu", "title": "parent", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "parentid", "relationcolums": "[]"}, {"t": 7, "col": "orderby", "join": 0, "type": "number", "input": 0, "roles": "[]", "title": "orderby", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "created", "join": 0, "type": "date", "input": 0, "roles": "[]", "title": "created", "width": "100%", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	menusettings	2018-11-30 12:50:20.173	[]	[{"t": 1, "type": "multiselect", "roles": [{"label": "developer", "value": 0}], "table": "framework.mainmenu", "title": "parent", "column": "parentid", "classname": null}]	[{"act": "/getone/menuedit?id=0", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add menu", "classname": null, "parametrs": [], "isforevery": 0}, {"act": "/getone/menuedit", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "редактировать", "classname": null, "parametrs": [{"paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}, {"paramtitle": "o", "paramcolumn": {"t": 1, "label": "title", "value": "title"}}], "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete menu", "classname": "btn", "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "isforevery": 1}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
55	account	account	framework.users	form full	f	[{"t": 1, "col": "id", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": "row", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "fam", "join": false, "type": "label", "roles": "[]", "title": "fam", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "form-group row", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "im", "join": false, "type": "label", "roles": "[]", "title": "im", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "form-group row", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "ot", "join": false, "type": "label", "roles": "[]", "title": "ot", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "form-group row", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "login", "join": false, "type": "label", "roles": "[]", "title": "login", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "form-group row", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "join": false, "type": "password", "roles": "[]", "title": "password", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "form-control", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "isactive", "join": false, "type": "checkbox", "roles": "[]", "title": "isactive", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": "form-group row", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "created", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "form-group row", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "roles", "join": false, "type": "label", "roles": "[]", "title": "roles", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": "form-group row", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "roleid", "join": false, "type": "number", "roles": "[]", "title": "roleid", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": "form-group row", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "orgs", "join": false, "type": "label", "roles": "[]", "title": "orgs", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": "form-group row", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "usersettings", "join": false, "type": "text", "roles": "[]", "title": "usersettings", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": "form-group row", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "orgid", "join": false, "type": "number", "roles": "[]", "title": "orgid", "width": "100%", "depency": false, "visible": false, "relation": "framework.orgs", "classname": "form-group row", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "orgname", "title": "orgname", "value": "orgname"}]}, {"t": 14, "col": "orgname", "type": "label", "input": 0, "roles": [], "table": "framework.orgs", "title": "orgname", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": "form-group row", "notaddable": false, "relatecolumn": "orgid", "relationcolums": "[]"}, {"t": 11, "col": "photo", "join": false, "type": "image", "roles": "[]", "title": "photo", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	account	2019-03-19 16:09:24.896608	[]	[]	[]	[]	card	f	t	t	t	f
4037	SP API	API methods Storage procedures	framework.spapi	table	t	[{"t": 1, "col": "id", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "methodtype", "join": 0, "type": "select", "roles": "[]", "title": "methodtype", "width": "100%", "depency": null, "visible": 0, "relation": "framework.methodtypes", "classname": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "methotypename", "value": "methotypename"}]}, {"t": 2, "col": "methodname", "join": 0, "type": "text", "roles": "[]", "title": "method name", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "procedurename", "join": 0, "type": "text", "roles": "[]", "title": "procedure name", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "methotypename", "type": "text", "input": 0, "roles": [], "table": "framework.methodtypes", "title": "methotypename", "tpath": [], "output": 0, "related": 1, "visible": true, "relation": null, "classname": null, "notaddable": 0, "relatecolumn": "methodtype", "relationcolums": "[]"}, {"t": 4, "col": "roles", "join": 0, "type": "text", "roles": "[]", "title": "roles", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "created", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	spapi	2018-12-21 14:27:50.79	[]	[{"type": "typehead", "roles": [], "title": "found", "column": [{"t": 1, "label": "methodname", "value": "methodname"}, {"t": 1, "label": "procedurename", "value": "procedure name"}], "classname": "form-control"}]	[{"act": "/getone/spapiform?N=0", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": null, "parametrs": [], "paramtype": null, "isforevery": 0}, {"act": "/getone/spapiform", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "N", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": "query", "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": 1}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	t
28	tree from	tree from	framework.trees	form full	f	[{"t": 1, "col": "id", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "title", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "url", "join": false, "type": "text", "roles": "[]", "title": "url", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "descr", "join": false, "type": "text", "roles": "[]", "title": "descr", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "roles", "join": false, "type": "multiselect", "roles": "[]", "title": "roles", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 6, "col": "created", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	treeform	2019-03-14 11:52:57.162249	[]	[]	[{"act": "/list/trees", "icon": "fa fa-thumbs-up", "type": "Link", "roles": [], "title": "ready", "classname": "btn btn-success", "parametrs": [], "paramtype": null, "isforevery": false}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
26	trees	trees components	framework.trees	table	t	[{"t": 1, "col": "id", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "title", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "url", "join": false, "type": "text", "roles": "[]", "title": "url", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "descr", "join": false, "type": "text", "roles": "[]", "title": "descr", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "roles", "join": false, "type": "text", "roles": "[]", "title": "roles", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "created", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	trees	2019-03-14 11:21:06.460061	[]	[{"type": "typehead", "roles": [], "title": "found", "column": [{"t": 1, "label": "title", "value": "title"}, {"t": 1, "label": "url", "value": "url"}, {"t": 1, "label": "descr", "value": "descr"}], "classname": null}]	[{"act": "/getone/treeform", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": "btn btn", "parametrs": [{"paramconst": "0", "paramtitle": "id", "paramcolumn": null}], "paramtype": null, "isforevery": false}, {"act": "/getone/treeform", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/composition/branches", "icon": "fa fa-code-fork", "type": "Link", "roles": [], "title": "branches", "classname": null, "parametrs": [{"paramconst": "0", "paramtitle": "bid", "paramcolumn": null}, {"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}]	[{"label": "developer", "value": 0}]	\N	t	t	t	t	f
30	branches	branches	framework.treesbranches	table	f	[{"t": 1, "col": "id", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "treesid", "join": false, "type": "number", "roles": "[]", "title": "treesid", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "title", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "parentid", "join": false, "type": "number", "roles": "[]", "title": "parentid", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "icon", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "created", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	branches	2019-03-14 13:42:05.157003	[]	[]	[{"act": "/list/trees", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "back", "classname": "btn ", "parametrs": [], "paramtype": null, "isforevery": false}, {"act": "/composition/branches", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "label": "treesid", "value": "treesid"}}, {"paramconst": null, "paramtitle": "bid", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/composition/branches", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "label": "treesid", "value": "treesid"}}, {"paramconst": "0", "paramtitle": "bid", "paramcolumn": null}, {"paramconst": "treesid,orgid", "paramtitle": "relation", "paramcolumn": null}], "paramtype": null, "isforevery": false}]	[{"label": "developer", "value": 0}]	\N	t	f	f	f	f
5038	profile detail	profile detail	framework.users	form full	f	[{"t": 2, "col": "fam", "join": false, "type": "text", "roles": "[]", "title": "fam", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "updatable": true, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "im", "join": false, "type": "text", "roles": "[]", "title": "im", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "ot", "join": 0, "type": "text", "roles": "[]", "title": "ot", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "login", "join": 0, "type": "text", "roles": "[]", "title": "login", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "join": 0, "type": "password", "roles": "[]", "title": "password", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "orgid", "join": 0, "type": "select", "roles": "[]", "title": "orgid", "width": "100%", "depency": null, "visible": 1, "relation": "framework.orgs", "classname": null, "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "value": "id"}, {"label": "orgname", "value": "orgname"}], "select_condition": []}, {"t": 8, "col": "isactive", "join": 0, "type": "checkbox", "roles": "[]", "title": "isactive", "width": "10%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "created", "join": 0, "type": "label", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 9, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "roles", "join": false, "type": "multiselect", "roles": "[]", "title": "roles", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 1, "col": "id", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "roleid", "join": false, "type": "number", "roles": "[]", "title": "roleid", "width": "100%", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "photo", "join": false, "type": "image", "roles": "[]", "title": "photo", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	userone	2018-12-28 13:19:10.513	[]	[]	[{"act": "/list/users", "icon": "fa fa-check", "type": "Link", "roles": [], "title": "ready", "classname": "btn btn-success", "parametrs": [], "paramtype": null, "isforevery": 0}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
32	branches form	branches form	framework.treesbranches	form full	f	[{"t": 1, "col": "id", "join": false, "type": "label", "roles": "[]", "title": "bid", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "treesid", "join": false, "type": "label", "roles": "[]", "title": "treesid", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "title", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "parentid", "join": false, "type": "select", "roles": "[]", "title": "parentid", "width": "100%", "depency": null, "visible": true, "relation": "framework.treesbranches", "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "select_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": {"t": 1, "label": "treesid", "value": "treesid"}, "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}], "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "icon", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "created", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 15, "col": "treeviewtype", "join": false, "type": "select", "roles": "[]", "title": "treeviewtype", "width": "100%", "depency": null, "visible": true, "relation": "framework.treeviewtypes", "classname": null, "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "typename", "title": "typename", "value": "typename"}], "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 23, "col": "viewid", "join": false, "type": "select", "roles": "[]", "title": "viewid", "width": "100%", "depency": null, "visible": true, "relation": "framework.views", "classname": null, "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}, {"label": "path", "title": "path", "value": "path"}], "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "label": "treeviewtype", "value": "treeviewtype"}, "value": "1", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 14, "col": "compoid", "join": false, "type": "select", "roles": "[]", "title": "compoid", "width": "100%", "depency": false, "visible": true, "relation": "framework.compos", "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "visible_condition": [{"col": {"t": 1, "label": "treesid", "value": "treesid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "label": "treeviewtype", "value": "treeviewtype"}, "value": "2", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}]	branchesform	2019-03-14 13:46:57.627417	[]	[]	[{"act": "/composition/branches", "icon": "fa fa-refresh", "type": "Link", "roles": [], "title": "click twice", "classname": "btn btn-success", "parametrs": [{"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "label": "treesid", "value": "treesid"}}, {"paramconst": "0", "paramtitle": "bid", "paramcolumn": null}], "paramtype": null, "isforevery": false}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
34	myorg	user org	framework.orgs	form full	f	[{"t": 1, "col": "id", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "orgname", "join": false, "type": "label", "roles": "[]", "title": "orgname", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	myorg	2019-03-18 09:42:45.155502	[]	[]	[]	[]	\N	f	t	t	t	f
54	Notifications	Notifications	framework.viewsnotification	table	t	[{"t": 1, "col": "id", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "viewid", "join": false, "type": "number", "roles": "[]", "title": "viewid", "width": "100%", "depency": false, "visible": false, "relation": "framework.views", "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "col", "join": false, "type": "text", "roles": "[]", "title": "col", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "tableid", "join": false, "type": "text", "roles": "[]", "title": "tableid", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "notificationtext", "join": false, "type": "text", "roles": "[]", "title": "notificationtext", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "foruser", "join": false, "type": "number", "roles": "[]", "title": "foruser", "width": "100%", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": "_userid_", "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "issend", "join": false, "type": "checkbox", "roles": "[]", "title": "issend", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "isread", "join": false, "type": "checkbox", "roles": "[]", "title": "isread", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "created", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "sended", "join": false, "type": "date", "roles": "[]", "title": "sended", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "readed", "join": false, "type": "date", "roles": "[]", "title": "readed", "width": "100%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	notifs	2019-03-19 16:03:31.904736	[]	[{"t": 1, "type": "check", "roles": [], "table": null, "title": "sended", "column": "issend", "classname": null}, {"t": 1, "type": "check", "roles": [], "table": null, "title": "readed", "column": "isread", "classname": null}]	[]	[]	\N	t	t	t	t	f
56	log	log	framework.logtable	form full	f	[{"t": 1, "col": "id", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "10%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "userid", "join": false, "type": "number", "roles": "[]", "title": "userid", "width": "10%", "depency": false, "visible": false, "relation": "framework.users", "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "login", "title": "login", "value": "login"}]}, {"t": 2, "col": "tablename", "join": false, "type": "label", "roles": "[]", "title": "tablename", "width": "50%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "tableid", "join": false, "type": "label", "roles": "[]", "title": "tableid", "width": "10%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "opertype", "join": false, "type": "label", "roles": "[]", "title": "opertype", "width": "10%", "depency": false, "visible": false, "relation": "framework.opertypes", "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "title": "typename", "value": "typename"}]}, {"t": 10, "col": "login", "type": "label", "input": 0, "roles": [], "table": "framework.users", "title": "login", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "userid", "relationcolums": "[]"}, {"t": 6, "col": "oldata", "join": false, "type": "label", "roles": "[]", "title": "oldata", "width": "80%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "newdata", "join": false, "type": "label", "roles": "[]", "title": "newdata", "width": "80%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "created", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "30%", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	log	2019-03-19 16:34:03.67124	[]	[]	[]	[]	\N	f	t	t	t	f
5037	users	users list	framework.users	table	f	[{"t": 1, "col": "id", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "fam", "join": 0, "type": "text", "roles": "[]", "title": "fam", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "im", "join": 0, "type": "text", "roles": "[]", "title": "im", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "ot", "join": 0, "type": "text", "roles": "[]", "title": "ot", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "photo", "join": false, "type": "image", "roles": "[]", "title": "photo", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "login", "join": 0, "type": "text", "roles": "[]", "title": "login", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "roles", "join": false, "type": "multiselect", "roles": "[]", "title": "roles", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 12, "col": "orgs", "join": false, "type": "multiselect", "roles": "[]", "title": "orgs", "width": "100%", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "orgname", "value": "orgname"}], "relationcolums": "[]", "multiselecttable": "framework.orgs"}, {"t": 8, "col": "isactive", "join": 0, "type": "checkbox", "roles": "[]", "title": "isactive", "width": "100%", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "created", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "100%", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 9, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	users	2018-12-28 13:10:45.637	[]	[{"t": 1, "type": "check", "roles": [], "table": null, "title": "isactive", "column": "isactive", "classname": null}, {"t": 1, "type": "substr", "roles": [], "table": null, "title": "login", "column": "login", "classname": "form-control"}, {"t": 1, "type": "multijson", "roles": [], "table": null, "title": "roles", "column": "roles", "classname": null}]	[{"act": "/getone/userone", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit user", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": "query", "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "isforevery": 1}]	[{"label": "developer", "value": 0}]	\N	f	t	t	t	f
\.


--
-- TOC entry 2471 (class 0 OID 0)
-- Dependencies: 210
-- Name: views_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('views_id_seq', 64, true);


--
-- TOC entry 2441 (class 0 OID 319207)
-- Dependencies: 211
-- Data for Name: viewsnotification; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY viewsnotification (id, viewid, col, tableid, notificationtext, foruser, issend, isread, created, sended, readed) FROM stdin;
\.


--
-- TOC entry 2472 (class 0 OID 0)
-- Dependencies: 212
-- Name: viewsnotification_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('viewsnotification_id_seq', 1, true);


--
-- TOC entry 2443 (class 0 OID 319219)
-- Dependencies: 213
-- Data for Name: viewtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY viewtypes (id, vtypename, viewlink) FROM stdin;
1	table	/list/
2	tiles	\N
3	form full	/getone/
4	form not mutable	\N
\.


--
-- TOC entry 2248 (class 2606 OID 319421)
-- Name: acttypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY acttypes
    ADD CONSTRAINT acttypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2250 (class 2606 OID 319423)
-- Name: columntypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY columntypes
    ADD CONSTRAINT columntypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2252 (class 2606 OID 319425)
-- Name: compos_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY compos
    ADD CONSTRAINT compos_pkey PRIMARY KEY (id);


--
-- TOC entry 2254 (class 2606 OID 319427)
-- Name: filtertypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filtertypes
    ADD CONSTRAINT filtertypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2256 (class 2606 OID 319429)
-- Name: functions_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY functions
    ADD CONSTRAINT functions_pkey PRIMARY KEY (id);


--
-- TOC entry 2258 (class 2606 OID 319431)
-- Name: logtable_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY logtable
    ADD CONSTRAINT logtable_pkey PRIMARY KEY (id);


--
-- TOC entry 2260 (class 2606 OID 319433)
-- Name: mainmenu_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY mainmenu
    ADD CONSTRAINT mainmenu_pkey PRIMARY KEY (id);


--
-- TOC entry 2262 (class 2606 OID 319435)
-- Name: methodtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY methodtypes
    ADD CONSTRAINT methodtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2264 (class 2606 OID 319437)
-- Name: opertypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY opertypes
    ADD CONSTRAINT opertypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2266 (class 2606 OID 319439)
-- Name: orgs_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 2268 (class 2606 OID 319443)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 2270 (class 2606 OID 319445)
-- Name: spapi_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY spapi
    ADD CONSTRAINT spapi_pkey PRIMARY KEY (id);


--
-- TOC entry 2272 (class 2606 OID 319449)
-- Name: trees_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY trees
    ADD CONSTRAINT trees_pkey PRIMARY KEY (id);


--
-- TOC entry 2274 (class 2606 OID 319451)
-- Name: treesbranches_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT treesbranches_pkey PRIMARY KEY (id);


--
-- TOC entry 2276 (class 2606 OID 319453)
-- Name: treeviewtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treeviewtypes
    ADD CONSTRAINT treeviewtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2279 (class 2606 OID 319455)
-- Name: views_path_key; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY views
    ADD CONSTRAINT views_path_key UNIQUE (path);


--
-- TOC entry 2281 (class 2606 OID 319457)
-- Name: views_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY views
    ADD CONSTRAINT views_pkey PRIMARY KEY (id);


--
-- TOC entry 2283 (class 2606 OID 319459)
-- Name: viewsnotification_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewsnotification
    ADD CONSTRAINT viewsnotification_pkey PRIMARY KEY (id);


--
-- TOC entry 2285 (class 2606 OID 319461)
-- Name: viewtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewtypes
    ADD CONSTRAINT viewtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2277 (class 1259 OID 319474)
-- Name: users_id_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX users_id_key ON framework.users USING btree (id);


--
-- TOC entry 2296 (class 2620 OID 319475)
-- Name: trees_add_org; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER trees_add_org AFTER INSERT OR UPDATE OF userid ON framework.trees FOR EACH ROW EXECUTE PROCEDURE public.fn_trees_add_org();


--
-- TOC entry 2297 (class 2620 OID 319476)
-- Name: treesbranches_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER treesbranches_tr AFTER INSERT OR UPDATE OF viewid, compoid ON framework.treesbranches FOR EACH ROW EXECUTE PROCEDURE public.fn_treesbranch_check();


--
-- TOC entry 2298 (class 2620 OID 319477)
-- Name: users_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER users_tr AFTER INSERT OR UPDATE OF password, roles ON framework.users FOR EACH ROW EXECUTE PROCEDURE public.fn_user_check();


--
-- TOC entry 2290 (class 2606 OID 319514)
-- Name: compos_fk1; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT compos_fk1 FOREIGN KEY (compoid) REFERENCES compos(id);


--
-- TOC entry 2286 (class 2606 OID 319519)
-- Name: logtype_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY logtable
    ADD CONSTRAINT logtype_fk FOREIGN KEY (opertype) REFERENCES opertypes(id);


--
-- TOC entry 2294 (class 2606 OID 319529)
-- Name: org_f; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT org_f FOREIGN KEY (orgid) REFERENCES orgs(id);


--
-- TOC entry 2289 (class 2606 OID 319539)
-- Name: spapi_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY spapi
    ADD CONSTRAINT spapi_fk FOREIGN KEY (methodtype) REFERENCES methodtypes(id);


--
-- TOC entry 2291 (class 2606 OID 319544)
-- Name: treesbranches_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT treesbranches_fk FOREIGN KEY (parentid) REFERENCES treesbranches(id);


--
-- TOC entry 2292 (class 2606 OID 319549)
-- Name: treeview; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT treeview FOREIGN KEY (treeviewtype) REFERENCES treeviewtypes(id);


--
-- TOC entry 2288 (class 2606 OID 319554)
-- Name: us_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY sess
    ADD CONSTRAINT us_fk FOREIGN KEY (userid) REFERENCES users(id) ON DELETE CASCADE;


--
-- TOC entry 2287 (class 2606 OID 319559)
-- Name: userid_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY logtable
    ADD CONSTRAINT userid_fk FOREIGN KEY (userid) REFERENCES users(id);


--
-- TOC entry 2295 (class 2606 OID 319564)
-- Name: viewid_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewsnotification
    ADD CONSTRAINT viewid_fk FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2293 (class 2606 OID 319569)
-- Name: viewid_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT viewid_fk FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2450 (class 0 OID 0)
-- Dependencies: 9
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2019-03-25 09:10:18

--
-- PostgreSQL database dump complete
--


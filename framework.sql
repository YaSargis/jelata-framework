--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.10
-- Dumped by pg_dump version 9.5.1

-- Started on 2019-12-31 15:10:08

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 179912)
-- Name: framework; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA framework;


ALTER SCHEMA framework OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 179913)
-- Name: reports; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA reports;


ALTER SCHEMA reports OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 194780)
-- Name: test; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA test;


ALTER SCHEMA test OWNER TO postgres;

--
-- TOC entry 3078 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA test; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA test IS 'FOR TESTS';


--
-- TOC entry 1 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 3079 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 2 (class 3079 OID 194934)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3080 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = framework, pg_catalog;

--
-- TOC entry 283 (class 1255 OID 179914)
-- Name: fn_action_add_untitle(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_action_add_untitle(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _viewid int;
  _id int;
BEGIN
	-- add untitle action in actions table
	
    _viewid = injson->>'viewid';
    
    IF _viewid is NULL THEN
    	PERFORM raiserror('viewid is null');
    END IF;
    
    _id = nextval('framework.actions_id_seq'::regclass);
    INSERT INTO framework.actions (
      id, column_order, 
      title, viewid, icon, 
      act_url, act_type
    )
    VALUES (
      _id, COALESCE((
      	SELECT max(column_order) 
       	FROM framework.actions 
        WHERE viewid = _viewid
      ),0) + 1, 
      concat('untitled_',_id::varchar), _viewid, 'default', 
      '/', 'Link'
    );
    
    
END;
$$;


ALTER FUNCTION framework.fn_action_add_untitle(injson json) OWNER TO postgres;

--
-- TOC entry 3081 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION fn_action_add_untitle(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_action_add_untitle(injson json) IS 'add untitle action in actions table';


--
-- TOC entry 299 (class 1255 OID 179915)
-- Name: fn_action_copy(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_action_copy(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id int;
  action_id int;
BEGIN

  -- COPY ACTION IN VIEW
  _id = injson->>'id';
  
  action_id = nextval('framework.actions_id_seq'::regclass);
  
  
  INSERT INTO framework.actions (
      id, title, act_type,
      act_url, api_method, api_type,
	  ask_confirm, classname, column_order,
	  forevery, icon, main_action,
	  refresh_data, roles, viewid
  )
  SELECT
      action_id, concat(a.title,'_',action_id::varchar), a.act_type,
	  a.act_url, a.api_method, a.api_type,
	  a.ask_confirm, a.classname, COALESCE((
	    SELECT max(aa.column_order)
		FROM framework.actions as aa
		WHERE aa.viewid = a.viewid			 
	  ),0) + 1,
	  a.forevery, a.icon, a.main_action,
	  a.refresh_data, a.roles, a.viewid
  FROM framework.actions as a
  WHERE a.id = _id;
  
  INSERT INTO framework.act_parametrs(
  	actionid, paramtitle, paramt,
	paramconst, paraminput, paramcolumn,
	val_desc, query_type
  )
  SELECT
	action_id, paramtitle, paramt,
	paramconst, paraminput, paramcolumn,
	val_desc, query_type
  FROM framework.act_parametrs
  WHERE actionid = _id;
  
  INSERT INTO framework.act_visible_condions (
	actionid, val_desc, col,
	title, operation, value
  ) 
  SELECT
    action_id, val_desc, col,
	title, operation, value
  FROM framework.act_visible_condions
  WHERE actionid = _id;
  
  
END;
$$;


ALTER FUNCTION framework.fn_action_copy(injson json) OWNER TO postgres;

--
-- TOC entry 3082 (class 0 OID 0)
-- Dependencies: 299
-- Name: FUNCTION fn_action_copy(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_action_copy(injson json) IS 'COPY ACTION IN VIEW';


--
-- TOC entry 300 (class 1255 OID 179916)
-- Name: fn_allviews_sel(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_allviews_sel(injson json, OUT outjson json, OUT foundcount bigint) RETURNS record
    LANGUAGE plpgsql
    AS $$
-- USING IN COMPOSITIONS
DECLARE
  --pagenum smallint;
 -- pagesize smallint;
  substr varchar(50);
 -- _off smallint;
BEGIN
 -- pagenum = injson->>'pagenum';
  --pagesize = injson->>'pagesize';
  substr = injson->>'substr';
  
 -- pagenum = coalesce(pagenum,'1');
  --pagesize = coalesce(pagesize,'15');
  substr = upper(concat('%',coalesce(substr,'%'),'%')); 
 --_off=(pagenum*pagesize)-pagesize;
  foundcount = (SELECT count(v.id)
  FROM framework.views as v
  WHERE upper(v.title) like substr or upper(v.tablename) like substr
  or upper(v.path) like substr
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
    		or upper(v.path) like substr
	ORDER BY v.id
	--LIMIT pagesize OFFSET _off
    ) as d
  INTO outjson;
  
  outjson = COALESCE(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_allviews_sel(injson json, OUT outjson json, OUT foundcount bigint) OWNER TO postgres;

--
-- TOC entry 3083 (class 0 OID 0)
-- Dependencies: 300
-- Name: FUNCTION fn_allviews_sel(injson json, OUT outjson json, OUT foundcount bigint); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_allviews_sel(injson json, OUT outjson json, OUT foundcount bigint) IS 'USING IN COMPOSITIONS
GET ALL VIEWS';


--
-- TOC entry 301 (class 1255 OID 179917)
-- Name: fn_apimethods(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_apimethods(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- API method list
	SELECT 
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT
    	a.val as label,
        a.val as value
    FROM framework.apimethods as a) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');
    

END;
$$;


ALTER FUNCTION framework.fn_apimethods(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3084 (class 0 OID 0)
-- Dependencies: 301
-- Name: FUNCTION fn_apimethods(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_apimethods(injson json, OUT outjson json) IS 'API Methods list';


--
-- TOC entry 302 (class 1255 OID 179918)
-- Name: fn_autocomplete(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_autocomplete(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
  col varchar;
 -- val varchar;
  _table varchar;
  squery varchar;
  _val varchar;
BEGIN
	-- FORM AUTOCOMPLETE METHOD
	col = injson->>'col';
    _val = injson->>'val';
    _table = injson->>'table';
    --perform raiserror(val);
    IF _val is not null and length(_val) > 0 THEN
    	_val = concat('%',upper(_val),'%');
    	squery = concat(squery,
        	'SELECT array_to_json(array_agg(row_to_json(d))) FROM (
            SELECT distinct ' , 
            col , ' as value, ' , col , ' 
        	as label FROM ' , _table , ' WHERE upper(' , 
            col , ')::varchar like $1::varchar LIMIT 500) as d');
            	
       EXECUTE format(squery) USING _val INTO outjson;
       
       outjson = 
       	coalesce(
       		outjson,
       		(SELECT array_to_json(array_agg(row_to_json(d))) 
             FROM (    
              SELECT 
             	injson ->> 'val' as value, 
               	injson ->> 'val' as label          
              ) as d));
    END IF;        

	outjson = coalesce(outjson,'[]');
    outjson = '{"label":"","value":null}'::jsonb||outjson::jsonb; 

END;
$_$;


ALTER FUNCTION framework.fn_autocomplete(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3085 (class 0 OID 0)
-- Dependencies: 302
-- Name: FUNCTION fn_autocomplete(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_autocomplete(injson json, OUT outjson json) IS 'FORM AUTOCOMPLETE METHOD';


--
-- TOC entry 303 (class 1255 OID 179919)
-- Name: fn_branchestree_recurs(integer, integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_branchestree_recurs(_parentid integer, _treesid integer, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- TREES BRANCHES RECURS FUNCTION
	SELECT
    	array_to_json(array_agg(row_to_json(d))) 
      FROM
      (SELECT
          tb.id as key, 
          tb.icon,
          tb.parentid,
          tb.treesid,
          tb.title as label,
          tb.ismain,
          framework.fn_branchestree_recurs(tb.id,tb.treesid) as children
      FROM framework.treesbranches as tb
      WHERE tb.treesid = _treesid and tb.title is not null and 
      coalesce(tb.parentid,0) = coalesce(_parentid,0)
      ORDER BY coalesce(tb.orderby,0)
      ) as d
      INTO outjson;
      
     -- outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_branchestree_recurs(_parentid integer, _treesid integer, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3086 (class 0 OID 0)
-- Dependencies: 303
-- Name: FUNCTION fn_branchestree_recurs(_parentid integer, _treesid integer, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_branchestree_recurs(_parentid integer, _treesid integer, OUT outjson json) IS 'TREES BRANCHES RECURS FUNCTION';


--
-- TOC entry 304 (class 1255 OID 179920)
-- Name: fn_col_add_select_condition(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_col_add_select_condition(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	_conf_id int;
    _operation varchar(30);
    _value varchar(150);
    _const varchar(350);
    _col varchar(350);
    _title varchar(350);
    
    
BEGIN
	-- add select_condition for config
    
    _conf_id = injson->>'confid';
    _operation = '=';
    _const = 'CONST';
	
	IF _conf_id is null THEN
    	PERFORM raiserror('configid is null');
    END IF;
    
    INSERT INTO framework.select_condition (
      configid,
      col,
      title,
      operation,
      const,
      value
    ) VALUES (
      _conf_id,
      _col,
      _title,
      _operation,
      _const,
      _value
    );
	

END;
$$;


ALTER FUNCTION framework.fn_col_add_select_condition(injson json) OWNER TO postgres;

--
-- TOC entry 3087 (class 0 OID 0)
-- Dependencies: 304
-- Name: FUNCTION fn_col_add_select_condition(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_col_add_select_condition(injson json) IS 'add select_condition for config';


--
-- TOC entry 305 (class 1255 OID 179921)
-- Name: fn_compo(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_compo(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id int;
BEGIN
	-- GET COMPO
    
	_id = injson->>'id';
    
    SELECT row_to_json(d)
    FROM
   	 (
     	SELECT *
     	FROM framework.compos as c
     	WHERE c.id = _id
     ) as d
    INTO outjson;
    
	outjson = coalesce(outjson,'{}');

END;
$$;


ALTER FUNCTION framework.fn_compo(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3088 (class 0 OID 0)
-- Dependencies: 305
-- Name: FUNCTION fn_compo(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_compo(injson json, OUT outjson json) IS 'GET COMPO';


--
-- TOC entry 306 (class 1255 OID 179922)
-- Name: fn_compo_bypath(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_compo_bypath(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _path varchar(350);
BEGIN
	-- GET COMPO SETTINGS BY PATH
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
-- TOC entry 3089 (class 0 OID 0)
-- Dependencies: 306
-- Name: FUNCTION fn_compo_bypath(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_compo_bypath(injson json, OUT outjson json) IS 'GET COMPO SETTINGS BY PATH';


--
-- TOC entry 307 (class 1255 OID 179923)
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
  -- INSERT/UPDATE COMPOSITION

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
      id, title,
      path, config
    )
    VALUES (
      _id, _title,
      _path, _config
    );
    
    
    SELECT row_to_json(d)
    FROM
    (SELECT
    	*
    FROM framework.compos) as d
    WHERE id = _id
    INTO _newdata;
    
  	INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, userid,
      newdata
    ) VALUES (
      'framework.compos', _id::varchar(150),
      '1', _userid ,
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
      title = coalesce(_title,title),
      path = coalesce(_path,path),
      config = coalesce(_config,config )  	
    WHERE id = _id;
    
  	INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, userid,
      newdata
    ) VALUES (
      'framework.compos', _id::varchar(150),
      '2', _userid,
     _newdata   
    ); 
  END IF;    
END;
$$;


ALTER FUNCTION framework.fn_compo_save(injson json, OUT _id integer) OWNER TO postgres;

--
-- TOC entry 3090 (class 0 OID 0)
-- Dependencies: 307
-- Name: FUNCTION fn_compo_save(injson json, OUT _id integer); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_compo_save(injson json, OUT _id integer) IS 'INSERT/UPDATE COMPOSITION';


--
-- TOC entry 308 (class 1255 OID 179924)
-- Name: fn_config_fncol_add(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_fncol_add(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- add fn column in config


	IF (injson->>'title') IS NULL THEN
    	PERFORM raiserror('title is null');
    END IF;
    
	IF (injson->>'fn') IS NULL THEN
    	PERFORM raiserror('fn is null');
    END IF;
    
    IF (injson->'fncols') IS NULL THEN
    	PERFORM raiserror('fncols is null');
    END IF;
    
	INSERT INTO framework.config (
  	  viewid, col, title,
      column_order, fn, fncolumns 
    )
    VALUES (
   	 (injson->>'viewid')::INT, substring(injson->>'title',1,15), injson->>'title',
     (
     SELECT
     	max(column_id)
     FROM framework.config
     WHERE viewid = (injson->>'viewid')::INT
     ) + 1, injson->>'fn',
    injson->'fncols'
    );
END;
$$;


ALTER FUNCTION framework.fn_config_fncol_add(injson json) OWNER TO postgres;

--
-- TOC entry 3091 (class 0 OID 0)
-- Dependencies: 308
-- Name: FUNCTION fn_config_fncol_add(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_fncol_add(injson json) IS 'ADD fn COLUMN IN CONFIG';


--
-- TOC entry 309 (class 1255 OID 179925)
-- Name: fn_config_inscol(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_inscol(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	_col varchar(150);
    _viewid int;
    _conf JSON;
    _tabname varchar(350);
    _val json;
    _title varchar(500);
BEGIN
	-- add fn column in config
    _col = injson->>'col'; -- this is title
    _viewid = injson->>'viewid';
    
    IF _col is null OR _viewid is null THEN
    	PERFORM raiserror('col or view is null');
    END IF;
    
    
    SELECT
    	v.tablename
    FROM framework.views as v
    WHERE v.id = _viewid
    INTO _tabname;
    
    IF _tabname is null THEN
    	PERFORM raiserror('tabname is null');
    END IF;
    
    /*SELECT outjson 
    FROM framework.fn_createconfig(json_build_object('tabname',_tabname,'colname',_col))
    INTO _conf;*/
    
    
   /* SELECT
    	value
    FROM json_array_elements(_conf)
    WHERE (value->>'title') = _col
    LIMIT 1
    INTO _val;
    
    _title = _val->>'title';
    
    IF (SELECT 
    		count(id) 
    	FROM framework.config 
    	WHERE viewid = _viewid and title = _title) > 0
    THEN
    	_title = concat(_title,'_', 
            (SELECT 
                count(id) 
          	FROM framework.config 
          	WHERE viewid = _viewid)::varchar);
    END IF;*/

    
    INSERT INTO framework.config (
      viewid, t, col, column_id,
      title, relation, relcol,
      depency, column_order,
      depencycol
    )
    SELECT
           _viewid,	pz.t, pz.col, pz.column_id,
           concat(pz.title, '_', (
             SELECT 
               count(id) 
             FROM framework.config 
             WHERE viewid = _viewid)::varchar) as title,
                COALESCE(pz.relation,(
                	SELECT 
                    	concat(y.table_schema, '.', y.table_name)
                    FROM information_schema.table_constraints as c
                    	JOIN information_schema.key_column_usage AS x ON
                        	c.constraint_name = x.constraint_name and
                            x.column_name = pz.column_name
                        JOIN information_schema.constraint_column_usage AS y ON 
                        	y.constraint_name = c.constraint_name and
                            y.constraint_schema = c.constraint_schema
                    WHERE c.table_name = pz.table_name and
                          c.table_schema = pz.table_schema and
                          c.constraint_type = 'FOREIGN KEY'
                    LIMIT 1
                )) as relation,
                (
                	SELECT 
                    	concat(y.column_name)
                    FROM information_schema.table_constraints as c
                    	JOIN information_schema.key_column_usage AS x ON
                             c.constraint_name = x.constraint_name and
                             x.column_name = pz.column_name
                        JOIN information_schema.constraint_column_usage AS y ON 
                        	y.constraint_name = c.constraint_name and
                            y.constraint_schema = c.constraint_schema
                    WHERE c.table_name = pz.table_name and
                     	  c.table_schema = pz.table_schema and
                          c.constraint_type = 'FOREIGN KEY'
                    LIMIT 1
                ) as relcol,
             pz.depency, COALESCE((
               SELECT 
                  max(column_order) 
               FROM framework.config 
               WHERE viewid = _viewid),0) + 1,
             pz.depencycol	
    FROM
    	
        (SELECT 

           	ROW_NUMBER() OVER(order by f.column_id) as t,  
            f.*
           
        FROM (
        	SELECT 
            	DISTINCT 
            	t.column_name as col,
                coalesce(pgd.description, t.column_name) as title,                         
                null as relation,
                null as depencycol,
                t.ordinal_position as column_id,
                false as depency,
                t.column_name,
                t.table_schema,
                t.table_name
            FROM information_schema.columns as t
            	LEFT JOIN pg_catalog.pg_statio_all_tables as st on
                         st.schemaname = t.table_schema and st.relname =
                         t.table_name
            	LEFT JOIN pg_catalog.pg_description pgd on pgd.objoid =
                         st.relid and pgd.objsubid = t.ordinal_position
            WHERE concat(t.table_schema, '.', t.table_name) = _tabname
            	--AND coalesce(pgd.description, t.column_name) = COALESCE(_colname, coalesce(pgd.description, t.column_name))
            UNION ALL
            SELECT 
            	x.table_name as col,       
                x.table_name as title,
                concat(x.table_schema, '.', x.table_name) as relation,
                x.column_name as depencycol,
                (
                 	SELECT count(t.*)
                    FROM information_schema.columns as t
                    WHERE concat(t.table_schema, '.', t.table_name) = _tabname
                ) + 1 as column_id,
                true as depency,
                '' as column_name,
                '' as table_schema,
                '' as table_name
            FROM information_schema.key_column_usage as x
                 LEFT JOIN information_schema.referential_constraints as c on
                         c.constraint_name = x.constraint_name and
                         c.constraint_schema = x.constraint_schema
                 LEFT JOIN information_schema.key_column_usage y on
                         y.ordinal_position = x.position_in_unique_constraint and
                         y.constraint_name = c.unique_constraint_name
        	WHERE concat(y.table_schema, '.', y.table_name) = _tabname and
                  y.table_name is not null
        ) as f
       
        ORDER BY 
        	f.column_id) as pz
         WHERE pz.title = _col;

    
END;
$$;


ALTER FUNCTION framework.fn_config_inscol(injson json) OWNER TO postgres;

--
-- TOC entry 3092 (class 0 OID 0)
-- Dependencies: 309
-- Name: FUNCTION fn_config_inscol(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_inscol(injson json) IS 'add fn column in config';


--
-- TOC entry 310 (class 1255 OID 179926)
-- Name: fn_config_relation(integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_relation(_id integer, OUT _relation character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
/*DECLARE
  variable_name datatype;*/
BEGIN
	-- FOR CONFIG RELATION COLUMN
	
    SELECT
    	CASE WHEN 
        	c.type like '%_api'
        THEN
        	c.select_api
        WHEN c.type like 'multi%' and 
        	 c.type not like '%_api'
        THEN
        	c.multiselecttable
        ELSE
          COALESCE(
            c.relation,c.select_api,c.multiselecttable
          )
        END
    FROM framework.config as c
    WHERE c.id = _id
    INTO _relation;


END;
$$;


ALTER FUNCTION framework.fn_config_relation(_id integer, OUT _relation character varying) OWNER TO postgres;

--
-- TOC entry 3093 (class 0 OID 0)
-- Dependencies: 310
-- Name: FUNCTION fn_config_relation(_id integer, OUT _relation character varying); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_relation(_id integer, OUT _relation character varying) IS 'FOR CONFIG RELATION COLUMN';


--
-- TOC entry 311 (class 1255 OID 179927)
-- Name: fn_config_relationcolumns(integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_relationcolumns(_id integer, OUT relation_columns character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_relationcolums JSON;
    _multicolums JSON;
    
BEGIN
	-- FOR CONFIG RELATIONCOLUMNS COLUMN

	SELECT
    	c.relationcolums,
        c.multicolums
    FROM framework.config as c
    WHERE c.id = _id
    INTO _relationcolums, _multicolums;
    
    IF coalesce(_relationcolums::varchar,'[]') <> '[]'
    THEN
    	SELECT
        	string_agg((value->>'label'),', ')
        FROM json_array_elements(_relationcolums)
        INTO relation_columns;
    ELSE
    	IF coalesce(_multicolums::varchar,'[]') <> '[]'
        THEN
          SELECT
              string_agg((value->>'label'),', ')
          FROM json_array_elements(_multicolums)
          INTO relation_columns;
        END IF;
    END IF;

END;
$$;


ALTER FUNCTION framework.fn_config_relationcolumns(_id integer, OUT relation_columns character varying) OWNER TO postgres;

--
-- TOC entry 3094 (class 0 OID 0)
-- Dependencies: 311
-- Name: FUNCTION fn_config_relationcolumns(_id integer, OUT relation_columns character varying); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_relationcolumns(_id integer, OUT relation_columns character varying) IS 'FOR CONFIG RELATIONCOLUMNS COLUMN';


--
-- TOC entry 313 (class 1255 OID 179928)
-- Name: fn_config_selectapi(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_selectapi(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _viewid int;
  tabname varchar(350);
BEGIN
	-- select_api for column add in config
	_viewid = (injson->'inputs')->>'id';
    
    IF _viewid is null THEN
    	PERFORM raiserror('viewid is null, can not find out table name');
    END IF;
	
    SELECT 
    	v.tablename
    FROM framework.views as v
    WHERE v.id = _viewid 
    INTO tabname; 
        
    SELECT 
    	array_to_json(array_agg(row_to_json(d)))
    FROM (
    	SELECT 
           	DISTINCT 
           	t.column_name as label,
            coalesce(pgd.description, t.column_name) as value
        FROM information_schema.columns as t
           	LEFT JOIN pg_catalog.pg_statio_all_tables as st on
				st.schemaname = t.table_schema and 
                st.relname = t.table_name
          	LEFT JOIN pg_catalog.pg_description pgd on 
            	pgd.objoid = st.relid and 
                pgd.objsubid = t.ordinal_position
        WHERE concat(t.table_schema, '.', t.table_name) = tabname
            UNION ALL
        SELECT 
           	x.table_name as label,       
            x.table_name as value
        FROM information_schema.key_column_usage as x
             LEFT JOIN information_schema.referential_constraints as c on
                  c.constraint_name = x.constraint_name and
        	      c.constraint_schema = x.constraint_schema
             LEFT JOIN information_schema.key_column_usage y on
             	y.ordinal_position = x.position_in_unique_constraint and
                y.constraint_name = c.unique_constraint_name
        WHERE concat(y.table_schema, '.', y.table_name) = tabname and
        	  y.table_name is not null
    ) as d
    INTO outjson;
 	
    outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_config_selectapi(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3095 (class 0 OID 0)
-- Dependencies: 313
-- Name: FUNCTION fn_config_selectapi(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_selectapi(injson json, OUT outjson json) IS 'select_api for column add in config';


--
-- TOC entry 314 (class 1255 OID 179929)
-- Name: fn_config_settings_apply(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_settings_apply(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _col varchar(150);
  _setting varchar(150);
  _selected json;
  _viewid int;
BEGIN
	-- apply all columns settings in config by chosed column
  _col = injson->>'col';
  _setting = injson->>'setting';
  _viewid = injson->>'viewid';
  
  -- mock yet
  
END;
$$;


ALTER FUNCTION framework.fn_config_settings_apply(injson json) OWNER TO postgres;

--
-- TOC entry 3096 (class 0 OID 0)
-- Dependencies: 314
-- Name: FUNCTION fn_config_settings_apply(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_settings_apply(injson json) IS 'apply all columns settings in config by chosed column';


--
-- TOC entry 315 (class 1255 OID 179930)
-- Name: fn_config_to_json(integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_config_to_json(_viewid integer, OUT _config json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- CONFIG FROM TABLE TO JSON BY VIEW ID

  SELECT
     array_to_json(array_agg(row_to_json(d)))
  FROM
      (SELECT 
        concat(c.col,'_',c.id::varchar) as key,
        c.col,
        c.title,
        c.column_id,
        c.classname,
        c.depency,
        c.depencycol,
        c.relcol,
        c.column_order,
        c."join",
        c.updatable,
        c.required,
        c.orderby,
        c.orderbydesc,
        c.related,
        c."table",
        c.width,
        c.visible,
        c."type",
        c.multiselecttable,
        c.editable,
        c.tpath,
        c.relation,
        CASE WHEN c.fn is not null
        THEN
        	json_build_object('value', c.fn, 'label', c.fn, 'functype', f.functype) 
        ELSE 
        	null
        END as fn,
        c.select_api,
        c.t,
        c.relatecolumn,
        c.roles,
        COALESCE((
         SELECT
            array_to_json(array_agg(row_to_json(d)))
          FROM(
           SELECT
            value as label,
            value as value
           FROM json_array_elements_text(c.relationcolums) as r
			) as d
         ),'[]') as relationcolums,
         (SELECT
          	array_to_json(array_agg(row_to_json(d)))
          FROM
           (SELECT
                m.value::varchar as value, 
                m.value::varchar as label
            FROM json_array_elements_text(c.multicolums) as m) as d) as multicolums,
          CASE WHEN c.fn is not null
          THEN
          COALESCE((
            SELECT
              array_to_json(array_agg(row_to_json(d)))
            FROM
              (
                SELECT * FROM (
                  SELECT (
                        CASE 
                        WHEN value::varchar not in ('_userid_', '_orgid_', '_orgs_') 
                        THEN cc.col 
                        ELSE value::varchar
                        END 
                      ) as label, (
                        CASE 
                        WHEN value::varchar not in ('_userid_', '_orgid_', '_orgs_') 
                        THEN cc.title
                        ELSE value::varchar
                        END 
                      ) as value, (
                        CASE 
                        WHEN value::varchar not in ('_userid_', '_orgid_', '_orgs_') 
                        THEN concat(cc.col,'_',cc.id::varchar)
                        ELSE value::varchar
                        END 
                      ) as key,
                      CASE WHEN cc.related THEN cc.t
                      ELSE '1'
                      END as t
                  FROM (
                    SELECT
                        row_number() over (order by 0) as r,
                        value as value
                    FROM json_array_elements_text(c.fncolumns) as f 
                    --WHERE value::varchar not in ('_userid_', '_orgid_', '_orgs_')
                ) as  ff
                    LEFT JOIN framework.config as cc on cc.viewid = _viewid and cc.id::varchar = ff.value::varchar
                ORDER BY ff.r ) as dd
              
                             
               /* SELECT
                    cc.col as label,
                    cc.title as value,
                    concat(cc.col,'_',cc.id::varchar) as key,
                    CASE WHEN cc.related THEN cc.t
                    ELSE '1'
                    END as t
                FROM json_array_elements_text(c.fncolumns) as ff
                    LEFT JOIN framework.config as cc on cc.viewid = _viewid and cc.title = ff.value::varchar*/
              ) as d),'[]')
          ELSE
          	null
          END as fncolumns,
              
          (SELECT
            array_to_json(array_agg(row_to_json(d)))
           FROM
           (
            SELECT 
                json_build_object('label',df.act,'value',df.act) as act,
                json_build_object('label',df.bool,'value',df.bool) as bool,
                df.value
            FROM framework.defaultval as df
            WHERE df.configid = c.id) as d) as defaultval,
          (SELECT
            array_to_json(array_agg(row_to_json(d)))
           FROM
            (
            SELECT
                vs.value,
                json_build_object('value',op.value,'js',op.js) as operation,
                json_build_object(
                    'value',cc.title,
                    'label',cc.title,
                    't', cc.t,
                    'key',concat(cc.col,'_',cc.id::varchar)
                ) as col
            FROM framework.visible_condition as vs
                LEFT JOIN framework.operations as op on op.value = vs.operation
                LEFT JOIN framework.config as cc on /*cc.viewid = _viewid and*/ cc.id = vs.val_desc
            WHERE vs.configid = c.id
            ) as d) as visible_condition,
          (SELECT
            array_to_json(array_agg(row_to_json(d)))
           FROM
            (SELECT
                  json_build_object('label',sc.col,'value', sc.col) as col,
                  sc.const,
                  json_build_object(
                      'value', op.value,
                      'js', op.js,
                      'python', op.python,
                      'sql', op.sql
                  ) as operation,
                  json_build_object(
                      'value',cc.title,
                      'label',cc.title,
                      't', cc.t,
                      'key',concat(cc.col,'_',cc.id::varchar)
                  ) as value
              FROM framework.select_condition as sc
                  LEFT JOIN framework.operations as op on op.value = sc.operation
                  LEFT JOIN framework.config as cc on cc.viewid = _viewid and cc.id = sc.val_desc
              WHERE sc.configid = c.id      
            ) as d) as select_condition 
  FROM framework.config as c
    LEFT JOIN framework.functions as f on f.funcname = c.fn
  WHERE c.viewid = _viewid
  ORDER BY c.column_order) as d
  INTO _config;
  
  _config = COALESCE(_config,'[]');
END;
$$;


ALTER FUNCTION framework.fn_config_to_json(_viewid integer, OUT _config json) OWNER TO postgres;

--
-- TOC entry 3097 (class 0 OID 0)
-- Dependencies: 315
-- Name: FUNCTION fn_config_to_json(_viewid integer, OUT _config json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_config_to_json(_viewid integer, OUT _config json) IS 'CONFIG FROM TABLE TO JSON BY VIEW ID';


--
-- TOC entry 316 (class 1255 OID 179931)
-- Name: fn_configsettings_selectapi(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_configsettings_selectapi(insjon json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- SELECT CONFIG SETTINGS DIC
	SELECT
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT
    	c.sname as label,
        c.sname as value
    FROM framework.configsettings as c) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');
    


END;
$$;


ALTER FUNCTION framework.fn_configsettings_selectapi(insjon json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3098 (class 0 OID 0)
-- Dependencies: 316
-- Name: FUNCTION fn_configsettings_selectapi(insjon json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_configsettings_selectapi(insjon json, OUT outjson json) IS 'SELECT CONFIG SETTINGS DIC';


--
-- TOC entry 317 (class 1255 OID 179932)
-- Name: fn_copyview(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_copyview(injson json, OUT _newid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	_id int;  
    _title varchar(150);
    _path varchar(150);
BEGIN
	-- COPY VIEW 


	_id = injson->>'id';
    
    SELECT 
    	v.title,
        v."path"
    FROM framework.views as v
    WHERE v.id = _id
    INTO _title, _path;
    
    _newid = nextval('framework.views_id_seq'::regclass);
    
    _title = concat(_title,'_copy_',_newid);
    _path = concat(_path,'_copy_',_newid);
    
    INSERT INTO framework.views (
      id, title, descr, tablename,
      viewtype, pagination, config,
      "path", groupby, filters,
      acts, roles, classname,
      orderby, ispagesize, pagecount,
      foundcount, subscrible, checker,
      "copy"
    )
    SELECT 
    	_newid, _title, descr, tablename,
        viewtype, pagination, config,
        _path, groupby, filters,
        acts, roles, classname,
        orderby, ispagesize, pagecount, 
        foundcount, subscrible, checker,
        true 
    FROM framework.views  
    WHERE id = _id;
    
    
    INSERT INTO framework.config (
      viewid, t, col, column_id,
      title, type, roles,
      visible, required, width,
      "join", classname, updatable,
      relation, select_api, multiselecttable,
      orderby, orderbydesc, relcol,
      depency, relationcolums, multicolums,
      depencycol, column_order, fn,
      fncolumns, relatecolumn, "table",
      related, tpath, copy
   )
   SELECT
      _newid, t, col, column_id,
      title, type, roles,
      visible, required, width,
      "join", classname, updatable,
      relation, select_api, multiselecttable,
      orderby, orderbydesc, relcol,
      depency, relationcolums, multicolums,
      depencycol, column_order, fn,
      fncolumns, relatecolumn, "table" ,
      related, tpath, true
   FROM framework.config
   WHERE viewid =_id and fn is null;
   
    INSERT INTO framework.config (
      viewid, t, col, column_id,
      title, type, roles,
      visible, required, width,
      "join", classname, updatable,
      relation, select_api, multiselecttable,
      orderby, orderbydesc, relcol,
      depency, relationcolums, multicolums,
      depencycol, column_order, fn,
      fncolumns, relatecolumn, "table",
      related, tpath, copy
   )
   SELECT
      _newid, cv.t, cv.col, cv.column_id,
      cv.title, cv.type, cv.roles,
      cv.visible, cv.required, cv.width,
      cv."join", cv.classname, cv.updatable,
      cv.relation, cv.select_api, cv.multiselecttable,
      cv.orderby, cv.orderbydesc, cv.relcol,
      cv.depency, cv.relationcolums, cv.multicolums,
      cv.depencycol, cv.column_order, cv.fn, (array_to_json(ARRAY(
        SELECT cc.id
        FROM framework.config as cc  
            JOIN framework.config as c on c.viewid = _id and cc.title = c.title
            JOIN json_array_elements_text(cv.fncolumns) as j on j.value::varchar::int = c.id 
        WHERE  cc.viewid = _newid 
      ))), cv.relatecolumn, cv."table" ,
      cv.related, cv.tpath, true
   FROM framework.config as cv
   WHERE cv.viewid =_id and cv.fn is not null;
  
   INSERT INTO framework.visible_condition (
    configid,
    val_desc,
    col, title,
    operation, value 
  ) 
  SELECT
    cc.id,
    (
     SELECT 
     	cccc.id
     FROM framework.config as ccc 
     JOIN framework.config as cccc on cccc.viewid = _newid and cccc.title = ccc.title
     WHERE  ccc.id = vs.val_desc
    ),
    vs.col, vs.title,
    vs.operation, vs.value 
  FROM framework.visible_condition as vs
  	JOIN framework.config as c on c.viewid = _id and c.id = vs.configid
    JOIN framework.config as cc on cc.viewid = _newid and cc.title = c.title;
    
  INSERT INTO framework.select_condition (
    configid, col,
    operation, const,
    value, val_desc 
  )
  SELECT
  	DISTINCT
    cc.id, sc.col,
    sc.operation, sc.const,
    sc.value, sc.val_desc 
  FROM framework.select_condition as sc
  	JOIN framework.config as c on c.viewid = _id and c.id = sc.configid
    JOIN framework.config as cc on cc.viewid = _newid and cc.title = c.title;
  
  
  INSERT INTO framework.defaultval (
    configid, bool,
    act, value 
  )
  SELECT 
  	DISTINCT
      cc.id, df.bool,
      df.act, df.value 
  FROM framework.defaultval as df
      JOIN framework.config as c on c.viewid = _id and c.id = df.configid
      JOIN framework.config as cc on cc.viewid = _newid and cc.title = c.title;
    
  
  INSERT INTO framework.actions (
    column_order, title,viewid,
    icon,classname, act_url, api_method,
    api_type, refresh_data, ask_confirm,
    roles, forevery, main_action, act_type
  ) 
  SELECT
    a.column_order, a.title,_newid,
    a.icon, a.classname, a.act_url, a.api_method,
    a.api_type, a.refresh_data, a.ask_confirm,
    a.roles, a.forevery,
    a.main_action,
    a.act_type
  FROM framework.actions as a
  WHERE a.viewid = _id;
  
  INSERT INTO framework.act_visible_condions (
    actionid, val_desc, col,
    title, operation, value
  ) 
  SELECT
  	DISTINCT
    ac2.id, a.val_desc, a.col,
    a.title, a.operation, a.value
  FROM framework.act_visible_condions as a
  	JOIN framework.actions as ac on ac.id = a.actionid and ac.viewid = _id
    JOIN framework.actions as ac2 on ac2.viewid = _newid and ac2.title = ac.title;
  
  INSERT INTO framework.act_parametrs (
    actionid, paramtitle, paramt,
    paramconst, paraminput, paramcolumn,
    val_desc, query_type
  )
  SELECT
  	DISTINCT
  	ac2.id, paramtitle, paramt,
    paramconst, paraminput, paramcolumn,
    val_desc, query_type
  FROM framework.act_parametrs as a
  	JOIN framework.actions as ac on ac.id = a.actionid and ac.viewid = _id
    JOIN framework.actions as ac2 on ac2.viewid = _newid and ac2.title = ac.title;
  
  INSERT INTO framework.filters (
    column_order, viewid, title,
    type, classname, "column",
    columns, roles, t, "table" 
  )
  SELECT
    column_order, _newid, title,
    type, classname, "column",
    columns, roles, t, "table" 
  FROM framework.filters
  WHERE viewid = _id;
  
  UPDATE framework.views
  SET copy = FALSE
  WHERE id = _id;
  
  UPDATE framework.config
  SET copy = FALSE
  WHERE viewid = _id;
END;
$$;


ALTER FUNCTION framework.fn_copyview(injson json, OUT _newid integer) OWNER TO postgres;

--
-- TOC entry 3099 (class 0 OID 0)
-- Dependencies: 317
-- Name: FUNCTION fn_copyview(injson json, OUT _newid integer); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_copyview(injson json, OUT _newid integer) IS 'COPY VIEW ';


--
-- TOC entry 318 (class 1255 OID 179934)
-- Name: fn_createconfig(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_createconfig(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  tabname varchar(350);
	_colname varchar(200);
BEGIN
	-- CREATE VIEW's CONFIG
	tabname = injson->>'tabname';
    --_colname = injson->>'colname';
        
    SELECT 
    	array_to_json(array_agg(row_to_json(d)))
    FROM (
    	SELECT 
           ROW_NUMBER() OVER(order by f.column_id) as t,
           f.*
        FROM (
        	SELECT 
            	DISTINCT 
            	t.column_name as col,
                coalesce(pgd.description, t.column_name) as title,                         
                'label' as type,
                true as visible,
                concat(
                	t.column_name,'_',
                    SUBSTRING((uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36)),1,5)
                ) as key,
                (
                	SELECT 
                    	concat(y.table_schema, '.', y.table_name)
                    FROM information_schema.table_constraints as c
                    	JOIN information_schema.key_column_usage AS x ON
                        	c.constraint_name = x.constraint_name and
                            x.column_name = t.column_name
                        JOIN information_schema.constraint_column_usage AS y ON 
                        	y.constraint_name = c.constraint_name and
                            y.constraint_schema = c.constraint_schema
                    WHERE c.table_name = t.table_name and
                          c.table_schema = t.table_schema and
                          c.constraint_type = 'FOREIGN KEY'
                    LIMIT 1
                ) as relation,
                (
                	SELECT 
                    	concat(y.column_name)
                    FROM information_schema.table_constraints as c
                    	JOIN information_schema.key_column_usage AS x ON
                             c.constraint_name = x.constraint_name and
                             x.column_name = t.column_name
                        JOIN information_schema.constraint_column_usage AS y ON 
                        	y.constraint_name = c.constraint_name and
                            y.constraint_schema = c.constraint_schema
                    WHERE c.table_name = t.table_name and
                     	  c.table_schema = t.table_schema and
                          c.constraint_type = 'FOREIGN KEY'
                    LIMIT 1
                ) as relcol,
                '[]' as relationcolums,
                false as "join",
                false as onetomany,
                false as required,
                null as defaultval,
                '' as width,
                t.ordinal_position as column_id,
                false as depency,
                null as depencycol,
                '[]' as roles,
                '' as classname
            FROM information_schema.columns as t
            	LEFT JOIN pg_catalog.pg_statio_all_tables as st on
                         st.schemaname = t.table_schema and st.relname =
                         t.table_name
            	LEFT JOIN pg_catalog.pg_description pgd on pgd.objoid =
                         st.relid and pgd.objsubid = t.ordinal_position
            WHERE concat(t.table_schema, '.', t.table_name) = tabname
            	--AND coalesce(pgd.description, t.column_name) = COALESCE(_colname, coalesce(pgd.description, t.column_name))
            UNION ALL
            SELECT 
            	x.table_name as col,       
                x.table_name as title,
                'array' as type,
                false as visible,
                concat(
                	x.table_name, '_',
                    SUBSTRING((uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36)),1,5)
                ) as key,
                concat(x.table_schema, '.', x.table_name) as relation,
                null as relcol,
                '[]' as relationcolums,
                false as join,
                true as onetomany,
                false as required,
                null as defaultval,
                '' as width,
                (
                 	SELECT count(t.*)
                    FROM information_schema.columns as t
                    WHERE concat(t.table_schema, '.', t.table_name) = tabname
                ) + 1 as column_id,
                true as depency,
                x.column_name as depencycol,
                '[]' as roles,
                '' as classname
            FROM information_schema.key_column_usage as x
                 LEFT JOIN information_schema.referential_constraints as c on
                         c.constraint_name = x.constraint_name and
                         c.constraint_schema = x.constraint_schema
                 LEFT JOIN information_schema.key_column_usage y on
                         y.ordinal_position = x.position_in_unique_constraint and
                         y.constraint_name = c.unique_constraint_name
        	WHERE concat(y.table_schema, '.', y.table_name) = tabname and
                  y.table_name is not null
        ) as f
        ORDER BY 
        	f.column_id,
        	relation
    ) as d
    INTO outjson;
 	
    outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_createconfig(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3100 (class 0 OID 0)
-- Dependencies: 318
-- Name: FUNCTION fn_createconfig(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_createconfig(injson json, OUT outjson json) IS 'CREATE VIEW''s CONFIG';


--
-- TOC entry 312 (class 1255 OID 179935)
-- Name: fn_createconfig_new(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_createconfig_new(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  tabname varchar(350);
BEGIN

  tabname = injson->>'tabname';
  SELECT array_to_json(array_agg(row_to_json(d)))
  FROM (
         SELECT ROW_NUMBER() OVER(
         order by f.column_id) as t,
                  *,
                  '[]'::JSON as relationcolums,
                  '[]'::JSON as roles
         FROM (
                SELECT distinct t.column_name as col,
                       substring(coalesce(pgd.description, t.column_name), 1, 62) as title,
                       framework.fn_htmldatatype(t.data_type) as type,
                       true as visible, 
                       (
                         SELECT concat(y.table_schema, '.', y.table_name)
                         FROM information_schema.table_constraints as c
                              JOIN information_schema.key_column_usage AS x ON
                                c.constraint_name = x.constraint_name and
                                x.column_name = t.column_name
                              JOIN information_schema.constraint_column_usage AS
                                y ON y.constraint_name = c.constraint_name and
                                y.column_name = t.column_name
                         WHERE c.table_name = t.table_name and
                               c.table_schema = t.table_schema and
                               c.constraint_type = 'FOREIGN KEY'
                         LIMIT 1
                       ) as relation,
                       (
                         SELECT concat(y.column_name)
                         FROM information_schema.table_constraints as c
                              JOIN information_schema.key_column_usage AS x ON
                                c.constraint_name = x.constraint_name and
                                x.column_name = t.column_name
                              JOIN information_schema.constraint_column_usage AS
                                y ON y.constraint_name = c.constraint_name and
                                y.column_name = t.column_name
                         WHERE c.table_name = t.table_name and
                               c.table_schema = t.table_schema and
                               c.constraint_type = 'FOREIGN KEY'
                         LIMIT 1
                       ) as relcol,
                       false as "join",
                       false as onetomany,
                       null as defaultval,
                       ''                       as width,
                       t.ordinal_position as column_id,
                       false as depency,
                       null as depencycol,
                       ''                       as classname
                FROM information_schema.columns as t
                     left join pg_catalog.pg_statio_all_tables as st on
                       st.schemaname = t.table_schema and st.relname =
                       t.table_name
                     left join pg_catalog.pg_description pgd on pgd.objoid =
                       st.relid and pgd.objsubid = t.ordinal_position 
                WHERE concat(t.table_schema, '.', t.table_name) = tabname
                UNION ALL
                SELECT x.table_name as col,
                       --,        
                       x.table_name as title,
                       'array'                       as type,
                       false as visible,
                       concat(x.table_schema, '.', x.table_name) as relation,
                       null as relcol,
                       --'[]'::JSON as relationcolums,
                       false as join,
                       true as onetomany,
                       null as defaultval,
                       ''                       as width,
                       (
                         SELECT count(t.*)
                         FROM information_schema.columns as t
                         WHERE concat(t.table_schema, '.', t.table_name) =
                           tabname
                       ) + 1 as column_id,
                       true as depency,
                       x.column_name as depencycol,
                       --'[]'::JSON as roles,
                       ''                       as classname
                FROM information_schema.key_column_usage as x
                     --  and t.column_name = x.column_name
                     left join information_schema.referential_constraints as c
                       on c.constraint_name = x.constraint_name and
                       c.constraint_schema = x.constraint_schema
                     left join information_schema.key_column_usage y on
                       y.ordinal_position = x.position_in_unique_constraint and
                       y.constraint_name = c.unique_constraint_name
                WHERE concat(y.table_schema, '.', y.table_name) = tabname and
                      y.table_name is not null
              ) as f
         ORDER BY f.column_id,
                  relation
       ) as d
  INTO outjson;

  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_createconfig_new(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 319 (class 1255 OID 179936)
-- Name: fn_cryptosess(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_cryptosess(injson json, OUT sessid character) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
  user_id int;
  _orgid int;
  _created timestamp;
  
  _thumbprint varchar(200);
BEGIN
	-- AUTH IN WITH CRYPTOKEY
    
    _thumbprint = injson->>'thumbprint';
    
    IF _thumbprint is null THEN
    	PERFORM raiserror('No Certificate');
    END IF;
	
	SELECT 
    	u.id,
        u.orgs->0
    FROM framework.users as u
    WHERE u.isactive and u.thumbprint = _thumbprint
    INTO user_id, _orgid;
    
    IF user_id is null THEN
    	perform raiserror('User not active or not found. Check your certificate');
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


ALTER FUNCTION framework.fn_cryptosess(injson json, OUT sessid character) OWNER TO postgres;

--
-- TOC entry 3101 (class 0 OID 0)
-- Dependencies: 319
-- Name: FUNCTION fn_cryptosess(injson json, OUT sessid character); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_cryptosess(injson json, OUT sessid character) IS 'AUTH IN WITH CRYPTOKEY';


--
-- TOC entry 320 (class 1255 OID 179937)
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
	-- DELETE ROW IN LIST COMPONENT (FROM TABLE)

  -- = injson->>'tablename';	
  _id = trim(injson->>'id');
  _userid = injson->>'userid';
  _viewid = injson->>'viewid';
  
    IF _viewid is NULL
    THEN
      perform raiserror('view id is null');
    END IF; 
    
    SELECT 
    	roles,
        tablename
    FROM framework.views 
    WHERE id = _viewid
    INTO _viewroles, _tablename;
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
     	JOIN json_array_elements_text(_userroles) as r on 
        	((v.value::json->>'value')::varchar = r.value::varchar
            	OR
             v.value::varchar = r.value::varchar
            )
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
 
  _squery = concat('DELETE FROM ', _tablename, ' WHERE upper(id::varchar) = $1; ');
  EXECUTE format(_squery) USING upper(_id);
END;
$_$;


ALTER FUNCTION framework.fn_deleterow(injson json) OWNER TO postgres;

--
-- TOC entry 3102 (class 0 OID 0)
-- Dependencies: 320
-- Name: FUNCTION fn_deleterow(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_deleterow(injson json) IS 'DELETE ROW IN LIST COMPONENT (FROM TABLE)';


--
-- TOC entry 321 (class 1255 OID 179938)
-- Name: fn_dialog_addadmin(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_addadmin(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _user_to_add int;
  _dialogid int;
  _dtype smallint;
  _admins json;
  _od json;
  _users JSON;
  _nw JSON;
BEGIN
	_userid = injson->>'userid';
    _dialogid = injson->>'id';
    _user_to_add = injson->>'user_to_add';


	IF _dialogid IS NULL 
    THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    IF _user_to_add is null 
    THEN 
  	  PERFORM raiserror('user_to_add is null');
    END IF;
    
    SELECT 
    	d.dialog_admins,
        d.dtype,
        d.users
    FROM framework.dialogs as d
    WHERE d.id = _dialogid
    INTO _admins, _dtype, _users; 

    IF _dtype = '1'
    THEN 
        RETURN;
    END IF;
    
    IF _user_to_add not in (
    	SELECT
        	value::varchar::int
    	FROM json_array_elements_text(_users)
    )
    THEN
    	PERFORM raiserror('User not in dialog');
    END IF;
    
    IF _user_to_add in (
    	SELECT
        	value::varchar::int
    	FROM json_array_elements_text(_admins)
    )
    THEN
    	PERFORM raiserror('User already admin');
    END IF;
    
    
    IF (
        SELECT
            count(*)
        FROM json_array_elements_text(_admins)
        WHERE value::varchar::int = _userid
    ) = 0
    THEN
        PERFORM raiserror('ACCESS DENIED');
    END IF;
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _od;
    
    UPDATE framework.dialogs
    SET    
		dialog_admins = _admins::jsonb||concat('[',_user_to_add::varchar,']')::jsonb
    WHERE id = _dialogid;


    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, oldata, newdata,
      userid
    ) VALUES (
      'framework.dialogs', _dialogid::VARCHAR,
      '2',_od,_nw,
      _userid
     );
END;
$$;


ALTER FUNCTION framework.fn_dialog_addadmin(injson json) OWNER TO postgres;

--
-- TOC entry 3103 (class 0 OID 0)
-- Dependencies: 321
-- Name: FUNCTION fn_dialog_addadmin(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_addadmin(injson json) IS 'ADD USER TO ADMINS';


--
-- TOC entry 322 (class 1255 OID 179939)
-- Name: fn_dialog_adduser(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_adduser(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _user_to_add int;
  _dialogid int;
  _dtype smallint;
  _admins json;
  _od json;
  _users JSON;
  _nw JSON;
BEGIN
	_userid = injson->>'userid';
    _dialogid = injson->>'id';
    _user_to_add = injson->>'user_to_add';


	IF _dialogid IS NULL 
    THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    IF _user_to_add is null 
    THEN 
  	  PERFORM raiserror('user_to_add is null');
    END IF;
    
    SELECT 
    	d.dialog_admins,
        d.dtype,
        d.users
    FROM framework.dialogs as d
    WHERE d.id = _dialogid
    INTO _admins, _dtype, _users; 

    IF _dtype = '1'
    THEN 
        RETURN;
    END IF;
    
    IF _user_to_add in (
    	SELECT
        	value::varchar::int
    	FROM json_array_elements_text(_users)
    )
    THEN
    	PERFORM raiserror('User already in dialog');
    END IF;
    
    
    
    IF (
        SELECT
            count(*)
        FROM json_array_elements_text(_admins)
        WHERE value::varchar::int = _userid
    ) = 0
    THEN
        PERFORM raiserror('ACCESS DENIED');
    END IF;
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _od;
    
    UPDATE framework.dialogs
    SET    
		users = users::jsonb||concat('[',_user_to_add::varchar,']')::jsonb
    WHERE id = _dialogid;


    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, oldata, newdata,
      userid
    ) VALUES (
      'framework.dialogs', _dialogid::VARCHAR,
      '2',_od,_nw,
      _userid
     );
END;
$$;


ALTER FUNCTION framework.fn_dialog_adduser(injson json) OWNER TO postgres;

--
-- TOC entry 3104 (class 0 OID 0)
-- Dependencies: 322
-- Name: FUNCTION fn_dialog_adduser(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_adduser(injson json) IS 'ADD USER IN DIALOG';


--
-- TOC entry 323 (class 1255 OID 179940)
-- Name: fn_dialog_edit(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_edit(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _id int;
  _title varchar(150);
  _photo json;
  _admins json;
  _dialog_admins json;
  _dtype smallint;
  _od json;
  _nw json;
  _users json;
BEGIN
	_userid = injson->>'userid';
    _id = injson->>'id';
    _title = injson->>'title';
   -- _photo = injson->>'photo';
    _photo = injson->>'value';
    _dialog_admins = injson->>'dialog_admins';
   -- _users = injson->>'users';
    SELECT 
    	d.dialog_admins,
        d.dtype
    FROM framework.dialogs as d
    WHERE d.id = _id
    INTO _admins, _dtype; 
    
    
    IF _dtype = '1'
    THEN 
        RETURN;
    END IF;
    
    IF (
        SELECT
            count(*)
        FROM json_array_elements_text(_admins)
        WHERE value::varchar::int = _userid
    ) = 0
    THEN
        PERFORM raiserror('ACCESS DENIED');
    END IF;
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _id
    ) as z
    INTO _od;
    
    UPDATE framework.dialogs
    SET    
        title = coalesce(_title,title),
        photo = coalesce(_photo,photo),
        dialog_admins = coalesce(_dialog_admins,dialog_admins)--,
		--users = coalesce(_users,'[]')
    WHERE id = _id;
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _id
    ) as z
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, oldata, newdata,
      userid
    ) VALUES (
      'framework.dialogs', _id::VARCHAR,
      '2',_od,_nw,
      _userid
     );
    
END;
$$;


ALTER FUNCTION framework.fn_dialog_edit(injson json) OWNER TO postgres;

--
-- TOC entry 3105 (class 0 OID 0)
-- Dependencies: 323
-- Name: FUNCTION fn_dialog_edit(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_edit(injson json) IS 'EDIT DIALOG';


--
-- TOC entry 324 (class 1255 OID 179941)
-- Name: fn_dialog_group_create(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_group_create(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  --_message_text varchar;
  _dialog_id int;
  _users JSON;
 -- _files json;
  --_images json;
  _id int;
  _title varchar(150);
  _photo json;
BEGIN
	
	_userid = injson->>'userid';
    _users = injson->>'users';
   -- _message_text = injson->>'message_text';
   -- _files = injson->>'files';
    --_images = injson->>'images';
    _title = injson->>'title';
    _photo = injson->>'value';
    
    -- CHECKS
    IF _userid is NULL 
    THEN
    	PERFORM raiserror('userid is null');
    END IF;
    
    IF _users is NULL 
    THEN
    	PERFORM raiserror('users is null');
    END IF;
    
    -- USERS FOR GROUP DIALOG
    _users = (
      array_to_json(ARRAY(
        SELECT
            _userid
      ))::jsonb||_users::jsonb
    )::json;
    
    -- ADD DIALOG
    _dialog_id = nextval('framework.dialogs_id_seq'::regclass);
    
	_title = COALESCE(_title,CONCAT('untitled_',_dialog_id::varchar));
    INSERT INTO framework.dialogs (
       id, title, users, userid, 
       dtype,  photo 
    ) VALUES (
       _dialog_id, _title, _users ,_userid, 
       '2', coalesce(_photo,'[]')
    );
    
END;
$$;


ALTER FUNCTION framework.fn_dialog_group_create(injson json) OWNER TO postgres;

--
-- TOC entry 3106 (class 0 OID 0)
-- Dependencies: 324
-- Name: FUNCTION fn_dialog_group_create(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_group_create(injson json) IS 'CREATE GROUP DIALOG';


--
-- TOC entry 328 (class 1255 OID 179942)
-- Name: fn_dialog_leave(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_leave(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _user_to_remove int;
  _dialogid int;
  _dtype smallint;
  _admins json;
  _od json;
  _users JSON;
  _nw JSON;
BEGIN
	_userid = injson->>'userid';
    _dialogid = injson->>'id';
    _user_to_remove = _userid;


	IF _dialogid IS NULL 
    THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    IF _user_to_remove is null 
    THEN 
  	  PERFORM raiserror('user_to_remove is null');
    END IF;
    
    SELECT 
    	d.dialog_admins,
        d.dtype,
        d.users
    FROM framework.dialogs as d
    WHERE d.id = _dialogid
    INTO _admins, _dtype, _users; 

    IF _dtype = '1'
    THEN 
        RETURN;
    END IF;
    
    IF _user_to_remove not in (
    	SELECT
        	value::varchar::int
    	FROM json_array_elements_text(_users)
    )
    THEN
    	PERFORM raiserror('User not in dialog');
    END IF;
    
    
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _od;
    
    UPDATE framework.dialogs
    SET    
		users = array_to_json(ARRAY(
        	SELECT
                value::varchar::int
            FROM json_array_elements_text(users)
            WHERE value::varchar::int <> _user_to_remove
        ))
    WHERE id = _dialogid;


    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, oldata, newdata,
      userid
    ) VALUES (
      'framework.dialogs', _dialogid::VARCHAR,
      '2',_od,_nw,
      _userid
     );
END;
$$;


ALTER FUNCTION framework.fn_dialog_leave(injson json) OWNER TO postgres;

--
-- TOC entry 3107 (class 0 OID 0)
-- Dependencies: 328
-- Name: FUNCTION fn_dialog_leave(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_leave(injson json) IS 'REMOVE USER FROM DIALOG';


--
-- TOC entry 329 (class 1255 OID 179943)
-- Name: fn_dialog_message_bydialog(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_message_bydialog(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE 	
	_dialog_id int;	
    _userid int;
    _users json;
    _foundcount bigint;
    _pagesize smallint;
    _offset int;
    
BEGIN
	_dialog_id = injson->>'dialogid';
    _userid = injson->>'userid';
    _pagesize = injson->>'pagesize';
    
    
    IF _userid is NULL 
    THEN
    	PERFORM raiserror('userid is null');
    END IF;
    
    IF _dialog_id is NULL 
    THEN
    	PERFORM raiserror('dialogid is null');
	END IF;
    
    SELECT
    	d.users
    FROM framework.dialogs as d
    WHERE d.id = _dialog_id
    INTO _users;
    
    IF _users is null 
    THEN
    	PERFORM raiserror('Dialog is not found');
    END IF;
    
    IF (
    	SELECT
        	count(*)
        FROM json_array_elements_text(_users)
        WHERE value::varchar::int = _userid
    ) = 0 
    THEN
    	PERFORM raiserror('ACCESS DENIED');
    END IF;
    
    SELECT
      count(id)
    FROM framework.dialog_messages 
    WHERE dialog_id = _dialog_id 
    INTO _foundcount;
    
    _pagesize = coalesce(_pagesize,'30');
    _offset = _foundcount - _pagesize;
    
    IF _offset < 0 THEN 
    	_offset = 0;
  	END IF;
    
    
    SELECT
    	array_to_json(array_agg(row_to_json(z)))
    FROM (
      SELECT
          dm.id,
          dm.dialog_id,
          dm.files,
          dm.images,
          dm.isread,
          dm.created,
          dm.isupdated,
          dm.reply_to,
          dm.forwarded_from,
          dm.message_text,
          concat(u.fam,' ',u.im,' ',u.ot) as userfio,
		  u.photo,
          u.login,
          o.orgname,
          (
            CASE
            WHEN dm.userid = _userid
            THEN true
            ELSE false
            END
          ) as ismine
      FROM framework.dialog_messages as dm
          JOIN framework.users as u on u.id = dm.userid
          LEFT JOIN framework.orgs as o on o.id = u.orgid
      WHERE dm.dialog_id = _dialog_id
	  ORDER BY dm.created --desc
      LIMIT _pagesize OFFSET _offset
	) as z
    INTO outjson;

	outjson = COALESCE(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_dialog_message_bydialog(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3108 (class 0 OID 0)
-- Dependencies: 329
-- Name: FUNCTION fn_dialog_message_bydialog(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_message_bydialog(injson json, OUT outjson json) IS 'MESSAGES BY DIALOG';


--
-- TOC entry 330 (class 1255 OID 179944)
-- Name: fn_dialog_message_delete(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_message_delete(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _id int;
  _dialog_id int;
  _message_user int;
  _created TIMESTAMP;
  _od json;
BEGIN
  _id = injson->>'id';	
  _userid = injson->>'userid';

  -- CHECKS
  IF _id is NULL 
  THEN
  	PERFORM raiserror('id is null');
  END IF;
  
  IF _userid is NULL 
  THEN
  	PERFORM raiserror('Userid is null');
  END IF;
  
  SELECT
    dm.created,	
    dm.userid,
    dm.dialog_id
  FROM framework.dialog_messages as dm
  WHERE dm.id = _id
  INTO _created, _message_user, _dialog_id;
  
  IF _message_user <> _userid 
  THEN
  	PERFORM raiserror('Access Denied');
  END IF;
  
  IF NOT (
     EXTRACT(year from now()-_created) = 0 AND 
  	 EXTRACT(month from now()-_created) = 0 AND
     EXTRACT(day from now()-_created) = 0 AND
     EXTRACT(hour from now()-_created) < 24
  ) 
  THEN
  	PERFORM raiserror('Passed more than 24 hours');
  END IF;
  
  -- DELETE MESSAGE
  SELECT
  	row_to_json(d)
  FROM (
  	SELECT
  		*
 	FROM framework.dialog_messages 
 	WHERE id = _id
  ) as d
  INTO _od;
  
  DELETE FROM framework.dialog_messages 
  WHERE id = _id;
  
  -- LOG
  INSERT INTO framework.logtable (
    tablename, tableid, opertype,
    oldata, newdata, userid
  ) VALUES (
    'framework.dialog_messages', _id::varchar, '2',
    _od, '[]'::json, _userid	
  );
  
  
END;
$$;


ALTER FUNCTION framework.fn_dialog_message_delete(injson json) OWNER TO postgres;

--
-- TOC entry 3109 (class 0 OID 0)
-- Dependencies: 330
-- Name: FUNCTION fn_dialog_message_delete(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_message_delete(injson json) IS 'EDIR MESSAGE';


--
-- TOC entry 331 (class 1255 OID 179945)
-- Name: fn_dialog_message_edit(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_message_edit(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _message_text varchar;
  _files json;
  _images json;
  _id int;
  _dialog_id int;
  _message_user int;
  _created TIMESTAMP;
  _od json;
  _nw json;
BEGIN
  _id = injson->>'id';	
  _userid = injson->>'userid';
  _message_text = injson->>'message_text';
  _files = injson->>'files';
  _images = injson->>'images';
  
  -- CHECKS
  IF _id is NULL 
  THEN
  	PERFORM raiserror('id is null');
  END IF;
  
  IF _userid is NULL 
  THEN
  	PERFORM raiserror('Userid is null');
  END IF;
  
  SELECT
    dm.created,	
    dm.userid,
    dm.dialog_id
  FROM framework.dialog_messages as dm
  WHERE dm.id = _id
  INTO _created, _message_user, _dialog_id;
  
  IF _message_user <> _userid 
  THEN
  	PERFORM raiserror('Access Denied');
  END IF;
  
  IF NOT (
     EXTRACT(year from now()-_created) = 0 AND 
  	 EXTRACT(month from now()-_created) = 0 AND
     EXTRACT(day from now()-_created) = 0 AND
     EXTRACT(hour from now()-_created) < 24
  ) 
  THEN
  	PERFORM raiserror('Passed more than 24 hours');
  END IF;
  
  IF COALESCE(_message_text,'') = '' 
  THEN
  	PERFORM raiserror('Message is empty');
  END IF;

  -- EDIT MESSAGE
  SELECT
  	row_to_json(d)
  FROM (
  	SELECT
  		*
 	FROM framework.dialog_messages 
 	WHERE id = _id
  ) as d
  INTO _od;
  
  UPDATE framework.dialog_messages 
  SET 
  	message_text = _message_text,
    isupdated = true,
    files = COALESCE(_files,files),
    images = COALESCE(_images,images)
  WHERE id = _id;
  
  SELECT
  	row_to_json(d)
  FROM (
  	SELECT
  		*
 	FROM framework.dialog_messages 
 	WHERE id = _id
  ) as d
  INTO _nw;
  
  -- LOG
  INSERT INTO framework.logtable (
    tablename, tableid, opertype,
    oldata, newdata, userid
  ) VALUES (
    'framework.dialog_messages', _id::varchar, '2',
    _od, _nw, _userid	
  );
  
  UPDATE framework.dialog_messages
  SET 
  	isread = true, 
    user_reads = (
      CASE WHEN (
          SELECT
              count(*)
          FROM json_array_elements_text(user_reads)
          WHERE value::varchar::int = _userid
      ) = 0
      THEN (
          array_to_json(ARRAY(
              SELECT
                  _userid	
          ))::jsonb||user_reads::jsonb
      )::json
      ELSE
      	user_reads
      END
    )
  WHERE dialog_id = _dialog_id and id <> _id;
  
END;
$$;


ALTER FUNCTION framework.fn_dialog_message_edit(injson json) OWNER TO postgres;

--
-- TOC entry 3110 (class 0 OID 0)
-- Dependencies: 331
-- Name: FUNCTION fn_dialog_message_edit(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_message_edit(injson json) IS 'EDIR MESSAGE';


--
-- TOC entry 332 (class 1255 OID 179946)
-- Name: fn_dialog_message_send(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_message_send(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _dialogid int;
  _message_text varchar;
  _reply_to int;
  _forwarded_from int;
  _files json;
  _images json;
  _id int;
  _users JSON;
BEGIN
  _userid = injson->>'userid';
  _dialogid = injson->>'dialogid';
  _message_text = injson->>'message_text';
  _forwarded_from = injson->>'forwarded_from';
  _reply_to = injson->>'reply_to';
  _files = injson->>'value';
  _files = COALESCE(_files,'[]');
  
  _images = (
  	SELECT
 	 array_to_json(
       ARRAY(
        SELECT
            *
        FROM json_array_elements(_files)
        WHERE lower(value->>'content_type') like 'image%'
       )
     )
  );
  
  _files = (
  	SELECT
 	 array_to_json(
       ARRAY(
        SELECT
            *
        FROM json_array_elements(_files)
        WHERE lower(value->>'content_type') not like 'image%'
       )
     )
  );
  
  -- CHECKS
  IF _userid is NULL 
  THEN
  	PERFORM raiserror('Userid is null');
  END IF;
  
  IF _dialogid is NULL 
  THEN
  	PERFORM raiserror('Dialogid is null');
  END IF;
  _message_text = COALESCE(_message_text,'');
  IF _message_text = '' AND (
  	SELECT
    	count(*)
    FROM json_array_elements(_files)
  ) = 0 AND (
  	SELECT
    	count(*)
    FROM json_array_elements(_images)
  ) = 0
  THEN
  	PERFORM raiserror('Message is empty');
  END IF;
  
  -- GET DIALOGS USERS FOR NOTIFICATIONS
  SELECT 
  	d.users
  FROM framework.dialogs as d
  WHERE d.id = _dialogid
  INTO _users;
  
  IF _users is null 
  THEN
  	PERFORM raiserror('Dialog is not found');
  END IF;
  
  IF (
    	SELECT
        	count(*)
        FROM json_array_elements_text(_users)
        WHERE value::varchar::int = _userid
   ) = 0 
  THEN
   	PERFORM raiserror('ACCESS DENIED');
  END IF;
  
  
  -- ADD MESSAGE
  _id = nextval('framework.dialog_messages_id_seq'::regclass);
  
  INSERT INTO framework.dialog_messages (
    id, userid, message_text, reply_to, 
    forwarded_from, dialog_id, files, images
  ) VALUES (
    _id, _userid, _message_text, _reply_to,
    _forwarded_from, _dialogid, _files, _images
  );
  
  -- ADD NOTIFICATIONS
  INSERT INTO framework.dialog_notifications (
    dialog_id, sender_userid, userid, message_text, message_id
  ) 
  SELECT
  	_dialogid, _userid, value::varchar::int, _message_text, _id
  FROM json_array_elements_text(_users);
  --WHERE value::varchar::int <> _userid;
  
  UPDATE framework.dialogs
  SET last_message_date = now()
  WHERE id = _dialogid;
  
  UPDATE framework.dialog_messages
  SET 
  	isread = true, 
    user_reads = (
      CASE WHEN (
          SELECT
              count(*)
          FROM json_array_elements_text(user_reads)
          WHERE value::varchar::int = _userid
      ) = 0
      THEN (
          array_to_json(ARRAY(
              SELECT
                  _userid	
          ))::jsonb||user_reads::jsonb
      )::json
      ELSE
      	user_reads
      END
    )
  WHERE dialog_id = _dialogid and id<>_id;
  
END;
$$;


ALTER FUNCTION framework.fn_dialog_message_send(injson json) OWNER TO postgres;

--
-- TOC entry 3111 (class 0 OID 0)
-- Dependencies: 332
-- Name: FUNCTION fn_dialog_message_send(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_message_send(injson json) IS 'SEND MESSAGE TO DIALOG';


--
-- TOC entry 325 (class 1255 OID 179947)
-- Name: fn_dialog_message_setread(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_message_setread(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id int;
  _userid int;
BEGIN
	_id = injson->>'id';
    _userid = injson->>'userid';
    
    IF _id is null 
    THEN
    	PERFORM raiserror('id is null');
    END IF;
        
    IF _userid is null 
    THEN
    	PERFORM raiserror('userid is null');
    END IF;
    
    
    
  UPDATE framework.dialog_messages
  SET 
    isread = true, 
    user_reads = (
      CASE WHEN (
          SELECT
              count(*)
          FROM json_array_elements_text(user_reads)
          WHERE value::varchar::int = _userid
      ) = 0
      THEN (
          array_to_json(ARRAY(
              SELECT
                  _userid	
          ))::jsonb||user_reads::jsonb
      )::json
      ELSE
      	user_reads
      END
    )
  WHERE id = _id;
END;
$$;


ALTER FUNCTION framework.fn_dialog_message_setread(injson json) OWNER TO postgres;

--
-- TOC entry 3112 (class 0 OID 0)
-- Dependencies: 325
-- Name: FUNCTION fn_dialog_message_setread(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_message_setread(injson json) IS 'SET MESSAGE READED';


--
-- TOC entry 334 (class 1255 OID 179948)
-- Name: fn_dialog_personal_create(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_personal_create(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _reciver_user_id int;
  _message_text varchar;
  _dialog_id int;
  _users JSON;
  _files json;
  _images json;
  _id int;
  _first_message json;
BEGIN
	
	_userid = injson->>'userid';
    _reciver_user_id = injson->>'reciver_user_id';
    _message_text = injson->>'message_text';
    _files = injson->>'files';
    _images = injson->>'images';
    
    -- CHECKS
    IF _userid is NULL 
    THEN
    	PERFORM raiserror('userid is null');
    END IF;
    
    IF _reciver_user_id is NULL 
    THEN
    	PERFORM raiserror('reciver_user is null');
    END IF;
    
    -- IF MESSAGE IS NOT EMPTY, CREATE FIRST MESSAGE
    IF _message_text is NOT NULL
    THEN
    	_first_message = json_build_object(
           'userid', _userid,
           'dialogid', _dialog_id,
           'files', _files,
           'images', _images,
           'message_text', _message_text
         ); 
    ELSE 
    	_first_message = '{}'::json;
    END IF; 
    
    -- USERS FOR PERSONAL DIALOG
    _users = array_to_json(ARRAY(
      SELECT
          _userid
      UNION 
      SELECT 
          _reciver_user_id
    ));
    
    -- ADD DIALOG
    _dialog_id = nextval('framework.dialogs_id_seq'::regclass);
	
    INSERT INTO framework.dialogs (
       id, users, userid, first_message
    ) VALUES (
       _dialog_id, _users ,_userid, _first_message
    );
	
    
END;
$$;


ALTER FUNCTION framework.fn_dialog_personal_create(injson json) OWNER TO postgres;

--
-- TOC entry 3113 (class 0 OID 0)
-- Dependencies: 334
-- Name: FUNCTION fn_dialog_personal_create(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_personal_create(injson json) IS 'CREATE PERSONAL DIALOG';


--
-- TOC entry 335 (class 1255 OID 179949)
-- Name: fn_dialog_removeadmin(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_removeadmin(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _admin_to_remove int;
  _dialogid int;
  _dtype smallint;
  _admins json;
  _od json;
  _users JSON;
  _nw JSON;
BEGIN
	_userid = injson->>'userid';
    _dialogid = injson->>'id';
    _admin_to_remove = injson->>'admin_to_remove';


	IF _dialogid IS NULL 
    THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    IF _admin_to_remove is null 
    THEN 
  	  PERFORM raiserror('admin_to_remove is null');
    END IF;
    
    SELECT 
    	d.dialog_admins,
        d.dtype,
        d.dialog_admins
    FROM framework.dialogs as d
    WHERE d.id = _dialogid
    INTO _admins, _dtype, _users; 

    IF _dtype = '1'
    THEN 
        RETURN;
    END IF;
    
    IF _admin_to_remove not in (
    	SELECT
        	value::varchar::int
    	FROM json_array_elements_text(_admins)
    )
    THEN
    	PERFORM raiserror('User is not admin');
    END IF;
    
    
    
    IF (
        SELECT
            count(*)
        FROM json_array_elements_text(_admins)
        WHERE value::varchar::int = _userid
    ) = 0
    THEN
        PERFORM raiserror('ACCESS DENIED');
    END IF;
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _od;
    
    UPDATE framework.dialogs
    SET    
		dialog_admins = array_to_json(ARRAY(
        	SELECT
                value::varchar::int
            FROM json_array_elements_text(_admins)
            WHERE value::varchar::int <> _admin_to_remove
        ))
    WHERE id = _dialogid;


    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, oldata, newdata,
      userid
    ) VALUES (
      'framework.dialogs', _dialogid::VARCHAR,
      '2',_od,_nw,
      _userid
     );
END;
$$;


ALTER FUNCTION framework.fn_dialog_removeadmin(injson json) OWNER TO postgres;

--
-- TOC entry 3114 (class 0 OID 0)
-- Dependencies: 335
-- Name: FUNCTION fn_dialog_removeadmin(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_removeadmin(injson json) IS 'REMOVE USER FROM ADMINS';


--
-- TOC entry 336 (class 1255 OID 179950)
-- Name: fn_dialog_removeuser(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialog_removeuser(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _user_to_remove int;
  _dialogid int;
  _dtype smallint;
  _admins json;
  _od json;
  _users JSON;
  _nw JSON;
BEGIN
	_userid = injson->>'userid';
    _dialogid = injson->>'id';
    _user_to_remove = injson->>'user_to_remove';


	IF _dialogid IS NULL 
    THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    IF _user_to_remove is null 
    THEN 
  	  PERFORM raiserror('user_to_remove is null');
    END IF;
    
    SELECT 
    	d.dialog_admins,
        d.dtype,
        d.users
    FROM framework.dialogs as d
    WHERE d.id = _dialogid
    INTO _admins, _dtype, _users; 

    IF _dtype = '1'
    THEN 
        RETURN;
    END IF;
    
    IF _user_to_remove not in (
    	SELECT
        	value::varchar::int
    	FROM json_array_elements_text(_users)
    )
    THEN
    	PERFORM raiserror('User not in dialog');
    END IF;
    
    
    
    IF (
        SELECT
            count(*)
        FROM json_array_elements_text(_admins)
        WHERE value::varchar::int = _userid
    ) = 0
    THEN
        PERFORM raiserror('ACCESS DENIED');
    END IF;
    
    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _od;
    
    UPDATE framework.dialogs
    SET    
		users = array_to_json(ARRAY(
        	SELECT
                value::varchar::int
            FROM json_array_elements_text(users)
            WHERE value::varchar::int <> _user_to_remove
        ))
    WHERE id = _dialogid;


    SELECT
        row_to_json(z)
    FROM (
         SELECT
                d.*
         FROM framework.dialogs as d
         WHERE d.id = _dialogid
    ) as z
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid,
      opertype, oldata, newdata,
      userid
    ) VALUES (
      'framework.dialogs', _dialogid::VARCHAR,
      '2',_od,_nw,
      _userid
     );
END;
$$;


ALTER FUNCTION framework.fn_dialog_removeuser(injson json) OWNER TO postgres;

--
-- TOC entry 3115 (class 0 OID 0)
-- Dependencies: 336
-- Name: FUNCTION fn_dialog_removeuser(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialog_removeuser(injson json) IS 'REMOVE USER FROM DIALOG';


--
-- TOC entry 337 (class 1255 OID 179951)
-- Name: fn_dialogs_byuser(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialogs_byuser(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
BEGIN
	_userid = injson->>'userid';
    
    IF _userid is null 
    THEN
    	PERFORM raiserror('userid is null');
    END IF;
    
    SELECT
    	array_to_json(array_agg(row_to_json(z)))
    FROM (
      SELECT 
          d.id, (
            CASE WHEN
              d.dtype = '1'
            THEN (
              SELECT
              	u.login
              FROM json_array_elements_text(d.users) as uu
              	JOIN framework.users as u on uu.value::varchar::int = u.id
              WHERE uu.value::varchar::int <> _userid
            )		
            ELSE
              d.title
            END
          ) as title, (
            CASE WHEN
              d.dtype = '1'
            THEN (
              SELECT
              	u.photo
              FROM json_array_elements_text(d.users) as uu
              	JOIN framework.users as u on uu.value::varchar::int = u.id
              WHERE uu.value::varchar::int <> _userid
            )		
            ELSE
              d.photo
            END
          ) as photo,
          d.created,
          d.last_message_date,
          (
          	SELECT 
            	row_to_json(f)
            FROM (
            	SELECT
                	m.message_text,
                    concat(u.fam,' ',u.im,' ',u.ot) as userfio,
                    u.login,
                    u.photo,
                    u.orgid,
                    o.orgname,
                    (
                      CASE
                      WHEN m.userid = _userid
                      THEN true
                      ELSE false
                      END
                    ) as ismine
                FROM framework.dialog_messages as m
                	LEFT JOIN framework.users as u on u.id = m.userid
                    LEFT JOIN framework.orgs as o on o.id = u.orgid
                WHERE m.dialog_id = d.id
                ORDER BY m.created DESC LIMIT 1
            ) as f
          ) as last_message,
          d.dtype as dialog_type,
          dt.tname as dialog_type_name,
          (
          	SELECT
            	array_to_json(array_agg(row_to_json(zz)))
           	FROM (
              SELECT 
              	uuu.id,
              	concat(uuu.fam,' ',uuu.im,' ',uuu.ot) as userfio,
                uuu.login,
                uuu.photo,
                uuu.orgid,
                o.orgname, (
                  CASE WHEN da.value::varchar is null
                  THEN false
                  ELSE true
                  END
                )  as isadmin
              FROM json_array_elements_text(d.users) as uu
              	JOIN framework.users as uuu on uuu.id = uu.value::varchar::int 
                LEFT JOIN framework.orgs as o on o.id = uuu.orgid
                LEFT JOIN json_array_elements_text(d.dialog_admins) as da on da.value::varchar = uu.value::varchar
              --WHERE uu.value::varchar::int <> _userid
            ) as zz
          ) as users, (
          	CASE WHEN (
                SELECT
                	m.userid
                FROM framework.dialog_messages as m
                WHERE m.dialog_id = d.id
                ORDER BY m.created DESC LIMIT 1
          	) <> _userid
          	THEN
         		0
            ELSE (
            	SELECT
                	count(m.id)
                FROM framework.dialog_messages as m
                WHERE m.dialog_id = d.id and (
                	SELECT 
                    	count(*)
                    FROM json_array_elements(m.user_reads)
                	WHERE value::varchar::int = _userid
                ) = 0
            )
            END
          ) as unreaded,
          (
          	SELECT
            	row_to_json(zd)
            FROM (
            	SELECT
                	u.id,
                    u.login,
                    u.photo
                FROM framework.users as u
                WHERE u.id = d.creator
            ) as zd
          ) as creator,
          d.dialog_admins, (
            CASE WHEN (
              SELECT
                  count(*)
              FROM json_array_elements_text(d.dialog_admins)
              WHERE value::varchar::int = _userid
            ) > 0 THEN true
            ELSE false END
          ) as isadmin
      FROM framework.dialogs as d
      	JOIN framework.dialog_types as dt on dt.id = d.dtype
      WHERE (
          SELECT count(value) 
          FROM json_array_elements_text(d.users) 
          WHERE value::varchar::int = _userid
      ) > 0
      ORDER BY d.last_message_date desc
    ) as z
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_dialogs_byuser(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3116 (class 0 OID 0)
-- Dependencies: 337
-- Name: FUNCTION fn_dialogs_byuser(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialogs_byuser(injson json, OUT outjson json) IS 'USER DIALOGS';


--
-- TOC entry 338 (class 1255 OID 179952)
-- Name: fn_dialogs_chats_ws(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialogs_chats_ws(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
BEGIN

  _userid = injson->>'userid';
  
  SELECT
     array_to_json(array_agg(row_to_json(z)))
  FROM (
       SELECT  
	      n.id as notificationid,
          d.id, (
            CASE WHEN
              d.dtype = '1'
            THEN (
              SELECT
                  u.login
              FROM json_array_elements_text(d.users) as uu
                  JOIN framework.users as u on uu.value::varchar::int = u.id
              WHERE uu.value::varchar::int <> _userid
            )        
            ELSE
              d.title
            END
          ) as title, (
            CASE WHEN
              d.dtype = '1'
            THEN (
              SELECT
                  u.photo
              FROM json_array_elements_text(d.users) as uu
                  JOIN framework.users as u on uu.value::varchar::int = u.id
              WHERE uu.value::varchar::int <> _userid
            )        
            ELSE
              d.photo
            END
          ) as photo,
          d.created,
          d.last_message_date, (
            SELECT 
                row_to_json(f)
            FROM (
                SELECT
                    m.message_text,
                    concat(u.fam,' ',u.im,' ',u.ot) as userfio,
                    u.login,
                    u.photo,
                    u.orgid,
                    o.orgname
                FROM framework.dialog_messages as m
                    LEFT JOIN framework.users as u on u.id = m.userid
                    LEFT JOIN framework.orgs as o on o.id = u.orgid
                WHERE m.dialog_id = d.id
                ORDER BY m.created DESC LIMIT 1
            ) as f
          ) as last_message,
          d.dtype as dialog_type,
          dt.tname as dialog_type_name,
          (
              SELECT
                array_to_json(array_agg(row_to_json(zz)))
               FROM (
              SELECT 
              	uuu.id,
                  concat(uuu.fam,' ',uuu.im,' ',uuu.ot) as userfio,
                uuu.login,
                uuu.photo,
                uuu.orgid,
                o.orgname, (
                  CASE WHEN da.value::varchar is null
                  THEN false
                  ELSE true
                  END
                )  as isadmin
              FROM json_array_elements_text(d.users) as uu
                JOIN framework.users as uuu on uuu.id = uu.value::varchar::int 
                LEFT JOIN framework.orgs as o on o.id = uuu.orgid
                LEFT JOIN json_array_elements_text(d.dialog_admins) as da on da.value::varchar = uu.value::varchar
              --WHERE uu.value::varchar::int <> _userid
            ) as zz
          ) as users, (
              CASE WHEN (
                SELECT
                    m.userid
                FROM framework.dialog_messages as m
                WHERE m.dialog_id = d.id
                ORDER BY m.created DESC LIMIT 1
              ) <> _userid
              THEN
                 0
            ELSE (
                SELECT
                    count(m.id)
                FROM framework.dialog_messages as m
                WHERE m.dialog_id = d.id and (
                    SELECT 
                        count(*)
                    FROM json_array_elements(m.user_reads)
                	WHERE value::varchar::int = _userid
                ) = 0
            )
            END
          ) as unreaded,
          (
          	SELECT
            	row_to_json(zd)
            FROM (
            	SELECT
                	u.id,
                    u.login,
                    u.photo
                FROM framework.users as u
                WHERE u.id = d.creator
            ) as zd
          ) as creator,
          d.dialog_admins, (
            CASE WHEN (
              SELECT
                  count(*)
              FROM json_array_elements_text(d.dialog_admins)
              WHERE value::varchar::int = _userid
            ) > 0 THEN true
            ELSE false END
          ) as isadmin
	   FROM framework.dialog_notifications as n
	        JOIN framework.dialogs as d on d.id = n.dialog_id
			JOIN framework.dialog_types as dt on dt.id = d.dtype
	   WHERE n.userid = _userid and not n.issend
  ) as z
  INTO outjson;

END;
$$;


ALTER FUNCTION framework.fn_dialogs_chats_ws(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3117 (class 0 OID 0)
-- Dependencies: 338
-- Name: FUNCTION fn_dialogs_chats_ws(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialogs_chats_ws(injson json, OUT outjson json) IS 'DIALOGS NOTIFICATIONS FOR WS';


--
-- TOC entry 339 (class 1255 OID 179953)
-- Name: fn_dialogs_chatsmessages_ws(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialogs_chatsmessages_ws(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    _userid int;
    _dialog_id int;
    _foundcount bigint;
    _pagesize int;
    _offset int;
BEGIN
    _userid = injson->>'userid';
    _dialog_id = injson->>'dialogid';
    _pagesize = injson->>'pagesize';

    SELECT
      count(id)
    FROM framework.dialog_messages 
    WHERE dialog_id = _dialog_id 
    INTO _foundcount;
    
    _pagesize = coalesce(_pagesize,'30');
    _offset = _foundcount - _pagesize;
    
    IF _offset < 0 THEN 
    	_offset = 0;
  	END IF;
    
    
    SELECT
    	array_to_json(array_agg(row_to_json(z)))
    FROM (
      SELECT
          dm.id,
          dm.dialog_id,
          dm.files,
          dm.images,
          dm.isread,
          dm.created,
          dm.isupdated,
          dm.reply_to,
          dm.forwarded_from,
          dm.message_text,
          concat(u.fam,' ',u.im,' ',u.ot) as userfio,
		  u.photo,
          u.login,
          o.orgname,
          coalesce(n.id,0) as notificationid,
          (
            CASE
            WHEN dm.userid = _userid
            THEN true
            ELSE false
            END
          ) as ismine
      FROM framework.dialog_messages as dm
          JOIN framework.users as u on u.id = dm.userid
          LEFT JOIN framework.orgs as o on o.id = u.orgid
          LEFT JOIN framework.dialog_notifications as n on n.dialog_id = dm.dialog_id
          	AND n.message_id = dm.id and n.userid = _userid
      WHERE dm.dialog_id = _dialog_id and 
       (
        	SELECT 
            	count(dn.id)
            FROM framework.dialog_notifications as dn
            WHERE not dn.issend and dn.dialog_id = _dialog_id
            	  and dn.userid = _userid 
        ) > 0
	  ORDER BY dm.created
      LIMIT _pagesize OFFSET _offset
	) as z
    INTO outjson;
    outjson = coalesce(outjson,'[]');
    

END;
$$;


ALTER FUNCTION framework.fn_dialogs_chatsmessages_ws(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3118 (class 0 OID 0)
-- Dependencies: 339
-- Name: FUNCTION fn_dialogs_chatsmessages_ws(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialogs_chatsmessages_ws(injson json, OUT outjson json) IS 'DIALOGS NOTIFICATIONS FOR WS';


--
-- TOC entry 340 (class 1255 OID 179954)
-- Name: fn_dialogs_notif_setsended(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialogs_notif_setsended(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _id int;
BEGIN
  _userid = injson->>'userid';
  _id = injson->>'id';
  
  IF _id is NULL THEN
     PERFORM raiserror('id is null');
  END IF;
  
  UPDATE framework.dialog_notifications
  SET
     issend = TRUE
  WHERE id = _id;
END;
$$;


ALTER FUNCTION framework.fn_dialogs_notif_setsended(injson json) OWNER TO postgres;

--
-- TOC entry 3119 (class 0 OID 0)
-- Dependencies: 340
-- Name: FUNCTION fn_dialogs_notif_setsended(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialogs_notif_setsended(injson json) IS 'SET DIALOGS NOTIFICATION STATUS SENDED';


--
-- TOC entry 341 (class 1255 OID 179955)
-- Name: fn_dialogs_usersearch(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_dialogs_usersearch(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _substr varchar(150);
  _userid int;
BEGIN

	_substr = injson->>'substr';
    _userid = injson->>'userid';
    
    _substr = coalesce(_substr,'1');
    _substr = replace(_substr,'@','');
    _substr = lower(concat(_substr,'%'));
    
    SELECT
    	array_to_json(array_agg(row_to_json(z)))
    FROM (
    	SELECT
        	u.id,
        	u.fam,
            u.im,
            u.ot,
            u.login,
            u.orgid,
            o.orgname,
            u.photo
        FROM framework.users as u
        	LEFT JOIN framework.orgs as o on o.id = u.orgid
        WHERE lower(u.login) like _substr and u.isactive and 
        	  u.id <> _userid
    ) as z
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_dialogs_usersearch(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3120 (class 0 OID 0)
-- Dependencies: 341
-- Name: FUNCTION fn_dialogs_usersearch(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_dialogs_usersearch(injson json, OUT outjson json) IS 'SEARCH USERS';


--
-- TOC entry 342 (class 1255 OID 179956)
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
	-- CALL API METHOD'S FUNCTION

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
        	PERFORM raiserror('m401err');
        END IF;
        
        IF (SELECT count(*)  
            FROM json_array_elements_text(mroles) as a1
           		JOIN json_array_elements_text(_roles) as ur 
                	ON a1.value::varchar(15)::smallint = ur.value::varchar(15)::smallint
            ) = 0 
        THEN
        	PERFORM raiserror('m403err');
        END IF;        
    END IF;   
    
    IF primaryauthorization = 1 and _userid is null THEN
    	perform raiserror('m401err');
    END IF; 
    
    SELECT 
    	injson::jsonb || 
    	(SELECT 
        	row_to_json(d) 
         FROM (
         	SELECT _userid as userid
         ) as d)::jsonb
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
-- TOC entry 3121 (class 0 OID 0)
-- Dependencies: 342
-- Name: FUNCTION fn_fapi(injson json, apititle character varying, apitype smallint, sessid character, primaryauthorization smallint, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_fapi(injson json, apititle character varying, apitype smallint, sessid character, primaryauthorization smallint, OUT outjson json) IS 'CALL API METHOD''S FUNCTION';


--
-- TOC entry 343 (class 1255 OID 179957)
-- Name: fn_filter_add_untitle(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_filter_add_untitle(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE 
  _viewid int;
  _id int;
BEGIN
  -- add untitle filter in filters table
  
  _viewid = injson->>'viewid';

  IF _viewid is NULL THEN
  	PERFORM raiserror('viewid is null');
  END IF;
    
    _id = nextval('framework.filters_id_seq'::regclass);
    
    INSERT INTO framework.filters (
      id, column_order,
	  viewid, title, type
    ) VALUES (
      _id, COALESCE((
      	SELECT max(column_order) 
       	FROM framework.filters 
        WHERE viewid = _viewid
      ),0) + 1,
      _viewid, concat('untitled_',_id::varchar), 'substr'
    );
END;
$$;


ALTER FUNCTION framework.fn_filter_add_untitle(injson json) OWNER TO postgres;

--
-- TOC entry 3122 (class 0 OID 0)
-- Dependencies: 343
-- Name: FUNCTION fn_filter_add_untitle(injson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_filter_add_untitle(injson json) IS '-- add untitle filter in filters table';


--
-- TOC entry 344 (class 1255 OID 179958)
-- Name: fn_formparams_V004(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION "fn_formparams_V004"(injson json, OUT tables json, OUT filtertypes json, OUT viewtypes json, OUT columntypes json) RETURNS record
    LANGUAGE plpgsql
    AS $$
--DECLARE

BEGIN
  -- 	
/*
	OLD V004
    NEED TO REMOVE AFTER TESTS

*/
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
  	c.typename as value, 
  	c.typename as label,
    c.viewtypes 
  FROM framework.columntypes as c
    ) as d
    INTO columntypes;
END;
$$;


ALTER FUNCTION framework."fn_formparams_V004"(injson json, OUT tables json, OUT filtertypes json, OUT viewtypes json, OUT columntypes json) OWNER TO postgres;

--
-- TOC entry 345 (class 1255 OID 179959)
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
  k int;
BEGIN
	
  _config = injson->>'config';
  _inputs = injson->>'inputs';
  _val = injson->> 'val';
  _userid = injson->>'userid';
  _id = injson->>'id';
  _ismulti = injson->>'ismulti';
  _relation = coalesce(_config->>'multiselecttable',_config->>'relation');
  _relationcolums = coalesce(coalesce(_config->>'multicolums',_config->>'relationcolums'),'[]');
  
  
  _ismulti = coalesce(_ismulti,false);
  IF (_config->>'type') like 'multi%' THEN
  	_ismulti = true;
  END IF; 
  
  
  IF _relation is null or _relationcolums is null or (SELECT count(*) 
  													  FROM json_array_elements_text(_relationcolums)) = 0 
  THEN
  	PERFORM raiserror('Something wrong here. Please check the config');	
  END IF;  

  
  col1 = (_relationcolums->0)::json->>'value';
 
   IF (SELECT count(*)
   FROM information_schema.columns as t
   WHERE concat(t.table_schema,'.',t.table_name) = _relation and 
   		 t.column_name = col1) = 0 
   THEN
         PERFORM raiserror('error in config can not find table or col');
   END IF;      
 
  IF (SELECT count(*) FROM json_array_elements_text(_relationcolums)) = 1
  	and _config->>'type' not like '%typehead'
  THEN 		
        squery = concat(squery,' SELECT "', col1, 
        	'" as value, "',col1, '" as label FROM ', 
            _relation);  
            
  ELSE
        IF (SELECT count(*) FROM json_array_elements_text(_relationcolums)) > 1 THEN
          k = 1;
        ELSE
        	k = 0; 
        END IF;
        
		col2 = (_relationcolums->k)::json->>'value';

        IF (SELECT count(*)
        FROM information_schema.columns as t
        WHERE concat(t.table_schema,'.',t.table_name) = _relation and 
               t.column_name = col2) = 0 THEN
               PERFORM raiserror('error in config can not find table or col2');
        END IF; 

		squery = concat(
        	squery,
        	' SELECT "' , 
            col1 , 
            '" as value, concat( "', col2,'"'
        );

        k = 2;
        WHILE k < (SELECT count(*) FROM json_array_elements_text(_relationcolums))
        LOOP
        	squery = concat(squery,','' '',"',(_relationcolums->k)::json->>'value','"');
        	k = k + 1;
        END LOOP;

		squery = concat(squery,') ');
   
		squery = concat(squery, ' as label FROM ', _relation);
        
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

		IF _val is not null 
        THEN
        	IF not _ismulti 
            THEN
              _val = concat('%',upper(_val),'%');
              squery = concat(
              	squery,' WHERE (upper("' , 
                col2 , '"::varchar) like $1 or upper("' , 
                col1 , '"::varchar) like $1'); 
              FOR pv in (SELECT * FROM json_array_elements_text(_relationcolums))
              LOOP
                  squery = concat(squery, ' or upper(' , (pv->>'value')::json->>'value' , '::varchar) like $1 ');
              END LOOP;   
            ELSE
            	IF _val not like '[%]' THEN
            	_val = json_build_array(_val)::varchar;
                END IF;

            	squery = concat(
                	squery, 
                    ' WHERE  (
                	(select count(value) 
                     from json_array_elements_text($1::json)
                     where upper("' ,col2 , '"::varchar) like 
                     	concat(''%%'', upper(value::varchar),''%%'')
                     ) > 0 ' 
                );
                FOR pv in (SELECT * FROM json_array_elements_text(_relationcolums))
                LOOP
                    squery = concat(
                      squery, 
                      ' or upper(' , 
                      pv->>'value' , 
                      '::varchar) like 
                      (select 
                      	 upper(value::varchar) 
                       from json_array_elements_text($1)) '
                    );
                END LOOP;                           
            END IF;
            squery = concat(squery, ') '); 
			IF _id is not null THEN
				squery = concat(squery,' and "' , col1 , '" = ''' , replace(_id::varchar ,'''',''''''), '''');
            END IF;    
		ELSE
        	IF not _ismulti THEN
              IF _id is not null THEN
                  squery = concat(squery,' WHERE "', col1 , '" = ''' , replace(_id::varchar ,'''','''''') , ''' '); 
                  --perform raiserror(squery);
              END IF;   
            ELSE
               IF _id is not null THEN
                  squery = concat(squery,' WHERE "', col1 , '"::varchar in (select value::varchar from json_array_elements_text(''' , replace(_id::varchar ,'''','''''') , ''')) '); 
                  --perform raiserror(squery);
              END IF;             
            END IF;   	
        END IF;        
  END IF;	
  select_condition = _config->>'select_condition';
  IF _inputs is not null 
  	and select_condition is not null 
  THEN
    IF squery not like '%WHERE%' THEN
    	squery = concat(squery,' WHERE ');
    ELSE
    	squery = concat(squery,' and ');
    END IF;    

    
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
	
          squery = concat(
          	squery, ' "', col1,'"', 
            _oper , '''' , 
            operval, ''' and'
          );
        END IF;   
        IF _oper in ('is null','is not null') THEN
          squery = concat(
          	squery, ' "', col1,'" ', 
            _oper , ' and'
          );	
        END IF;    
        IF _oper = 'like' THEN
            squery = concat(
            	squery, ' upper("', col1,'") ',  
                _oper , ' upper(''%%' , 
                operval, '%%'') and'
            );
        END IF;       
        IF _oper in ('in','not in') THEN
            squery = concat(
            	squery, ' "', col1,'" ',  
                _oper , ' (', 
                (SELECT 
                	string_agg(
                    	concat('''',o.name::varchar,''''), 
                        ', '
                    )
                 FROM json_array_elements(concat('[',operval,']')::json
                 ) as o), ') and'
            );              
        END IF;  
            
    END LOOP;
    squery = substring(squery,1,length(squery)-4); 
  END IF;
  

  squery = concat(
  	'SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ',
  	squery, ' LIMIT 300 ) as d');
  --  perform raiserror(squery);

  EXECUTE format(squery) USING _val INTO outjson;
  outjson = coalesce(outjson,'[]');
  
END;
$_$;


ALTER FUNCTION framework.fn_formselect(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 346 (class 1255 OID 179961)
-- Name: fn_functions_getall_spapi(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_functions_getall_spapi(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
/* ALL FUNCTIONS FOR SP API*/
DECLARE 
	_conf JSON;
    _key varchar(100);
    _val varchar(150);
BEGIN
   _conf = (injson->'config');
   
   SELECT
   	VALUE->>'key'
   FROM json_array_elements(_conf)
   WHERE (value->>'col') = 'procedurename' 
   INTO _key;
   
   _val = (injson->'data')->>_key;
   
   _val = coalesce(_val,'%');
   

	
   SELECT
   		array_to_json(array_agg(row_to_json(d)))
   FROM (
      SELECT 
        format('%I.%I', ns.nspname, p.proname) as label,
        format('%I.%I', ns.nspname, p.proname) as value
      FROM pg_proc p 
      INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
      WHERE ns.nspname not in ('pg_catalog','information_schema') --and
      	--format('%I.%I', ns.nspname, p.proname) like _val
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_functions_getall_spapi(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3123 (class 0 OID 0)
-- Dependencies: 346
-- Name: FUNCTION fn_functions_getall_spapi(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_functions_getall_spapi(injson json, OUT outjson json) IS 'ALL FUNCTIONS FOR SP API';


--
-- TOC entry 347 (class 1255 OID 179962)
-- Name: fn_getacttypes(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getacttypes(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_viewtype VARCHAR(30);
BEGIN
	_viewtype = injson->>'viewtype';	
    
    /*for old versions correct work*/
	_viewtype = coalesce(_viewtype,'table');
    
	SELECT 
      array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT 
    	a.actname as value, 
        a.actname as label 
    FROM framework.acttypes as a
    WHERE (SELECT count(value)
           FROM json_array_elements_text(a.viewtypes)
           WHERE value::varchar = _viewtype) > 0
    ) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_getacttypes(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 348 (class 1255 OID 179963)
-- Name: fn_getfunctions(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getfunctions(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- functions for config's column 
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM (
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
-- TOC entry 3124 (class 0 OID 0)
-- Dependencies: 348
-- Name: FUNCTION fn_getfunctions(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_getfunctions(injson json, OUT outjson json) IS 'functions for config''s column ';


--
-- TOC entry 349 (class 1255 OID 179964)
-- Name: fn_getselect(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getselect(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _filterid int;
  _tabname varchar(350);
  _tabcolums varchar(1500);
  _squery varchar(1800);
BEGIN
	_filterid = injson->>'id';
    
    
    SELECT
    	coalesce(c.relation, c.multiselecttable) as  tabname,
    	COALESCE(
        	c.relationcolums ,	
            c.multicolums)->>0 as tabcolums
    FROM framework.filters as f
    	JOIN framework.config as c on c.id = f.val_desc
        	and f.viewid = f.viewid
    WHERE f.id = _filterid
    INTO _tabname, _tabcolums;
    
	/*_tabname = injson->>'tabname';
    _tabcolums = injson->>'tabcolums';*/
    
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
-- TOC entry 350 (class 1255 OID 179965)
-- Name: fn_gettables_sel(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_gettables_sel(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT 
      concat(TABLE_SCHEMA,'.',TABLE_NAME) as value,
      concat(TABLE_SCHEMA,'.',TABLE_NAME) as label, *
  FROM INFORMATION_SCHEMA.TABLES
  ORDER BY TABLE_SCHEMA, TABLE_NAME) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_gettables_sel(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 351 (class 1255 OID 179966)
-- Name: fn_getusersettings(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_getusersettings(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	_userid int;
BEGIN
	_userid = injson->>'userid';
    
    SELECT 
    	u.usersettings
    FROM framework.users as u
    WHERE u.id = _userid
    INTO outjson;

	outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_getusersettings(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 352 (class 1255 OID 179967)
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
-- TOC entry 353 (class 1255 OID 179968)
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
-- TOC entry 354 (class 1255 OID 179969)
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
-- TOC entry 355 (class 1255 OID 179970)
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
-- TOC entry 356 (class 1255 OID 179971)
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
-- TOC entry 357 (class 1255 OID 179972)
-- Name: fn_menu_recurs(json, integer, integer); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_menu_recurs(_roles json, _parentid integer, menu_id integer, OUT outjson json) RETURNS json
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
        framework.fn_menu_recurs(_roles,m.id,menu_id) as items,
        (SELECT count(m2.id) FROM framework.mainmenu as m2 WHERE m2.parentid = m.id) as childs
      FROM framework.mainmenu as m
      	--JOIN framework.menus as mn on mn.id = m.menuid --and not mn.ismainmenu 
      WHERE  ((SELECT count(*)
      			FROM json_array_elements_text(_roles) as r
                WHERE r.value::varchar = '0'
           		)>0     
      
      			 or 
      		 (SELECT count(*)
                			FROM json_array_elements_text(m.roles) as r
                             JOIN json_array_elements_text(_roles) as r2 on r2.value::varchar = r.value ::varchar 
                            )>0)
      	and coalesce(m.parentid,0) = coalesce(_parentid,0) and m.menuid = menu_id
      ORDER BY m.orderby
      ) as d
    INTO outjson;
END;
$$;


ALTER FUNCTION framework.fn_menu_recurs(_roles json, _parentid integer, menu_id integer, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 358 (class 1255 OID 179973)
-- Name: fn_menus(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_menus(injson json, OUT outjson json) RETURNS json
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
			LEFT JOIN framework.orgs as o on u.orgid = o.id 
        WHERE u.id = _userid) as d
        INTO _userdetail;
     
    END IF;    
	

    --outjson = framework.fn_menu_recurs(_roles, 0);
	SELECT
    	row_to_json(d)
    FROM
    (SELECT 
    	--outjson as mainmenu,
        _userdetail as userdetail,
        (SELECT
        	array_to_json(array_agg(row_to_json(t)))
         FROM
        (SELECT 
        	ms.menutype as id,
            mt.mtypename as menutype,
            coalesce(framework.fn_menu_recurs(_roles, 0,ms.id),'[]') as menu
         FROM framework.menus as ms 
         	JOIN framework.menutypes as mt on mt.id = ms.menutype
         ) as t) as menus,
        coalesce(_usermenu,'[]') as usermenu) as d
    INTO outjson;    
    
    --outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_menus(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 359 (class 1255 OID 179974)
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
-- TOC entry 360 (class 1255 OID 179975)
-- Name: fn_paramtypes(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_paramtypes(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN

	SELECT 
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT
    	a.val as label,
        a.val as value
    FROM framework.paramtypes as a) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');
    

END;
$$;


ALTER FUNCTION framework.fn_paramtypes(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 361 (class 1255 OID 179976)
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
	--_oldconfig = injson->>'config';
	_tabname = injson->>'tabname';
    
    SELECT * FROM framework.fn_createconfig(injson) INTO _oldconfig;

    
   /*-- perform raiserror(_newconfig::varchar);
    SELECT * FROM framework.fn_createconfig(injson) INTO _newconfig;

    FOR nw in (SELECT * FROM json_array_elements_text(_newconfig))
    LOOP 
    	isnotin = true;
        FOR ov in (SELECT * FROM json_array_elements_text(_oldconfig))
        LOOP
			IF (ov->>'col')::varchar = (nw->>'col')::varchar 
            	and 
            	ov->>'related' is null and ov->>'tpath' is null and isnotin
                 THEN
				isnotin = false;   
            END IF;
        END LOOP;
        

        
        IF isnotin  THEN
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
			IF (nw->>'col')::varchar = (ov->>'col')::varchar  THEN
				isin = false;
            END IF;

        END LOOP;
        IF isin and ov->>'related' is null THEN
        	SELECT _oldconfig::jsonb - i
            INTO _oldconfig;
		END IF;
        i = i+1;
    END LOOP;*/
	
    outjson = _oldconfig;
    
    

END;
$$;


ALTER FUNCTION framework.fn_refreshconfig(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 362 (class 1255 OID 179977)
-- Name: fn_savestate(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_savestate(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
_squery varchar;
_tablename varchar(300);
_col varchar(350);
_value varchar;
_id varchar(300);
_userid int;
_relatecolumn varchar(150);
_relatetable varchar(350);
--_squery varchar;
_err varchar;
_oldata json;
_newdata json;
_id_int int;
_id_seq varchar(200);
_col_type varchar(300);
rel_id varchar(36);
_id_type varchar(150);
rel_id_type varchar(150);
_viewid int;
_userroles json;
_viewroles json;
_type varchar(150);
_relation varchar;
_relationobj json;
_relationval varchar;
_key varchar(150);
_x varchar;
_rv varchar;
_config json;
_pv json;
_data json;
_insertvalues varchar;
_rt_query varchar;
_tpath json;
_tp json;
_tpast VARCHAR(150);
BEGIN
  _id = injson->>'id';
  _userid = injson->>'userid';
  _viewid = injson->>'viewid';
  _data = injson->>'data';
  _relation = injson->>'relation';
  _relationobj = injson->>'relationobj';
  
  SELECT
  	v.tablename,
    --v.config,
    v.roles
  FROM framework.views as v
  WHERE v.id = _viewid
  INTO _tablename, _viewroles;
  
  _config = framework.fn_config_to_json(_viewid);
  
  IF _viewid is NULL
  THEN
     PERFORM raiserror('view id is null');
  END IF; 

  SELECT 
  	roles
  FROM framework.users 
  WHERE id = _userid
  INTO _userroles;
  
  --PERFORM raiserror(_relationval::varchar);
    
  IF _viewroles is null THEN
      PERFORM raiserror('view is not found');
  END IF;
  
  IF (SELECT count(*) FROM json_array_elements_text(_viewroles)) > 0 and 
    (SELECT count(*) 
     FROM json_array_elements_text(_viewroles) as v
     	JOIN json_array_elements_text(_userroles) as r on 
        ((v.value::json->>'value')::varchar = r.value::varchar
        	OR
          v.value::varchar = r.value::varchar
        )
     ) = 0 THEN
    	PERFORM raiserror('m403err');
  END IF;
  
  SELECT 
        t.data_type, t.column_default
  FROM information_schema.columns as t                                         
  WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
      upper(t.column_name) = 'ID'
  INTO _id_type, _id_seq;
  
  IF _relation is not null  THEN
  	FOR _x in (SELECT regexp_split_to_table FROM regexp_split_to_table(_relation,','))
    LOOP
    	IF _relationobj->>_x is not null THEN
        	_rv = _relationobj->>_x;
            IF _rv = '_userid_' and 
               _tablename not in (
                    'framework.defaultval',
                    'framework.actions',
                    'framework.act_parametrs',
                    'framework.select_condition'
               )  
            THEN
               	_rv = _userid;
            END IF;
            IF _rv = '_orgs_' and 
               _tablename  not in (
                    'framework.defaultval',
                    'framework.actions',
                    'framework.act_parametrs',
                    'framework.select_condition'
               )   
            THEN
               	SELECT
                   	u.orgs::varchar 
                FROM framework.users as u
                WHERE u.id = _userid::int
                INTO _rv;
            END IF;
        	IF _rv = '_orgid_' and 
               _tablename not in (
                    'framework.defaultval',
                    'framework.actions',
                    'framework.act_parametrs',
                    'framework.select_condition'
               )  
            THEN
              SELECT
                  u.orgid::varchar 
              FROM framework.users as u
              WHERE u.id = _userid::int
              INTO _rv;
      		END IF;            
      		_relationval = concat(_relationval,',''',_rv,'''');
            
      END IF;
  	END LOOP;
    SELECT
    	string_agg(concat('"',regexp_split_to_table,'"'),',')
    FROM regexp_split_to_table(_relation,',')
    INTO _relation;    
  	_relation = concat(',',_relation);  
  ELSE
  	_relation = '';
    _relationval = '';
  END IF;
  
  IF _id is NULL THEN
      IF _id_type in ( 'character','varchar','char') 
      THEN
      	_id = upper(uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36));
      ELSE
      	EXECUTE format(concat('SELECT ',_id_seq,';')) INTO _id_int ;
      	_id = _id_int::varchar;
      END IF;
      _squery = concat('INSERT INTO ', _tablename, '(id',_relation);
      _insertvalues = concat('VALUES ($1::',_id_type,_relationval);
      
      IF 
      	(SELECT count(t.*)
         FROM information_schema.columns as t
         WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
             t.column_name = 'userid')>0 
      THEN
          _squery = concat(_squery,',userid');
          _insertvalues = concat(_insertvalues,',$2'); 
      END IF;
  ELSE
      _squery = concat('UPDATE ', _tablename, ' SET ');
      IF 
      	(SELECT count(t.*)
         FROM information_schema.columns as t
         WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
             t.column_name = 'userid')>0 
      THEN
          _squery = concat(_squery,'userid = $2, ');
      END IF;
  END IF;
  
  FOR _pv in (SELECT value FROM json_array_elements(_config))
  LOOP
  	_value = _data->>(_pv->>'key');
    
    IF _value = '_userid_' and 
       _tablename not in (
       		'framework.defaultval',
            'framework.actions',
            'framework.act_parametrs',
            'framework.select_condition'
       ) 
    THEN
    	_value = _userid;
    END IF;
    
    IF _value = '_orgs_' and 
       _tablename not in (
       		'framework.defaultval',
            'framework.actions',
            'framework.act_parametrs',
            'framework.select_condition'
       )  
    THEN
    	SELECT
        	u.orgs::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid::int
        INTO _value;
    END IF;
    
    IF _value = '_orgid_' and 
       _tablename not in (
       		'framework.defaultval',
            'framework.actions',
            'framework.act_parametrs',
            'framework.select_condition'
       )  
    THEN
    	SELECT
        	u.orgid::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid::int
        INTO _value;
    END IF;
    
	_relatetable = _pv->>'table';
    _col = _pv->>'col';
    _type = _pv->>'type';
    _key = _pv->>'key';
    
    IF (_pv->>'visible')::boolean and (_pv->>'type') not in ('label','color','link','filelist','gallery') THEN
      IF _relatetable is not null and _id is null
      THEN
        PERFORM raiserror('id can`t be null if relation');
      END IF;
      
      
      
      
      
      IF _type = 'password' THEN
         drop extension pgcrypto;
         create extension pgcrypto;
         SELECT encode(digest(_value, 'sha224'),'hex') INTO _value;
      END IF;
      IF _type <> 'array' THEN
        IF _pv->>'table' is null THEN
          SELECT t.data_type
          FROM information_schema.columns as t
          WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
                t.column_name = _col
          INTO _col_type; 	
           
          IF _col_type = 'character' THEN
            _col_type = 'varchar'; 
          END IF;
         
          IF _col_type is null THEN
             perform raiserror('can not find out the column type. check table and column names');
          END IF;
        
          IF _id_type = 'character' THEN
            _id_type = 'varchar'; 
          END IF;
          
          _data = (_data::jsonb-(_pv->>'key'))::json;
          _data = (jsonb_build_object((_pv->>'key'), _value) 
              || _data::jsonb)::json;
          
          IF (injson->>'id') is null THEN
            IF _value is not null  THEN
              _squery = concat(_squery,',"',_col,'"');
              _insertvalues = concat(_insertvalues,',($3->>''',_key,''')::',_col_type);
            END IF;
          ELSE
            IF _pv->>'table' is null THEN
                _squery = concat(_squery,'"',_col,'" = ($3->>''',_key,''')::',_col_type,', ');
            END IF;
          END IF;
        ELSE
           SELECT t.data_type
           FROM information_schema.columns as t
           WHERE concat(t.table_schema,'.',t.table_name) = (_pv->>'table') and 
                 t.column_name = _col
           INTO _col_type; 	
             
           IF _col_type = 'character' THEN
              _col_type = 'varchar'; 
           END IF;
           
           IF _col_type is null THEN
               perform raiserror('can not find out the column type. check table and column names');
           END IF;
          _rt_query = concat('UPDATE ',_pv->>'table',' SET "',_col,'" = ($2->>''',_key,''')::',_col_type,' FROM ',_tablename,' as t');
          _tpath = _pv->>'tpath';
          _tp = _tpath->0;
          _tpast = 't';
          FOR _tp in (SELECT value FROM json_array_elements(_tpath))
          LOOP
              _rt_query = concat(_rt_query,' JOIN ', _tp->>'table',' as ',_tp->>'t',' on ',_tpast,'."',_tp->>'col','" = ',_tp->>'t','.id');
          END LOOP;
          
          _rt_query = concat(_rt_query,' WHERE t.id = $1::',_id_type);   
          
          EXECUTE format(_rt_query) USING _id,_data;
        END IF;
      END IF; 
	END IF;
  END LOOP;
  
  IF injson->>'id' is null THEN
  	_squery = concat(_squery,') ',_insertvalues,'); ');
    EXECUTE format(_squery) USING _id,_userid,_data;
        
    _squery = concat('
      SElECT
        row_to_json(d)
      FROM (
        SELECT *
        FROM ',_tablename,'
        WHERE id = $1::',_id_type,'
      ) as d
    ');
    
    EXECUTE format(_squery) USING _id INTO _newdata;
    
	INSERT INTO framework.logtable (
      	tablename, tableid, opertype,
        userid, oldata, newdata
    ) VALUES (
      	_tablename, _id, 1,
        _userid::int, '{}'::json, _newdata
    );    
  ELSE
  
    EXECUTE format(concat('
      SElECT
        row_to_json(d)
      FROM (
        SELECT *
        FROM ',_tablename,'
        WHERE id = $1::',_id_type,'
      ) as d
    ')) USING _id INTO _oldata;
    
  	_squery = concat(substring(_squery,1,length(_squery) - 2),' WHERE id = $1::',_id_type);
    EXECUTE format(_squery) USING _id,_userid,_data;
    
    EXECUTE format(concat('
      SElECT
        row_to_json(d)
      FROM (
        SELECT *
        FROM ',_tablename,'
        WHERE id = $1::',_id_type,'
      ) as d
    ')) USING _id INTO _newdata;
    
	INSERT INTO framework.logtable (
    	tablename, tableid, opertype,
        userid, oldata, newdata
    ) VALUES (
    	_tablename, _id, 2,
        _userid::int, _oldata, _newdata
    );
  END IF;
  
  SElECT
    row_to_json(d)
  FROM (
      SELECT _id as id
    ) as d
  INTO outjson;
  /*SElECT
  	row_to_json(d)
  FROM (
  	SELECT _id as id,
    	_value as value
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'{}');*/
  
END;
$_$;


ALTER FUNCTION framework.fn_savestate(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3125 (class 0 OID 0)
-- Dependencies: 362
-- Name: FUNCTION fn_savestate(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_savestate(injson json, OUT outjson json) IS 'save all form state';


--
-- TOC entry 363 (class 1255 OID 179979)
-- Name: fn_saveusersettings(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_saveusersettings(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_userid int;
    _settings json;
    _osettings json;
BEGIN
	_userid = injson->>'userid';
    _settings = injson->>'settings';
    
   UPDATE framework.users
   SET usersettings = _settings
   WHERE id = _userid;
   
END;
$$;


ALTER FUNCTION framework.fn_saveusersettings(injson json) OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 179980)
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
_relation varchar;
_relationobj json;
_relationval varchar;
_x varchar;
_rv varchar;
BEGIN
  -- SAVE ONE COLUMN VALUE FOR TYPE form full
  
 -- _tablename = injson->>'tablename';
  _col = (injson->>'config')::json->>'col';
  _value = injson->>'value';
  _id = injson->>'id';
  _userid = injson->>'userid';
  _relatecolumn = (injson->>'config')::json->>'relatecolumn';
  _relatetable = injson->>'relatetable';
  _viewid = injson->>'viewid';
  _type = (injson->>'config')::json->>'type';
  _relation = injson->>'relation';
  _relationobj = injson->>'relationobj';
  

    
    IF _viewid is NULL
    THEN
      perform raiserror('view id is null');
    END IF; 
    
    SELECT 
    	roles,
        tablename
    FROM framework.views 
    WHERE id = _viewid
    INTO _viewroles, _tablename;
    
   IF _tablename <> 'framework.defaultval'
   THEN
    IF _value = '_userid_' and
       _tablename in (
       		'framework.defaultval',
            'framework.actions',
            'framework.act_parametrs',
            'framework.select_condition'
       )  
    THEN
    	_value = _userid;
    END IF;
    IF _value = '_orgs_' and 
       _tablename in (
       		'framework.defaultval',
            'framework.actions',
            'framework.act_parametrs',
            'framework.select_condition'
       ) 
    THEN
    	SELECT
        	u.orgs::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid::int
        INTO _value;
    END IF;
    IF _value = '_orgid_' and 
       _tablename in (
       		'framework.defaultval',
            'framework.actions',
            'framework.act_parametrs',
            'framework.select_condition'
       ) 
    THEN
    	SELECT
        	u.orgid::varchar 
        FROM framework.users as u
    	WHERE u.id = _userid::int
        INTO _value;
    END IF;
   END IF;
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
     	JOIN json_array_elements_text(_userroles) as r on  (
        		(v.value::json->>'value')::varchar = r.value::varchar
                OR
                v.value::varchar = r.value::varchar
            )
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
   
   IF _col_type = 'character' THEN
  	_col_type = 'varchar'; 
   END IF;
   
   IF _col_type is null THEN
   	 perform raiserror('can not find out the column type. check table and column names');
   END IF;
  
  SELECT 
     t.data_type
  FROM information_schema.columns as t                                         
  WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
  upper(t.column_name) = 'ID'
  INTO _id_type;
  
  IF _id_type = 'character' THEN
  	_id_type = 'varchar'; 
  END IF;
  
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
     
     IF rel_id_type = 'character' THEN
     	rel_id_type = 'varchar'; 
     END IF;
     
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
      BEGIN
        _squery = concat('
            SELECT row_to_json(d) FROM	
            (SELECT 
              "',_col,'"
            FROM ',_tablename,'
            WHERE id = $1::',_id_type,' ) as d;');
            
        EXECUTE format(_squery) USING rel_id INTO _oldata;
        
      END;
      _squery = concat('SELECT row_to_json(d) FROM 
          (SELECT $1 as ',_col,') as d;');
      
      EXECUTE format(_squery) USING _value INTO _newdata; 
     
      INSERT INTO framework.logtable (
         tablename, tableid, opertype,
         userid, oldata, newdata, colname
      ) VALUES (
         _tablename, rel_id, 2,
         _userid::int, _oldata, _newdata, _col      
      ); 
     IF (SELECT count(t.*)
      FROM information_schema.columns as t
      WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
           t.column_name = 'userid')>0 THEN
     _squery = concat('          
          UPDATE ', _tablename, ' 
          SET "',_col,'" = $2::',_col_type,' , userid = $3 
          WHERE id::',_id_type,' = $1::',_id_type,'; 
      ');	
      EXECUTE format(_squery) USING rel_id,_value, _userid::int;
      ELSE
	  	  _squery = concat('          
          UPDATE ', _tablename, ' 
          SET "',_col,'" = $2::',_col_type,'
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
      IF _relation is not null THEN
         FOR _x in (SELECT regexp_split_to_table FROM regexp_split_to_table(_relation,','))
         LOOP
            IF _relationobj->>_x is not null THEN
  				_rv = _relationobj->>_x;
                IF _rv = '_userid_' and 
                   _tablename not in (
                    'framework.defaultval',
                    'framework.actions',
                    'framework.act_parametrs',
                    'framework.select_condition'
                   )  
                THEN
                    _rv = _userid;
                END IF;
                IF _rv = '_orgs_' and 
                   _tablename not in (
                      'framework.defaultval',
                      'framework.actions',
                      'framework.act_parametrs',
                      'framework.select_condition'
                   )  
                THEN
                    SELECT
                        u.orgs::varchar 
                    FROM framework.users as u
                    WHERE u.id = _userid::int
                    INTO _rv;
                END IF;
                IF _rv = '_orgid_' and 
                   _tablename not in (
                      'framework.defaultval',
                      'framework.actions',
                      'framework.act_parametrs',
                      'framework.select_condition'
                   )  
                THEN
                    SELECT
                        u.orgid::varchar 
                    FROM framework.users as u
                    WHERE u.id = _userid::int
                    INTO _rv;
                END IF;
    
                _relationval = concat(_relationval,',''',_rv,'''');
            END IF;
         END LOOP;
         
        SELECT
            string_agg(concat('"',regexp_split_to_table,'"'),',')
        FROM regexp_split_to_table(_relation,',')
        INTO _relation;           
        
        _relation = concat(',',_relation);  
      ELSE
      	_relation = '';
        _relationval = '';
      END IF; 
      
      IF _id_type in ( 'character','varchar','char') 
      THEN
      	   _id = upper(uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36));
      ELSE
      	   EXECUTE format(concat('SELECT nextval(''',_tablename,'_id_seq''::regclass);')) INTO _id_int ;
           _id = _id_int::varchar;
      END IF;   
     IF 
      (SELECT count(t.*)
       FROM information_schema.columns as t
       WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
            t.column_name = 'userid') > 0 
     THEN
        _squery = concat(
        	'INSERT INTO ', 
            _tablename, 
            '(id,"',_col,'"',_relation,', userid) 
            VALUES ($1::',
            _id_type,',$2::',
            _col_type,_relationval,
            ',$3); '
        );  
                            
        EXECUTE format(_squery) USING _id,_value, _userid::int;
     ELSE
        _squery = concat(
        	'INSERT INTO ', 
            _tablename, 
            '(id,"',_col,'"',
            _relation,') 
            VALUES ($1::',
            _id_type,',$2::',
            _col_type,_relationval,'); '
        );                     
     	EXECUTE format(_squery) USING _id,_value;
     END IF;   
         
      _squery = concat(
      	'SELECT row_to_json(d) FROM 
        	(SELECT $1 as ',_col,') as d;'
       );
              
       EXECUTE format(_squery) USING _value INTO _newdata;
                 
       INSERT INTO framework.logtable (
             tablename, tableid, opertype,
             userid, newdata, colname
       ) VALUES (
             _tablename, _id, '1',
             _userid::int, _newdata, _col
       );             
           	
  	ELSE
    
    	IF trim(coalesce(_id,'')) = '' THEN
        	perform raiserror('id is null');
        END IF;
        
         _squery = concat(
         	'SELECT row_to_json(d) FROM	
            	 (SELECT 
                  	"',_col,'"
                  FROM ',_tablename,'
                  WHERE id = $1::',_id_type,') as d;'
         );
         EXECUTE format(_squery) USING _id INTO _oldata;  
        IF (SELECT count(t.*)
            FROM information_schema.columns as t
            WHERE concat(t.table_schema,'.',t.table_name) = _tablename and 
               t.column_name = 'userid') > 0 
        THEN
             _squery = concat( 
             	' UPDATE ', _tablename, ' 
                  SET "',_col,'" = $2::',_col_type,' , userid = $3
                  WHERE id = $1::',_id_type,';'
             );
    							
             EXECUTE format(_squery) USING _id,_value, _userid::int; 
        ELSE
             _squery = concat( 
             	' UPDATE ', _tablename, ' 
                  SET "',_col,'" = $2::',_col_type,' 
                  WHERE id = $1::',_id_type,';'
             );
             EXECUTE format(_squery) USING _id,_value; 
        END IF;   
  
        _squery = concat(
        	'SELECT row_to_json(d) FROM 
            	(SELECT $1 as ',_col,') as d;');                
        EXECUTE format(_squery) USING _value INTO _newdata;
          
        INSERT INTO framework.logtable (
              tablename, tableid, opertype,
              userid, oldata, newdata, colname
        ) VALUES (
              _tablename, _id, 2,
              _userid::int, _oldata, _newdata, _col
        );         
    END IF;
  END IF; 
    
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
-- TOC entry 3126 (class 0 OID 0)
-- Dependencies: 364
-- Name: FUNCTION fn_savevalue(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_savevalue(injson json, OUT outjson json) IS 'SAVE ONE COLUMN VALUE FOR TYPE form full';


--
-- TOC entry 365 (class 1255 OID 179982)
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
-- TOC entry 366 (class 1255 OID 179983)
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
-- TOC entry 367 (class 1255 OID 179984)
-- Name: fn_tabcolumns_for_filters(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns_for_filters(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _viewid int;
  _tabname varchar(150);
  _substr varchar(540);
BEGIN

	-- for select conditions
  _viewid = (injson->'inputs')->>'id';
  _substr = injson->>'substr';
  
  SELECT
  	v.tablename
  FROM framework.views as v
  WHERE v.id = _viewid
  INTO _tabname;
  	
  _substr = concat('%',upper(coalesce(_substr,'%')),'%');

	
 /* SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname and 
  	upper(column_name) like _substr) as d
  INTO outjson;*/
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (
  
  SELECT
  	title as label,
    id as value
  FROM framework.config
  WHERE viewid = _viewid
  ) as d
  INTO outjson;
  
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns_for_filters(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3127 (class 0 OID 0)
-- Dependencies: 367
-- Name: FUNCTION fn_tabcolumns_for_filters(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_tabcolumns_for_filters(injson json, OUT outjson json) IS 'for select conditions';


--
-- TOC entry 368 (class 1255 OID 179985)
-- Name: fn_tabcolumns_for_filters_arr(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns_for_filters_arr(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _viewid int;
  _tabname varchar(150);
  _substr varchar(540);
  _cols json;
BEGIN

	-- for select conditions
  _viewid = (injson->'inputs')->>'id';
  _substr = injson->>'substr';
  
  SELECT
  	v.tablename
  FROM framework.views as v
  WHERE v.id = _viewid
  INTO _tabname;
  	
  --
  IF _substr like '[%' THEN
  	_cols = _substr::json;
  END IF;	
  
  _substr = concat('%',upper(coalesce(_substr,'%')),'%');
  
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname and 
  	
	(upper(column_name) in (
    	SELECT
        	upper(value::varchar)
        FROM json_array_elements_text(_cols)
    	)
        or upper(column_name) like _substr)
  
        ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns_for_filters_arr(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3128 (class 0 OID 0)
-- Dependencies: 368
-- Name: FUNCTION fn_tabcolumns_for_filters_arr(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_tabcolumns_for_filters_arr(injson json, OUT outjson json) IS 'for select conditions';


--
-- TOC entry 369 (class 1255 OID 179986)
-- Name: fn_tabcolumns_for_sc(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns_for_sc(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tabname varchar(150);
  _substr varchar(540);
BEGIN

	-- for select conditions
  _tabname = (injson->'inputs')->>'table';
  _substr = injson->>'substr';
  	
  _substr = concat('%',upper(coalesce(_substr,'%')),'%');

	
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname and 
  	upper(column_name) like _substr) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns_for_sc(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3129 (class 0 OID 0)
-- Dependencies: 369
-- Name: FUNCTION fn_tabcolumns_for_sc(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_tabcolumns_for_sc(injson json, OUT outjson json) IS 'for select conditions';


--
-- TOC entry 370 (class 1255 OID 179987)
-- Name: fn_tabcolumns_selforconfig_depselect(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns_selforconfig_depselect(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tabname varchar(150);
  _substr varchar(350);
  _config json;
  _key1 varchar(400);
BEGIN
  _config = (injson->'config');
  
  SELECT 
  	cc.value->>'key'
  FROM json_array_elements(_config) as cc 
  WHERE (cc.value->>'title') = 'relation table'
  INTO _key1;

  _tabname = (injson->'data')->>'relation_relation';
  _substr = injson->>'substr';	
  
  _substr = upper(concat('%',coalesce(_substr,'%'),'%'));
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname
   AND upper(column_name) like _substr
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns_selforconfig_depselect(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 371 (class 1255 OID 179988)
-- Name: fn_tabcolumns_selforconfig_multiselect(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns_selforconfig_multiselect(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tabname varchar(150);
  _substr varchar(350);
  _config json;
  _key1 varchar(400);
BEGIN
  _config = (injson->'config');
  
  SELECT 
  	cc.value->>'key'
  FROM json_array_elements(_config) as cc 
  WHERE (cc.value->>'title') = 'multiselecttable'
  INTO _key1;
 -- _key1 = _config->>'key';
  
  _tabname = (injson->'data')->>_key1;
  _substr = injson->>'substr';	
  
  _substr = upper(concat('%',coalesce(_substr,'%'),'%'));
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname
   AND upper(column_name) like _substr
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns_selforconfig_multiselect(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3130 (class 0 OID 0)
-- Dependencies: 371
-- Name: FUNCTION fn_tabcolumns_selforconfig_multiselect(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_tabcolumns_selforconfig_multiselect(injson json, OUT outjson json) IS 'mt';


--
-- TOC entry 372 (class 1255 OID 179989)
-- Name: fn_tabcolumns_selforconfig_relselect(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_tabcolumns_selforconfig_relselect(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tabname varchar(150);
  _substr varchar(350);
  _config json;
  _key1 varchar(400);
BEGIN
  _config = (injson->'config');
  
  SELECT 
  	cc.value->>'key'
  FROM json_array_elements(_config) as cc 
  WHERE (cc.value->>'title') = 'relation table'
  INTO _key1;

  _tabname = (injson->'data')->>_key1;
  _substr = injson->>'substr';	
  
  _substr = upper(concat('%',coalesce(_substr,'%'),'%'));
  
  SELECT 
  	array_to_json(array_agg(row_to_json(d)))
  FROM
  (SELECT column_name as label,
    column_name as value
  FROM information_schema.columns
  WHERE concat(table_schema,'.',table_name) = _tabname
   AND upper(column_name) like _substr
  ) as d
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_tabcolumns_selforconfig_relselect(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 375 (class 1255 OID 179990)
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
    (SELECT 
      array_to_json(array_agg(row_to_json(t))) 
    FROM
          (SELECT 
          	ta.*
          FROM framework.treesacts as ta
          WHERE coalesce(ta.act,'')<>'' and coalesce(ta.title,'')<>''
          	and ta.icon<>'' and ta.treesid = t.id) as t) as acts,   
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
          v.viewtype,
          tb.ismain
      FROM framework.treesbranches as tb
      	LEFT JOIN framework.views as v on v.id = tb.viewid
        LEFT JOIN framework.compos as c on c.id = tb.compoid
      WHERE tb.treesid = t.id and tb.title is not null
      ORDER BY tb.orderby) as d) as  items  
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
-- TOC entry 376 (class 1255 OID 179991)
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
-- TOC entry 377 (class 1255 OID 179992)
-- Name: fn_userorg_upd(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_userorg_upd(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _orgid int;
  _userid int;
BEGIN
	_orgid = injson->>'orgid';
	_userid = injson->>'userid';
    
    UPDATE framework.users
    SET orgid = _orgid
    WHERE id = _userid;

END;
$$;


ALTER FUNCTION framework.fn_userorg_upd(injson json) OWNER TO postgres;

--
-- TOC entry 378 (class 1255 OID 179993)
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
-- TOC entry 3131 (class 0 OID 0)
-- Dependencies: 378
-- Name: FUNCTION fn_userorgs(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_userorgs(injson json, OUT outjson json) IS 'Change user orgid';


--
-- TOC entry 379 (class 1255 OID 179994)
-- Name: fn_view_byid(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_byid(injson json, OUT outjson json, OUT roles json) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_id int;
BEGIN
  -- GET VIEW DATA BY id
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
        v.subscrible,
        v.checker,
        v.api
    FROM framework.views as v
    WHERE v.id = _id) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'{}');
END;
$$;


ALTER FUNCTION framework.fn_view_byid(injson json, OUT outjson json, OUT roles json) OWNER TO postgres;

--
-- TOC entry 3132 (class 0 OID 0)
-- Dependencies: 379
-- Name: FUNCTION fn_view_byid(injson json, OUT outjson json, OUT roles json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_view_byid(injson json, OUT outjson json, OUT roles json) IS 'GET VIEW DATA BY id';


--
-- TOC entry 380 (class 1255 OID 179995)
-- Name: fn_view_cols_for_fn(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_cols_for_fn(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	_viewid int;
    _n int;
    _substr varchar(540);
BEGIN

	-- columns for fncols select_api
    
	_viewid = (injson->'inputs')->>'id';
  	
    
 	/*SELECT
    	viewid
    FROM framework.config
    WHERE id = _n
    INTO _viewid; */   
    
    SELECT
    	array_to_json(array_agg(row_to_json(d)))
    FROM(
       SELECT
          concat(title,' / ',col) as label,
          id::varchar as value
       FROM framework.config
       WHERE viewid = _viewid  
       UNION
       SELECT
          value::varchar as label,
          value::varchar as value
       FROM json_array_elements_text('["_userid_", "_orgid_", "_orgs_"]'::json)
    ) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_view_cols_for_fn(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3133 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION fn_view_cols_for_fn(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_view_cols_for_fn(injson json, OUT outjson json) IS '-- columns for visible_condition fncols';


--
-- TOC entry 381 (class 1255 OID 179996)
-- Name: fn_view_cols_for_param(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_cols_for_param(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	_viewid int;
    _n int;
    _substr varchar(540);
BEGIN

	-- columns for visible_condition select_api
    
	_n = (injson->'inputs')->>'actionid';
	_substr = injson->>'substr';
    --_viewid = (injson->'inputs')->>'viewid';
  	
    _substr = coalesce(_substr,'%');
    
 	_viewid = COALESCE(_viewid,(SELECT
    	viewid
    FROM framework.actions
    WHERE id = _n
    ));    
    
    SELECT
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT
    	concat(title,' / ',col) as label,
        id as value
    FROM framework.config
    WHERE viewid = _viewid and 
    	id::varchar like _substr) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_view_cols_for_param(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3134 (class 0 OID 0)
-- Dependencies: 381
-- Name: FUNCTION fn_view_cols_for_param(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_view_cols_for_param(injson json, OUT outjson json) IS '-- columns for visible_condition select_api';


--
-- TOC entry 373 (class 1255 OID 179997)
-- Name: fn_view_cols_for_sc(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_cols_for_sc(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	_viewid int;
    _n int;
    _substr varchar(540);
BEGIN

	-- columns for visible_condition select_api
    
	_n = (injson->'inputs')->>'configid';
	_substr = injson->>'substr';
    _viewid = (injson->'inputs')->>'viewid';
  	
    _substr = coalesce(_substr,'%');
    
 	_viewid = COALESCE(_viewid,(SELECT
    	viewid
    FROM framework.config
    WHERE id = _n
    ));    
    
    SELECT
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT
    	concat(title,' / ',col) as label,
        id as value
    FROM framework.config
    WHERE viewid = _viewid and 
    	id::varchar like _substr) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'[]');

END;
$$;


ALTER FUNCTION framework.fn_view_cols_for_sc(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3135 (class 0 OID 0)
-- Dependencies: 373
-- Name: FUNCTION fn_view_cols_for_sc(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_view_cols_for_sc(injson json, OUT outjson json) IS '-- columns for visible_condition select_api';


--
-- TOC entry 374 (class 1255 OID 179998)
-- Name: fn_view_getByPath(character varying, character varying); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION "fn_view_getByPath"(_path character varying, _viewtype character varying, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
--DECLARE
  --_calendar_actions_cols varchar(500); -- FOR ERROR
 -- _relation varchar(250);
 -- _relation_columns json;
BEGIN
 IF (SELECT count(v.id)  
     FROM framework.views as v
 	 WHERE v."path" = _path ) = 0
 THEN
 	PERFORM raiserror('view is not found');
 END IF;
 
 IF _viewtype = 'list' and (SELECT count(v.id)  
     FROM framework.views as v
 	 WHERE v."path" = _path and v.viewtype in ('table','tiles','table_api','calendar')) = 0
 THEN
 	PERFORM raiserror('view with type list is not found');
 END IF;
 
 IF _viewtype = 'getone' and (SELECT count(v.id)  
     FROM framework.views as v
 	 WHERE v."path" = _path and v.viewtype like '%form%') = 0
 THEN
 	PERFORM raiserror('view with type getone is not found');
 END IF; 
 
 IF (
  SELECT v.viewtype 
  FROM framework.views as v
  WHERE v."path" = _path ) = 'calendar' 
 THEN
 	-- Calendar checks
    
	IF (
        SELECT count(c.id) 
        FROM framework.views as v
        	JOIN framework.config as c on c.viewid = v.id and c.visible and c.type = 'calendarStartDate'
        WHERE v."path" = _path 
    ) = 0
    THEN
 		PERFORM raiserror('view with type "calendar" must have one column typeof "calendarStartDate"');
 	END IF;
    
    
	IF (
        SELECT count(c.id) 
        FROM framework.views as v
        	JOIN framework.config as c on c.viewid = v.id and c.visible and c.type = 'calendarEndDate'
        WHERE v."path" = _path 
    ) = 0
    THEN
 		PERFORM raiserror('view with type "calendar" must have one column typeof "calendarEndDate"');
 	END IF;
    
	IF (
        SELECT count(c.id) 
        FROM framework.views as v
        	JOIN framework.config as c on c.viewid = v.id and c.visible and c.type = 'calendarTitle'
        WHERE v."path" = _path 
    ) = 0
    THEN
 		PERFORM raiserror('view with type "calendar" must have one column typeof "calendarTitle"');
 	END IF;
 END IF;
 
 SELECT
   row_to_json(d)
 FROM
  (SELECT
  	v.id,
    v.title,
    v.pagecount,
    v.pagination,
    v.checker,
    v.classname,
    v.orderby,
    v.ispagesize,
    v.subscrible,
    COALESCE((SELECT
     	array_to_json(array_agg(row_to_json(d)))
     FROM
    (SELECT
    	value as value,
        value as label
    FROM json_array_elements(v.roles) as rl) as d),'[]') as roles
    	
    ,
    v.viewtype,
    v.tablename,
    
    COALESCE((
      SELECT
      	array_to_json(array_agg(row_to_json(d)))
      FROM 
       (
        SELECT
            f.title,
            f.id,
            f.type,
            f.t,
            f.classname,
            c.col as column,
            
            CASE WHEN f.columns is not null
            THEN
            (
              SELECT
                array_to_json(array_agg(row_to_json(d)))
              FROM
                (
                  SELECT
                      cc.col as label,
                      cc.title as value,
                      concat(cc.col,'_',cc.id::varchar) as key,
                      CASE WHEN cc.relation is not null THEN cc.t
                      ELSE '1'
                      END as t
                  FROM json_array_elements_text(f.columns) as ff
                      JOIN framework.config as cc on cc.viewid = v.id and cc.title = ff.value::varchar
                ) as d)
            ELSE
              null
            END as columns,           
            COALESCE((SELECT
                array_to_json(array_agg(row_to_json(d)))
             FROM
            (SELECT
                value as value,
                value as label
            FROM json_array_elements(f.roles) as rl) as d),'[]') as roles,
            f."table"
        FROM framework.filters as f
        	LEFT JOIN framework.config as c on c.id = f.val_desc
        WHERE f.viewid = v.id
        ORDER BY f.column_order
    ) as d),'[]') as filters,
    
   COALESCE( (SELECT
   	 	array_to_json(array_agg(row_to_json(d)))
     FROM (
      SELECT
      	a.act_url as act,
        a.title,
        a.icon,
        a.classname,
        a.act_type as "type",
        a.main_action as ismain,
        coalesce((SELECT
           array_to_json(array_agg(row_to_json(d)))
         FROM
            (SELECT
                value as value,
                value as label
            FROM json_array_elements(a.roles) as rl) as d),'[]') as roles
        ,
        a.forevery as isforevery,
        a.ask_confirm as actapiconfirm,
        a.refresh_data as actapirefresh,
        upper(a.api_type) as actapitype,
        a.api_method as actapimethod,
        (SELECT
        	array_to_json(array_agg(row_to_json(d)))
         FROM
            (SELECT
              CASE WHEN ap.val_desc is not null
              THEN
              json_build_object(
                  'value',cc.title,
                  'label',cc.title,
                  't', cc.t,
                  'key',concat(cc.col,'_',cc.id::varchar)
              )
              ELSE
              	null
              END
               as paramcolumn,
             ap.paramconst,
             ap.paraminput,
             ap.paramt,
             ap.paramtitle,
             ap.query_type
            FROM framework.act_parametrs as ap
            	LEFT JOIN framework.config as cc on cc.id = ap.val_desc
            WHERE ap.actionid = a.id
            ) as d
        ) as parametrs,
       (SELECT
      	 	array_to_json(array_agg(row_to_json(d)))
        FROM
        (
        SELECT
            av.value,
            json_build_object(
            	'label',cc.col,
                't',cc.t,
                'value', cc.title,
                'key', concat(cc.col,'_',cc.id::varchar)
            ) as col,
            json_build_object('value',op.value,'js',op.js) as operation
        FROM framework.act_visible_condions as av
        	LEFT JOIN framework.operations as op on op.value = av.operation
            LEFT JOIN framework.config as cc on cc.viewid = v.id and cc.id = av.val_desc
        WHERE av.actionid = a.id
        ) as d) as act_visible_condition 
      FROM framework.actions as a
      WHERE a.viewid = v.id
      ORDER BY a.column_order) as d
    
    ),'[]') as acts
    ,
    framework.fn_config_to_json(v.id) as config
  FROM framework.views as v
  WHERE v."path" = _path) as d
  INTO outjson;

END;
$$;


ALTER FUNCTION framework."fn_view_getByPath"(_path character varying, _viewtype character varying, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 382 (class 1255 OID 180000)
-- Name: fn_view_getByPath_showSQL(character varying); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION "fn_view_getByPath_showSQL"(_path character varying, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
--DECLARE
  --variable_name datatype;
BEGIN
 IF (SELECT count(v.id)  
     FROM framework.views as v
 	 WHERE v."path" = _path ) = 0
 THEN
 	PERFORM raiserror('view is not found');
 END IF;
 

 
 SELECT
   row_to_json(d)
 FROM
  (SELECT
  	v.id,
    v.title,
    v.pagecount,
    v.pagination,
    v.checker,
    v.classname,
    v.orderby,
    v.ispagesize,
    v.subscrible,
    COALESCE((SELECT
     	array_to_json(array_agg(row_to_json(d)))
     FROM
    (SELECT
    	value as value,
        value as label
    FROM json_array_elements(v.roles) as rl) as d),'[]') as roles
    	
    ,
    v.viewtype,
    v.tablename,
    
    COALESCE((
      SELECT
      	array_to_json(array_agg(row_to_json(d)))
      FROM 
       (
        SELECT
            f.title,
            f.id,
            f.type,
            f.t,
            f.classname,
            f."column",
            
            CASE WHEN f.columns is not null
            THEN
            (
              SELECT
                array_to_json(array_agg(row_to_json(d)))
              FROM
                (
                  SELECT
                      cc.col as label,
                      cc.title as value,
                      concat(cc.col,'_',cc.id::varchar) as key,
                      CASE WHEN cc.relation is not null THEN cc.t
                      ELSE '1'
                      END as t
                  FROM json_array_elements_text(f.columns) as ff
                      JOIN framework.config as cc on cc.viewid = v.id and cc.title = ff.value::varchar
                ) as d)
            ELSE
              null
            END as columns,           
            COALESCE((SELECT
                array_to_json(array_agg(row_to_json(d)))
             FROM
            (SELECT
                value as value,
                value as label
            FROM json_array_elements(f.roles) as rl) as d),'[]') as roles,
            f."table"
        FROM framework.filters as f
        WHERE f.viewid = v.id
        ORDER BY f.column_order
    ) as d),'[]') as filters,
    
   COALESCE( (SELECT
   	 	array_to_json(array_agg(row_to_json(d)))
     FROM (
      SELECT
      	a.act_url as act,
        a.title,
        a.icon,
        a.classname,
        a.act_type as "type",
        a.main_action as ismain,
        coalesce((SELECT
           array_to_json(array_agg(row_to_json(d)))
         FROM
            (SELECT
                value as value,
                value as label
            FROM json_array_elements(a.roles) as rl) as d),'[]') as roles
        ,
        a.forevery as isforevery,
        a.ask_confirm as actapiconfirm,
        a.refresh_data as actapirefresh,
        upper(a.api_type) as actapitype,
        a.api_method as actapimethod,
        (SELECT
        	array_to_json(array_agg(row_to_json(d)))
         FROM
            (SELECT
              CASE WHEN ap.val_desc is not null
              THEN
              json_build_object(
                  'value',cc.title,
                  'label',cc.title,
                  't', cc.t,
                  'key',concat(cc.col,'_',cc.id::varchar)
              )
              ELSE
              	null
              END
               as paramcolumn,
             ap.paramconst,
             ap.paraminput,
             ap.paramt,
             ap.paramtitle,
             ap.query_type
            FROM framework.act_parametrs as ap
            	LEFT JOIN framework.config as cc on cc.id = ap.val_desc
            WHERE ap.actionid = a.id
            ) as d
        ) as parametrs,
       (SELECT
      	 	array_to_json(array_agg(row_to_json(d)))
        FROM
        (
        SELECT
            av.value,
            json_build_object(
            	'label',cc.col,
                't',cc.t,
                'value', cc.title,
                'key', concat(cc.col,'_',cc.id::varchar)
            ) as col,
            json_build_object('value',op.value,'js',op.js) as operation
        FROM framework.act_visible_condions as av
        	LEFT JOIN framework.operations as op on op.value = av.operation
            LEFT JOIN framework.config as cc on cc.viewid = v.id and cc.id = av.val_desc
        WHERE av.actionid = a.id
        ) as d) as act_visible_condition 
      FROM framework.actions as a
      WHERE a.viewid = v.id
      ORDER BY a.column_order) as d
    
    ),'[]') as acts
    ,
    framework.fn_config_to_json(v.id) as config
  FROM framework.views as v
  WHERE v."path" = _path) as d
  INTO outjson;

END;
$$;


ALTER FUNCTION framework."fn_view_getByPath_showSQL"(_path character varying, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 383 (class 1255 OID 180001)
-- Name: fn_view_link_showsql(character varying); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_link_showsql(_path character varying, OUT _link json) RETURNS json
    LANGUAGE plpgsql
    AS $$
-- SQL SHOW LINK GENERATOR
BEGIN
	_link = json_build_object(
    	'link', 
        (SELECT
    		concat(maindomain,'/schema?path=', _path)
   		 FROM framework.mainsettings
   		 WHERE isactiv),
        'title',
        'show sql');
END;
$$;


ALTER FUNCTION framework.fn_view_link_showsql(_path character varying, OUT _link json) OWNER TO postgres;

--
-- TOC entry 3136 (class 0 OID 0)
-- Dependencies: 383
-- Name: FUNCTION fn_view_link_showsql(_path character varying, OUT _link json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_view_link_showsql(_path character varying, OUT _link json) IS '-- SQL SHOW LINK GENERATOR';


--
-- TOC entry 384 (class 1255 OID 180002)
-- Name: fn_view_setKeys(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION "fn_view_setKeys"() RETURNS void
    LANGUAGE plpgsql
    AS $$
/*
	ADD "key" IN CONFIG
	FOR TRANSFER TO NEW VERSION
*/
BEGIN
	UPDATE framework.views SET config =
	(SELECT 
    	json_build_array(

   	ARRAY(SELECT 
    	value::jsonb || 
        (jsonb_build_object( 'key',
            	concat(
                	value->>'col','_',                         	
            		SUBSTRING((uuid_in(md5(random()::text || now()::text)::cstring)::CHAR(36)),1,5)
                )) )::jsonb as conf
    FROM json_array_elements(config)) ))->0;
    
    UPDATE framework.views as v
	SET acts = 
	jsonb_build_array(
		ARRAY(
          (SELECT
            (a.value::jsonb - 'parametrs') ||
            jsonb_build_object('parametrs',
              jsonb_build_array(
                ARRAY(
                  SELECT
                    CASE WHEN coalesce((p.value->>'paramconst'),'') = ''
                    THEN

                    jsonb_build_object('paramcolumn',
                      (p.value->'paramcolumn')::jsonb ||
                       test."fn_setParamsKey"(
                            v.config,
                            (p.value->>'paramcolumn')::jsonb
                        )
                      ) || p.value::jsonb - 'paramcolumn'
                    ELSE
                      (p.value)::jsonb
                    END
                  FROM json_array_elements(coalesce((a.value->>'parametrs')::json,'[]')) as p


                )
              )->0
            )


    	 FROM json_array_elements(v.acts) as a
     	)
   	 )
	)->0;
END;
$$;


ALTER FUNCTION framework."fn_view_setKeys"() OWNER TO postgres;

--
-- TOC entry 385 (class 1255 OID 180003)
-- Name: fn_view_title_link(integer, character varying); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION fn_view_title_link(viewid integer, title character varying, OUT lnk json) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
/*
	OLD V004
    NEED TO REMOVE AFTER TESTS

*/
	SELECT
    	row_to_json(d)
    FROM
	(SELECT 
    	concat('/composition/view?id=',viewid,'&act_id=-1&fl_id=-1&N=-1') as link,
        title as title) as d
    INTO lnk;

END;
$$;


ALTER FUNCTION framework.fn_view_title_link(viewid integer, title character varying, OUT lnk json) OWNER TO postgres;

--
-- TOC entry 386 (class 1255 OID 180004)
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

	-- FOR WS NOTFICATIONS

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
    	JOIN json_array_elements_text(ids) as n on (n.value::varchar = v.tableid /*or v.tableid is null*/)
    WHERE v.viewid = _viewid and 
    	 (v.foruser = _userid /*or v.foruser is null*/) and not v.isread and not v.issend
     ) as d    
     INTO outjson; 
	
    outjson = COALESCE(outjson,'[]');
END;
$$;


ALTER FUNCTION framework.fn_viewnotif_get(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3137 (class 0 OID 0)
-- Dependencies: 386
-- Name: FUNCTION fn_viewnotif_get(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION fn_viewnotif_get(injson json, OUT outjson json) IS 'FOR WS NOTFICATIONS';


--
-- TOC entry 387 (class 1255 OID 180005)
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
  _checker boolean;  
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
  _checker = injson->>'checker';
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
      subscrible,
      checker
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
      _subscrible   ,
      coalesce(_checker,false)  
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
        subscrible = coalesce(_subscrible,subscrible) ,
        checker = coalesce(_checker,checker)
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
-- TOC entry 388 (class 1255 OID 180006)
-- Name: fn_viewsave_V004(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION "fn_viewsave_V004"(injson json, OUT outjson json) RETURNS json
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
  _checker boolean;  
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
  _checker = injson->>'checker';
 IF _id is null THEN
/*
	OLD V004
    NEED TO REMOVE AFTER TESTS

*/
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
      subscrible,
      checker
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
      _subscrible   ,
      coalesce(_checker,false)  
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
        subscrible = coalesce(_subscrible,subscrible) ,
        checker = coalesce(_checker,checker)
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


ALTER FUNCTION framework."fn_viewsave_V004"(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3138 (class 0 OID 0)
-- Dependencies: 388
-- Name: FUNCTION "fn_viewsave_V004"(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION "fn_viewsave_V004"(injson json, OUT outjson json) IS '/*
	OLD V004
    NEED TO REMOVE AFTER TESTS

*/';


--
-- TOC entry 389 (class 1255 OID 180007)
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

--
-- TOC entry 390 (class 1255 OID 180008)
-- Name: get_colcongif_V004(json); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION "get_colcongif_V004"(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  col varchar(350);
  _table varchar(350);
  
BEGIN
/*
	OLD V004
    NEED TO REMOVE AFTER TESTS

*/
  	

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


ALTER FUNCTION framework."get_colcongif_V004"(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3139 (class 0 OID 0)
-- Dependencies: 390
-- Name: FUNCTION "get_colcongif_V004"(injson json, OUT outjson json); Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON FUNCTION "get_colcongif_V004"(injson json, OUT outjson json) IS '/*
	OLD V004
    NEED TO REMOVE AFTER TESTS

*/';


--
-- TOC entry 391 (class 1255 OID 180009)
-- Name: tr_actions_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_actions_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.act_type = 'API' and NEW.api_type is NULL THEN
    	NEW.api_type = 'get';	
    END IF;
    
    IF NEW.act_type = 'Save' THEN
    	NEW.forevery = false;
    END IF; 
	
    IF NEW.act_type in ('Delete', 'Expand') THEN
    	NEW.forevery = true;
    END IF; 
    
    IF NEW.act_type = 'Expand' and not (
    	NEW.act_url like '/list/%' OR 
		NEW.act_url like '/getone/%'
      )    
    THEN
    	PERFORM raiserror('Expand act must have list or getone url');
    END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_actions_tr() OWNER TO postgres;

--
-- TOC entry 392 (class 1255 OID 180010)
-- Name: tr_actions_tr_del(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_actions_tr_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	DELETE FROM framework.act_parametrs WHERE actionid = OLD.id;
    DELETE FROM framework.act_visible_condions WHERE actionid = OLD.id;
    
    RETURN OLD;
END;
$$;


ALTER FUNCTION framework.tr_actions_tr_del() OWNER TO postgres;

--
-- TOC entry 393 (class 1255 OID 180011)
-- Name: tr_calendar_actions_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_calendar_actions_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	SELECT
    	calendar_date, 
        calendar_date
    FROM framework.calendar_test
    WHERE id = NEW.calendar_id
    INTO NEW."start", NEW."end";
    
    RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_calendar_actions_tr() OWNER TO postgres;

--
-- TOC entry 394 (class 1255 OID 180012)
-- Name: tr_config_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_config_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	_col varchar(150);
	_title varchar(150);
    _tablename varchar(350); -- view major table name
    _tpath json;
    _tt varchar(150);
BEGIN

	SELECT
    	v.tablename
    FROM framework.views as v
    WHERE v.id = NEW.viewid
    INTO _tablename;
    
    -- if related column from other table
    IF NEW.table is not null THEN
    	_tablename = NEW.table;
    END IF;
    
    -- check multi type columns data_type in table
    IF NEW.type like 'multi%' THEN
        -- data_type must be JSON
        IF (SELECT 
            data_type
        FROM information_schema.columns
        WHERE concat(table_schema,'.',table_name) = _tablename AND
        	  column_name = NEW.col) <> 'json'
        THEN
        	PERFORM raiserror('for type multi(select, typehead), column type must be JSON');
        END IF;    	
    END IF;
    
    -- check relaition and type
    IF NEW.relation is not null THEN
      -- for multiselect, mu;titypehead types	
      -- only not api types
      IF NEW.type like 'multi%' AND 
      	 NEW.type not like '%_api'
      THEN
      	IF (
        	SELECT 
              count(table_name)
            FROM information_schema.columns
            WHERE concat(table_schema,'.',table_name) = NEW.relation
        ) = 0 THEN
        	PERFORM raiserror(concat('table ',NEW.relation,' is not found'));
        END IF;
        
        NEW.multiselecttable = NEW.relation;      
        NEW.multicolums = NEW.relationcolums;
        NEW.relationcolums = '[]';
      END IF;
      
      -- if type _api
      IF NEW.type like '%_api' AND 
      	 COALESCE(OLD.select_api,'') <> NEW.relation 
         and COALESCE(OLD.relation,'')<>NEW.relation
      THEN    
        NEW.select_api = NEW.relation;      
      END IF;
      
      -- do not change relation
      IF OLD.relation is null OR OLD.relation<>NEW.relation THEN
          NEW.relation = OLD.relation;
      END IF;
    END IF;
    
    
	-- add relation columns to config 
    -- only if not "array" type 
	IF NEW.relationcolums is not null AND 
    
       NOT NEW.copy AND
       
       NEW.type<>'array' AND
       
       NEW.relation is not null AND
       
      (SELECT count(*) FROM json_array_elements(NEW.relationcolums)) > 0 AND 
      
      (SELECT count(r.value) 
       FROM json_array_elements_text(NEW.relationcolums) as r
       WHERE r.value::varchar not in (
			SELECT r2.value::varchar 	
       		FROM json_array_elements_text(coalesce(OLD.relationcolums,'[]'::json)) as r2
       )) > 0
       
    THEN
    	_tt = NEW.t;
    	IF NEW.related = true 
        THEN
            /*[
            	{"t": "t2", "col": "region_id", "table": "nsi.ros_j5phs5f9ra"}, 
                {"t": "t7", "col": "addressTypeId", "table": "nsi.ros_n4rellrh3d"}
            ]*/
            --IF (SELECT FROM ) 
            SELECT
            	array_to_json(array_agg(row_to_json(d)))
            FROM (
              SELECT
                   concat('t',NEW.t) as t, 
                   NEW.relatecolumn as col, 
                   NEW.table as table
              UNION 
              SELECT	
                  concat(NEW.col,'_', NEW.t) as t, 
                  NEW.col, 
                  NEW.relation as table
            ) as d
            INTO _tpath;
            
            _tt = concat(NEW.col,'_', NEW.t);
        	--PERFORM raiserror('There is not realized yet!');
        END IF;
        _tpath = coalesce(_tpath,'[]');
        
    	FOR _col in (
        	SELECT 
            	VALUE::varchar 
            FROM json_array_elements_text(NEW.relationcolums)
            WHERE value::varchar not in (
              SELECT value::varchar
              FROM json_array_elements_text(OLD.relationcolums)
          )
        )
        LOOP
        	_title = _col;
            
        	IF 
             (SELECT 
            	count(c.id)
              FROM framework.config as c
              WHERE c.viewid = NEW.viewid and c.col = _col) >0
            THEN
            	_title = concat(_col,'_',NEW.id);
            END IF;
        	
            
        	INSERT INTO framework.config (
               col, title, type, visible,
               related, roles, relatecolumn,
               relation,
               relcol,
               classname, "join", t,
               "table", viewid,
               column_order, tpath
            )
        	SELECT
              _col as col, _title as title, 'label' as type, true as visible,
              true as related, '[]'::json as roles, NEW.col as relatecolumn,
              (
                SELECT 
                  	concat(y.table_schema, '.', y.table_name)
                FROM information_schema.table_constraints as c
                   	JOIN information_schema.key_column_usage AS x ON
                       	c.constraint_name = x.constraint_name and
                        x.column_name = _col
                    JOIN information_schema.constraint_column_usage AS y ON 
                       	y.constraint_name = c.constraint_name and
                        y.constraint_schema = c.constraint_schema
                WHERE concat(c.table_schema ,'.',c.table_name) = NEW.relation 
                    	and
                      c.constraint_type = 'FOREIGN KEY'
                LIMIT 1                
                
              ) as relation,
              COALESCE((
                SELECT 
                  	concat(y.column_name)
                FROM information_schema.table_constraints as c
                  	JOIN information_schema.key_column_usage AS x ON
                         c.constraint_name = x.constraint_name and
                         x.column_name = _col
                    JOIN information_schema.constraint_column_usage AS y ON 
                      	y.constraint_name = c.constraint_name and
                        y.constraint_schema = c.constraint_schema
                WHERE concat(c.table_schema ,'.',c.table_name) = NEW.relation 
                   	  and
                     c.constraint_type = 'FOREIGN KEY'
                LIMIT 1
              ),NEW.relcol) as relcol,
              '' as classname, false as "join", _tt as t,
              NEW.relation as "table", NEW.viewid,
              coalesce((
              	SELECT 
                 max(c.column_order) 
            	FROM framework.config as c
            	WHERE c.viewid = NEW.viewid),0
              ) + 1, _tpath;
        END LOOP;
    END IF;
    
    -- check function changing 
    IF OLD.fn is null and NEW.fn is not null
    THEN
    	PERFORM raiserror('You can not change simple column to function column');
    END IF;
	
    IF NEW.depency and NEW.depencycol is null THEN
    	PERFORM raiserror('depencycol can not be empty (null) when depency=TRUE!');
    END IF;
    
	-- change column order in all config
	/*IF OLD.column_order<>NEW.column_order and 
	  (SELECT
	     count(id)
	   FROM framework.config
	   WHERE viewid = NEW.viewid and column_order = NEW.column_order) > 0 
	THEN
	   UPDATE framework.config
	   SET
	      column_order = column_order + 1
	   WHERE viewid = NEW.viewid AND column_order >= NEW.column_order;
	END IF;*/

	RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_config_tr() OWNER TO postgres;

--
-- TOC entry 438 (class 1255 OID 180014)
-- Name: tr_config_tr_del(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_config_tr_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	-- column use in fncols 
    IF (
    	SELECT 
        	count(id)
        FROM framework.config
        WHERE (
        	SELECT 
            	count(*)
            FROM json_array_elements_text(OLD.fncolumns)
            WHERE value::varchar = OLD.id::varchar 
        ) > 0
    ) > 0 THEN
    	PERFORM raiserror('column use in fn columns');
    END IF;
    
    DELETE FROM framework.act_parametrs WHERE val_desc = OLD.id;
    DELETE FROM framework.act_visible_condions WHERE val_desc = OLD.id;
    DELETE FROM framework.filters WHERE val_desc = OLD.id;
	DELETE FROM framework.visible_condition WHERE configid = OLD.id;
	DELETE FROM framework.select_condition WHERE configid = OLD.id;
	DELETE FROM framework.visible_condition WHERE val_desc = OLD.id;
	DELETE FROM framework.select_condition WHERE val_desc = OLD.id;	
	DELETE FROM framework.defaultval WHERE configid = OLD.id;
    
    RETURN OLD;

END;
$$;


ALTER FUNCTION framework.tr_config_tr_del() OWNER TO postgres;

--
-- TOC entry 395 (class 1255 OID 180015)
-- Name: tr_config_tr_ins(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_config_tr_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF (
    	SELECT 
        	count(c.id)
        FROM framework.config as c
        WHERE c.title = NEW.title and c.viewid = NEW.viewid
    ) > 0
    THEN
    	NEW.title = CONCAT(NEW.title,'_',NEW.id::varchar);
    END IF;

	-- IF FN PARAMETR IS FN
	IF NEW.fn is not null
    THEN
    	IF NEW.fncolumns is not null and (
        	SELECT
            	count(c.id)
            FROM framework.config as c 
            	JOIN json_array_elements_text(NEW.fncolumns) as fc on c.id::varchar = fc.value::varchar
            WHERE c.fn is not null
        ) > 0
        THEN
        	PERFORM raiserror('fn columns can not be fn');
        END IF;
    END IF;
    
    -- CHECK T NUMBER
    IF NEW.table is NULL AND (
    	SELECT
        	count(c.id)
        FROM framework.config as c
        WHERE c.viewid = NEW.viewid and c.t = NEW.t
       ) > 0
    THEN
    	SELECT
        	max(c.t::int) + 1
        FROM framework.config as c
        WHERE c.viewid = NEW.viewid and isnumeric(c.t)
        INTO NEW.t;     
    END IF;
    
	RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_config_tr_ins() OWNER TO postgres;

--
-- TOC entry 396 (class 1255 OID 180016)
-- Name: tr_dialog_messages_tr_ins(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_dialog_messages_tr_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_dialog_users json;
    _status smallint;
BEGIN
	
	-- CHECK USER ACCESS IN DIALOG
	SELECT
    	d.users,
        d.status
    FROM framework.dialogs as d
    WHERE d.id = NEW.dialog_id
    INTO 
    	_dialog_users,
        _status
        ;
    
    IF NEW.userid not in (
    		SELECT value::varchar::int 
        	FROM json_array_elements(_dialog_users)
    	) 
    THEN
    	PERFORM raiserror('Access denied. User not in dialog');
    END IF;
    
    -- CHECK DIALOG STATUS
    IF _status in ('2')
    THEN
    	PERFORM raiserror('Dialog is closed');
    END IF;
    
    
    -- CHECK USER ACTIVATION
    IF (
    	SELECT 
        	count(u.id)
        FROM framework.users as u
        WHERE u.id = NEW.userid and u.isactive
     ) = 0 
    THEN
    	PERFORM raiserror('User not found or not active');
    END IF;
     
    -- COPY MESSAGE IF FORWARDED
    IF NEW.forwarded_from IS NOT NULL 
    THEN
    	SELECT
        	d.message_text,
            d.files,
            d.images
        FROM framework.dialog_messages as d
        WHERE d.id = NEW.forwarded_from
        INTO 
        	NEW.message_text,
            NEW.files,
            NEW.images;
    END IF;
    
    -- CHECK MESSAGE TEXT
    NEW.message_text = COALESCE(NEW.message_text,'');
    IF NEW.message_text = '' AND (
      SELECT
          count(*)
      FROM json_array_elements(NEW.files)
 	) = 0 AND (
      SELECT
          count(*)
      FROM json_array_elements(NEW.images)
    ) = 0
    THEN
		PERFORM raiserror('Message is empty');
    END IF;

    -- DEFAULTS
    NEW.files = COALESCE(NEW.files,'[]');    
    NEW.images = COALESCE(NEW.images,'[]');
    NEW.user_reads = array_to_json(ARRAY(
    	SELECT
        	NEW.userid
    ));
    
    
	RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_dialog_messages_tr_ins() OWNER TO postgres;

--
-- TOC entry 397 (class 1255 OID 180017)
-- Name: tr_dialogs_tr_edit(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_dialogs_tr_edit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

   IF NEW.dtype = '1' THEN
      NEW.title = OLD.title;
   END IF;
   
   RETURN NEW;
  
END;
$$;


ALTER FUNCTION framework.tr_dialogs_tr_edit() OWNER TO postgres;

--
-- TOC entry 398 (class 1255 OID 180018)
-- Name: tr_dialogs_tr_ins(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_dialogs_tr_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	-- IF PERSONAL DIALOG
	IF NEW.dtype = '1' 
    THEN
    	IF (
        	SELECT count(*) 
        	FROM json_array_elements(NEW.users)
        ) <> 2
        THEN
        	PERFORM raiserror('For pesonal dialog must be 2 users');
        END IF;
        
        
    	NEW.title = COALESCE(NEW.title,
        	(
              SELECT
                  string_agg(us.login,',') 
              FROM json_array_elements(NEW.users) as u
                  JOIN framework.users as us on us.id = u.value::varchar::int
            )
        );
        
        -- CHECK DUBLICATES
        IF (
        	SELECT 	
            	count(d.id)
        	FROM framework.dialogs as d
            WHERE  d.dtype = NEW.dtype and (
            	SELECT count(*) 
                FROM json_array_elements(NEW.users) as u1
                	JOIN json_array_elements(d.users) as u2 on u1.value::varchar::int = u2.value::varchar::int
            ) = 2
        ) > 0
        THEN
        	PERFORM raiserror('Dialog already exist');
        END IF;
        
        
    END IF; 
    
    -- CHECK USERS
    IF (
    	SELECT count(*) 
    	FROM json_array_elements(NEW.users)
    ) <> (
      SELECT
     	 count(*)
      FROM json_array_elements(NEW.users) as u
      	JOIN framework.users as us on us.id = u.value::varchar::int
      WHERE us.isactive
    )
    THEN
    	PERFORM raiserror('One of dialogs user are not found or not active');
    END IF;
    
    NEW.creator = NEW.userid;
    
    -- SET ADMINS BY DEFAULT
	NEW.dialog_admins = array_to_json(
    	ARRAY(
        	SELECT NEW.userid
        )
    );
    
	RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_dialogs_tr_ins() OWNER TO postgres;

--
-- TOC entry 399 (class 1255 OID 180019)
-- Name: tr_dialogs_tr_ins_after(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_dialogs_tr_ins_after() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_id int;
    _users json;
BEGIN
    -- SEND FIRST MESSAGE
    IF NEW.dtype = '1' AND NEW.first_message::varchar <> '{}'
    THEN
      PERFORM framework.fn_dialog_message_send(
         NEW.first_message
      );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_dialogs_tr_ins_after() OWNER TO postgres;

--
-- TOC entry 400 (class 1255 OID 180020)
-- Name: tr_filters_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_filters_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	-- get column title
	IF NEW.val_desc is not NULL
    THEN 
    	SELECT
        	col
        FROM framework.config
        WHERE id = NEW.val_desc
        INTO NEW."column";
	END IF;
    
    -- columns only for typehead type
    IF NEW.type<>'typehead' THEN
    	NEW.columns = '[]'::json;
    ELSE
    	NEW."column" = null;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_filters_tr() OWNER TO postgres;

--
-- TOC entry 401 (class 1255 OID 180021)
-- Name: tr_mainmenu_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_mainmenu_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF NEW.parentid is not null and NEW.parentid = NEW.id THEN
    	PERFORM raiserror('parent id can not be = id');
    END IF;
    
    IF NEW.parentid is not null and 
    	NEW.menuid is not null and
    (SELECT 
    	m.menutype
     FROM framework.menus as m
     WHERE m.id = NEW.menuid
     ) = '3' THEN
     	PERFORM raiserror('Footer menu can not have child elements');
    END IF;
    
    RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_mainmenu_tr() OWNER TO postgres;

--
-- TOC entry 402 (class 1255 OID 180022)
-- Name: tr_menu_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_menu_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF NEW.ismainmenu and NEW.menutype in ('1','2')
    THEN
    	UPDATE framework.menus
        SET ismainmenu = false
        WHERE id <> NEW.id;
    END IF;
    IF NEW.menutype not in ('1','2') THEN
    	NEW.ismainmenu = false; 
    END IF;
    
   
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_menu_tr() OWNER TO postgres;

--
-- TOC entry 403 (class 1255 OID 180023)
-- Name: tr_menus_tr_del(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_menus_tr_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF OLD.ismainmenu = true THEN
    	PERFORM raiserror('Access denied. It is main menu');
    END IF;
    
    DELETE FROM framework.mainmenu WHERE menuid = OLD.id;
    
    RETURN OLD;
END;
$$;


ALTER FUNCTION framework.tr_menus_tr_del() OWNER TO postgres;

--
-- TOC entry 404 (class 1255 OID 180024)
-- Name: tr_orgs(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_orgs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _useroles json;
  _userorgs json;
  _orgs json;
  _org int;
  _parentid int;
BEGIN
	SELECT 
    	u.roles,
        u.orgs
    FROM framework.users as u
    WHERE u.id = NEW.userid
    INTO _useroles,_userorgs;
    _orgs = concat('[',NEW.id::varchar,']')::json;
    
	IF COALESCE(NEW.parentid,0)<>0 THEN 
      WHILE COALESCE(NEW.parentid,0)<>0
      LOOP
          SELECT
              parentid
          FROM framework.orgs
          WHERE id = _org
          INTO _parentid;
          IF coalesce(_parentid,0) <> 0 THEN
              SELECT
                  (_orgs::jsonb || concat('[',_parentid::varchar,']')::jsonb)::json   
              INTO _orgs;
          END IF;
      END LOOP;    
    END IF;     
    
    IF NEW.orgtype in (2,3,4) and 
       (
       	(SELECT count(*)
         FROM json_array_elements_text(_useroles)
         WHERE value::varchar::int in (0,3)) = 0
         OR 
        (SELECT count(*)
         FROM json_array_elements_text(_orgs) as o
          	JOIN json_array_elements_text(_userorgs) as uo on 
                  	uo.value::varchar::int = o.value::varchar::int
        ) = 0
      ) THEN
      	PERFORM raiserror('Отказано в доступе');
    END IF;	
    
    IF NEW.orgtype in (1,5) and  -- Разрешить редактировать только админам системы, либо админам организаций
       (
       	(SELECT count(*)
         FROM json_array_elements_text(_useroles)
         WHERE value::varchar::int in (0,1)) = 0
         OR 
        (
           (SELECT count(*)
           FROM json_array_elements_text(_orgs) as o
              JOIN json_array_elements_text(_userorgs) as uo on 
                      uo.value::varchar::int = o.value::varchar::int
           ) = 0 
           AND 
          (SELECT count(*)
           FROM json_array_elements_text(_useroles)
           WHERE value::varchar::int in (0,1,2)) = 0
       )
      ) THEN
      	PERFORM raiserror('Отказано в доступе');
    END IF;	
    
    IF NEW.ogrn is not null and not isnumeric(NEW.ogrn)
    	and length(NEW.ogrn)<>13
    THEN
		PERFORM raiserror('ошибка в формате ОГРН');
    END IF;
    
    IF NEW.inn is not null and not isnumeric(NEW.inn)
    	and length(NEW.inn)<>10
    THEN
		PERFORM raiserror('ошибка в формате ИНН');
    END IF;

	IF new.orgname<>'' and new.orgtype is not null THEN
    	NEW.completed = true;
    END IF;
      
	RETURN new;


END;
$$;


ALTER FUNCTION framework.tr_orgs() OWNER TO postgres;

--
-- TOC entry 405 (class 1255 OID 180025)
-- Name: tr_select_condition_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_select_condition_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    
	IF NEW.const is null and NEW.val_desc is null and NEW.operation not like '%null%'
    THEN
    	PERFORM raiserror('const or value is null');
    END IF;
    
    IF NEW.const is not null and NEW.value is not null
    THEN
    	NEW.value = null;
    END IF;
    SELECT
    	row_to_json(d)
    FROM
    (SELECT
    	c.t,
        c.id as key,
        c.col as label,
        c.title as value
    FROM framework.config as c
    WHERE c.id = NEW.val_desc) as d
    INTO NEW.value;
    
    RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_select_condition_tr() OWNER TO postgres;

--
-- TOC entry 406 (class 1255 OID 180026)
-- Name: tr_spapi_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_spapi_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	-- existing in db
	IF (
      SELECT 
        count(p.proname)
      FROM pg_proc p 
      INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
      WHERE format('%I.%I', ns.nspname, p.proname) = NEW.procedurename 
    ) = 0 THEN
    	PERFORM raiserror('Can not found selected function');
    END IF;
    
    -- Check function description
    IF COALESCE((
      SELECT 
          pd.description
      FROM pg_proc p 
          INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
          LEFT JOIN pg_catalog.pg_description as pd on p.oid = pd.objoid
      WHERE format('%I.%I', ns.nspname, p.proname) = NEW.procedurename 
    ),'') = '' THEN
    	PERFORM raiserror('Function without description');
    END IF;
    
    -- IN parametr check
    IF (
      SELECT count(p.proname)	
      FROM pg_proc p 
          INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
          LEFT JOIN pg_catalog.pg_description as pd on p.oid = pd.objoid
          LEFT JOIN pg_type as pt on pt.oid = p.proargtypes[0]::int
      WHERE format('%I.%I', ns.nspname, p.proname) = NEW.procedurename 
      and p.proargnames[1] = 'injson' and upper(pt.typname) like '%JSON' 
      --and p.proargmodes[1] = 'i'
    ) = 0 THEN
    	PERFORM raiserror('Check injson parametr');
    END IF;
    
	-- title
	IF (
      SELECT 
        p.proname
      FROM pg_proc p 
      INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
      WHERE format('%I.%I', ns.nspname, p.proname) = NEW.procedurename 
    ) not like 'fn_%' THEN
    	PERFORM raiserror('Function title must begun with fn_');
    END IF;
    
    -- check api method path
    new.methodname = regexp_replace(new.methodname, '[^a-z0-9_]-', '', 'g');
    
    RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_spapi_tr() OWNER TO postgres;

--
-- TOC entry 407 (class 1255 OID 180027)
-- Name: tr_trees_add_org(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_trees_add_org() RETURNS trigger
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


ALTER FUNCTION framework.tr_trees_add_org() OWNER TO postgres;

--
-- TOC entry 408 (class 1255 OID 180028)
-- Name: tr_trees_tr_del(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_trees_tr_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	DELETE FROM framework.treesbranches WHERE treesid = OLD.id;
    DELETE FROM framework.treesacts WHERE treesid = OLD.id;
    
    RETURN OLD; 

END;
$$;


ALTER FUNCTION framework.tr_trees_tr_del() OWNER TO postgres;

--
-- TOC entry 409 (class 1255 OID 180029)
-- Name: tr_treesbranch_check(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_treesbranch_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.compoid is not null and OLD.compoid is null  THEN
    	NEW.viewid = null;
    END IF;
    
	IF NEW.viewid is not null and OLD.viewid is null  THEN
    	NEW.compoid = null;
    END IF;    
	IF NEW.ismain THEN
    	UPDATE framework.treesbranches
        SET ismain = false
        WHERE treesid = NEW.treesid and id<>NEW.id;
    END IF;
    
    return 	NEW;
END;
$$;


ALTER FUNCTION framework.tr_treesbranch_check() OWNER TO postgres;

--
-- TOC entry 433 (class 1255 OID 180030)
-- Name: tr_user_check(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_user_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
	useroles json;
    
BEGIN

	IF NEW.roles is not null and  NEW.roles::varchar not like '[%]' THEN
    	perform raiserror('roles format error');
    END IF;
	IF NEW.orgs is not null and  NEW.orgs::varchar not like '[%]' THEN
    	perform raiserror('orgs format error');
    END IF;
	IF NEW.roles is not null and (SELECT count(*) FROM json_array_elements_text(NEW.roles)) = 0 THEN
    	perform raiserror('no roles');
    END IF;
    
    SELECT
    	 roles
    FROM framework.users
    WHERE id = NEW.userid
    INTO useroles;
    

    IF NEW.roles::VARCHAR<>OLD.roles::varchar THEN
      	
       IF (SELECT 
          coalesce( min(r.hierarchy),100000)
        FROM  json_array_elements_text(Old.roles) as o
          JOIN framework.roles as r on r.id = o.value::varchar::smallint) <
        (SELECT 
              coalesce( min(r.hierarchy),100000)
        FROM  json_array_elements_text(useroles) as o
          JOIN framework.roles as r on r.id = o.value::varchar::smallint) THEN
         perform raiserror('user roles hierarchy error');
         
       END IF;   
  
          
    END IF;

	IF NEW.password is not null and NEW.password = 'd14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f' THEN
    	NEW.password = OLD.password;
    END IF;
    return NEW;
END;
$$;


ALTER FUNCTION framework.tr_user_check() OWNER TO postgres;

--
-- TOC entry 410 (class 1255 OID 180031)
-- Name: tr_view_tr_check(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_view_tr_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.viewtype like '%api' and NEW.tablename is NULL THEN
    -- if data-binding from API method - view type is api, tablename is not neccesary
    	NEW.tablename = '';
    END IF;
    
    SELECT		
    	COALESCE(NEW.descr,p.description)
    FROM pg_catalog.pg_statio_all_tables as t
    	LEFT JOIN pg_catalog.pg_description as p on p.objoid = t.relid
    WHERE concat(t.schemaname::varchar,'.',t.relname::varchar) = NEW.tablename 
    INTO NEW.descr;
    
    IF coalesce((
      SELECT		
          p.description
      FROM pg_catalog.pg_statio_all_tables as t
          LEFT JOIN pg_catalog.pg_description as p on p.objoid = t.relid
      WHERE concat(t.schemaname::varchar,'.',t.relname::varchar) = NEW.tablename 
      LIMIT 1
    ),'') = '' THEN
       PERFORM raiserror('Table has no description');
    END IF;

    RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_view_tr_check() OWNER TO postgres;

--
-- TOC entry 434 (class 1255 OID 180032)
-- Name: tr_views_tr_del(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_views_tr_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN


    DELETE FROM framework.actions WHERE viewid = OLD.id;    
        
	/*DELETE FROM framework.visible_condition WHERE configid in (
      SELECT id FROM framework.config WHERE viewid = OLD.id
    );
    
	DELETE FROM framework.select_condition WHERE configid in (
      SELECT id FROM framework.config WHERE viewid = OLD.id
    );
    
	DELETE FROM framework.defaultval WHERE configid in (
      SELECT id FROM framework.config WHERE viewid = OLD.id
    );*/
    
    DELETE FROM framework.filters WHERE viewid = OLD.id;
    
	DELETE FROM framework.config WHERE viewid = OLD.id and fn is not null;
	DELETE FROM framework.config WHERE viewid = OLD.id and fn is null;	
	  
    
    RETURN OLD;  

END;
$$;


ALTER FUNCTION framework.tr_views_tr_del() OWNER TO postgres;

--
-- TOC entry 411 (class 1255 OID 180033)
-- Name: tr_views_tr_ins_after(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_views_tr_ins_after() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF not NEW.copy THEN
      INSERT INTO framework.config (
        viewid, t, col, column_id, title, type,
        roles, visible, required, width,
        "join", classname, updatable,
        relation, select_api, multiselecttable,
        orderby, orderbydesc, relcol,
        depency, depencycol, relationcolums,
        multicolums, column_order, fn,
        fncolumns, relatecolumn, "table",
        related
      )
      SELECT 
        NEW.id, c.value->>'t' as t, c.value->>'col' as col, 
        (c.value->>'column_id')::INTEGER as column_id,
        c.value->>'title' as title, c.value->>'type' as type,
        
        (CASE WHEN (c.value->>'roles')::varchar like '[%'
        THEN
        json_build_array(array(SELECT
                value->'value'
           FROM json_array_elements((c.value->>'roles')::json)
        ))->0
        ELSE
            '[]'::json
        END) as roles,
         
        coalesce((c.value->>'visible' )::BOOLEAN,false) as visible,
        COALESCE((c.value->>'required')::BOOLEAN,false) as required,
        c.value->>'width' as width,
        COALESCE((c.value->>'join')::BOOLEAN,false) as join,
        c.value->>'classname' as classname,
        COALESCE((c.value->>'updatable')::BOOLEAN,false) as updatable,
        c.value->>'relation' as relation,
        c.value->>'select_api' as select_api,   
        c.value->>'multiselecttable' as multiselecttable,
        COALESCE((c.value->>'orderby')::BOOLEAN,false) as orderby,
        COALESCE((c.value->>'orderbydesc')::BOOLEAN,false) as orderbydesc,
        c.value->>'relcol' as relcol,
        COALESCE((c.value->>'depency')::BOOLEAN,false) as depency,
        c.value->>'depencycol' as depencycol,
        
        (CASE WHEN (c.value->>'relationcolums')::varchar like '[%'
        THEN
        json_build_array(array(SELECT
                value->'value'
           FROM json_array_elements((c.value->>'relationcolums')::json)
        ))->0
        ELSE
         '[]'::json
        END) as relationcolums,
         
        (CASE WHEN (c.value->>'multicolums')::varchar like '[%'
        THEN
            json_build_array(array(SELECT
                value->'value'
           FROM json_array_elements((c.value->>'multicolums')::json)
            ))->0
        ELSE
            '[]'::json
        END
        ) as multicolums,
        
        row_number() over (PARTITION BY 0) as column_order,
        (c.value->'fn')->>'value' as fn,
        
        (CASE WHEN (c.value->>'fncolumns')::varchar like '[%'
        THEN
           json_build_array(array(SELECT
                value->'value'
           FROM json_array_elements((c.value->'fncolumns')::json)
        ))->0 
        ELSE
         null
        END ) as fncolumns,
        
        c.value->>'relatecolumn',
        c.value->>'table',
        coalesce((c.value->>'related')::boolean,false)
     FROM json_array_elements(framework.fn_createconfig(json_build_object('tabname',NEW.tablename ))) as c;	
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_views_tr_ins_after() OWNER TO postgres;

--
-- TOC entry 412 (class 1255 OID 180034)
-- Name: tr_viewsnotification_del_doubles(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_viewsnotification_del_doubles() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN /*Этот  триггер удаляет дубли  сообщений по полю doublemess*/ 
  if (old.issend=false and new.issend=true and not (new.doublemess is null))  then -- если информация о том что issend изменен на получен и причем принимает участие поле doublemess
    delete from framework.viewsnotification 
    where doublemess=new.doublemess and id<>new.id;
  end if; 
  RETURN NEW;
EXCEPTION
WHEN others THEN
  RETURN NEW;
END;
$$;


ALTER FUNCTION framework.tr_viewsnotification_del_doubles() OWNER TO postgres;

--
-- TOC entry 413 (class 1255 OID 180035)
-- Name: tr_visible_condition_tr(); Type: FUNCTION; Schema: framework; Owner: postgres
--

CREATE FUNCTION tr_visible_condition_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF NEW.value is null and NEW.operation not like '%null%'
    THEN
    	PERFORM raiserror('value is null');
    END IF; 
    
	IF NEW.val_desc is null
    THEN
    	PERFORM raiserror('val_desc is null');
    END IF;     
    
    RETURN NEW;

END;
$$;


ALTER FUNCTION framework.tr_visible_condition_tr() OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 414 (class 1255 OID 180038)
-- Name: fn_completed_color(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_completed_color(c boolean, OUT color character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	color = 'red';

	IF c THEN
    	color = 'green';
    END IF;     

END;
$$;


ALTER FUNCTION public.fn_completed_color(c boolean, OUT color character varying) OWNER TO postgres;

--
-- TOC entry 415 (class 1255 OID 180039)
-- Name: fn_completed_colorblack(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_completed_colorblack(t boolean, OUT c character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	c = 'black';
    IF not  t THEN
    	c = 'red';
    END IF;

END;
$$;


ALTER FUNCTION public.fn_completed_colorblack(t boolean, OUT c character varying) OWNER TO postgres;

--
-- TOC entry 416 (class 1255 OID 180040)
-- Name: fn_corect_error_view_config(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_corect_error_view_config(_id integer, OUT _result character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
  _i int;
  _act json; 
  _acts json[];
  _newact json;
BEGIN
 _result='';
 _i=0;
 FOR  _act in (select value from json_array_elements ((select acts from framework.views where  id=_id)::json) as d) 
 LOOP
  _i=_i+1;
  --_result=(concat(_result,' ',_i::varchar,'-',_act->>'title'::varchar,' ',_act->>'isforevery'::varchar,', '));
  if _act->>'isforevery' is null 
    then
     _newact=(_act::jsonb||'{"isforevery":"false"}'::jsonb)::json;
     /*_acts=row_to_json
     (
         select value from json_array_elements (_acts)
         -- union  select _newact
     );*/
     
    else   
     _newact=_act;
  end if;
 END LOOP;
 _result=_newact::varchar;
 return;
END;
$$;


ALTER FUNCTION public.fn_corect_error_view_config(_id integer, OUT _result character varying) OWNER TO postgres;

--
-- TOC entry 417 (class 1255 OID 180049)
-- Name: fn_withoutDesc_setRightFnTitle(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "fn_withoutDesc_setRightFnTitle"(_schemaname character varying, _fn_name character varying, _newschemaname character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _squery varchar;
  _nfnname varchar(500);
BEGIN

	IF _schemaname<>_newschemaname
    THEN
      _squery = CONCAT(
          'ALTER FUNCTION "',_schemaname,'"."', _fn_name,
          '"() SET SCHEMA "',_newschemaname,'";'
      );
      EXECUTE(_squery);
    END IF;
    
    


    
   --_squery = CONCAT(_squery,' SET SCHEMA ', _schemaname,' ',_newschemaname,';');
    
    
    
    IF _fn_name not like 'tr_%'
    THEN
    	_nfnname = _fn_name;
    	IF _nfnname like 'fn_%'
        THEN
        	_nfnname = replace(_fn_name,'fn_','');
        END IF;
        
        _nfnname = concat('"tr_', _nfnname,'"');
        _squery = CONCAT(
        	'ALTER FUNCTION "',_newschemaname,'"."', _fn_name,
            '"() RENAME TO ', _nfnname,';'
        );
        EXECUTE(_squery);
    END IF;
	

END;
$$;


ALTER FUNCTION public."fn_withoutDesc_setRightFnTitle"(_schemaname character varying, _fn_name character varying, _newschemaname character varying) OWNER TO postgres;

--
-- TOC entry 418 (class 1255 OID 180050)
-- Name: fn_withoutDesc_tables(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "fn_withoutDesc_tables"(_schema character varying) RETURNS TABLE(schema character varying, tablename character varying, description character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
	   t.schemaname::varchar, 
	   t.relname::varchar as table,
	   COALESCE(p.description,'НЕТ ОПИСАНИЯ')::varchar as desc
  FROM pg_catalog.pg_statio_all_tables as t
	  LEFT JOIN pg_catalog.pg_description as p on p.objoid = t.relid
  WHERE t.schemaname = _schema and (COALESCE(p.description,'') = '' OR
		p.description = 'НЕТ ОПИСАНИЯ');

END;
$$;


ALTER FUNCTION public."fn_withoutDesc_tables"(_schema character varying) OWNER TO postgres;

--
-- TOC entry 3140 (class 0 OID 0)
-- Dependencies: 418
-- Name: FUNCTION "fn_withoutDesc_tables"(_schema character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION "fn_withoutDesc_tables"(_schema character varying) IS 'ТАБЛИЦЫ БЕЗ ОПИСАНИЙ';


--
-- TOC entry 419 (class 1255 OID 180051)
-- Name: fn_withoutDesc_triggers(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "fn_withoutDesc_triggers"(_schemaname character varying) RETURNS TABLE(tab character varying, tg_name character varying, function_shema character varying, fnresult character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
   --c.*,
      CONCAT(n.nspname,'.', c.relname)::varchar as tablename, 
      t.tgname::varchar as tg_name,
      concat(pn.nspname,'.', p.proname)::varchar as functionschema ,
      "fn_withoutDesc_setRightFnTitle"(
         pn.nspname::varchar,
         p.proname::varchar,
     	 n.nspname::varchar   
      )::varchar as fn_result
  FROM pg_trigger as t
       JOIN pg_class as c on c.oid = t.tgrelid 
       JOIN pg_namespace as n on n.oid = c.relnamespace
       JOIN pg_proc as p on p.oid = t.tgfoid
       JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE n.nspname = _schemaname and not t.tgisinternal
      AND ( n.nspname <> pn.nspname OR p.proname not like 'tr_%');
END;
$$;


ALTER FUNCTION public."fn_withoutDesc_triggers"(_schemaname character varying) OWNER TO postgres;

--
-- TOC entry 3141 (class 0 OID 0)
-- Dependencies: 419
-- Name: FUNCTION "fn_withoutDesc_triggers"(_schemaname character varying); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION "fn_withoutDesc_triggers"(_schemaname character varying) IS ' -- triggers with wrong schemas and names';


--
-- TOC entry 424 (class 1255 OID 180052)
-- Name: fn_yesorno(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_yesorno(b boolean, OUT y character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF b THEN
    	y = 'YES';
    ELSE
    	y = 'NO';
    END IF;

END;
$$;


ALTER FUNCTION public.fn_yesorno(b boolean, OUT y character varying) OWNER TO postgres;

--
-- TOC entry 420 (class 1255 OID 180053)
-- Name: isnumeric(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION isnumeric(text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
DECLARE x NUMERIC;
BEGIN
    x = $1::NUMERIC;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$_$;


ALTER FUNCTION public.isnumeric(text) OWNER TO postgres;

--
-- TOC entry 421 (class 1255 OID 180054)
-- Name: prettydate(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION prettydate(d date, OUT "do" character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	do = to_char(d,'DD.MM.YYYY'); 
END;
$$;


ALTER FUNCTION public.prettydate(d date, OUT "do" character varying) OWNER TO postgres;

--
-- TOC entry 422 (class 1255 OID 180055)
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

SET search_path = reports, pg_catalog;

--
-- TOC entry 423 (class 1255 OID 180059)
-- Name: fn_call_report(json); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION fn_call_report(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
  report_path VARCHAR(350);
  _roles json;
  _userroles json;
  _sess char(36);
  _userid char(36);
  _fn_title VARCHAR(350);  
  squery varchar;
  _template_path varchar(300);
BEGIN
  report_path = injson->>'report_path';
  _sess =injson->>'sess';
  injson = injson->>'injson';
  
  SELECT 
  	rl.functitle,
    rl.roles,
    rl.template_path
  FROM reports.reportlist as rl
  WHERE rl.path = report_path
  INTO _fn_title, _roles, _template_path;
  
  IF _fn_title is null THEN
  	PERFORM raiserror('404');
  END IF; 
  
  SELECT
      u.id,
      u.roles
  FROM framework.users as u
      JOIN framework.sess as s on s.userid = u.id
  WHERE s.id = _sess
  INTO _userid, _userroles;
  
  IF _roles is not null and 
  	
    (SELECT count(*) FROM json_array_elements_text(_roles)) <>0
 	and 
    (SELECT count(*) FROM json_array_elements_text(_userroles)) <> 0
  THEN
 	IF (SELECT 
    		count(*) 
        FROM json_array_elements_text(_userroles) as u
        	JOIN json_array_elements_text(_roles) as r on 
            	u.value::varchar::int = r.value::varchar::int) = 0
        and (
        SELECT 
    		count(*) 
        FROM json_array_elements_text(_userroles)
        WHERE value::varchar = '0') = 0
 	THEN
    	PERFORM raiserror('access denied');
    END IF;
  END IF;
  
  SELECT injson::jsonb || 
   	   (SELECT row_to_json(d) FROM (SELECT _userid as userid) as d)::jsonb
  INTO injson;

  squery = concat('
    SELECT 
       row_to_json(d) 
    FROM
       ( 
         select 
         	outjson
            
         from ',_fn_title,'($1)
       ) as d;'
    );
    
  EXECUTE format(squery) INTO outjson USING injson;
  
  outjson =  (outjson::jsonb||(SELECT row_to_json(d) FROM (
  	SELECT 
      _template_path as template_path
  ) as d)::jsonb)::jsonb;
  
  outjson = coalesce(outjson,'{}');
 
END;
$_$;


ALTER FUNCTION reports.fn_call_report(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3142 (class 0 OID 0)
-- Dependencies: 423
-- Name: FUNCTION fn_call_report(injson json, OUT outjson json); Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON FUNCTION fn_call_report(injson json, OUT outjson json) IS 'ФУНКЦИЯ ВЫЗОВА ФУНКЦИИ ОТЧЁТА';


--
-- TOC entry 425 (class 1255 OID 180062)
-- Name: fn_getmethod_info(json); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION fn_getmethod_info(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	_id int; 
BEGIN
	_id = injson->>'id';
	

	SELECT
    	row_to_json(d)
    FROM
    (SELECT
    	s.methodname,
        s.methodtype,
        mt.methotypename
    FROM framework.spapi as s
    	LEFT JOIN framework.methodtypes as mt on mt.id = s.methodtype
    WHERE s.id = _id) as d
	into outjson;
    
    outjson = coalesce(outjson,'{}');
END;
$$;


ALTER FUNCTION reports.fn_getmethod_info(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 426 (class 1255 OID 180063)
-- Name: fn_getreports_fn(json); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION fn_getreports_fn(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_substr varchar(130);
BEGIN

  _substr = injson->>'substr';	

  _substr = CONCAT('%',upper(coalesce(_substr,'%')),'%');	

  SELECT
  	array_to_json(array_agg(row_to_json(p)))
  FROM
  (SELECT 
  	format('%I.%I', ns.nspname, p.proname) as label,
    format('%I.%I', ns.nspname, p.proname) as value,
    'user' as functype 
  FROM pg_proc p 
  INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
  WHERE ns.nspname in ('reports') and  
  	upper(format('%I.%I', ns.nspname, p.proname)) like _substr ) as p
  INTO outjson;
  
  outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION reports.fn_getreports_fn(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 427 (class 1255 OID 180065)
-- Name: fn_report_copy(json); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION fn_report_copy(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _id int;
  _newid int;	
  _nw json;
BEGIN
	/* REPORT COPY (DUBLICATE) */
	_userid = injson->>'userid';
    _id = injson->>'id';
    
    _newid = nextval('reports.reportlist_id_seq'::regclass);
	
    
    INSERT INTO reports.reportlist (
      id, title, roles,
      "path", "template",
      template_path, functitle,
      section, completed, filename
    )
    SELECT
      _newid, r.title, r.roles,
      concat(r."path",'_copy'), r."template",
      r.template_path, r.functitle,
      r.section, r.completed, r.filename
    FROM reports.reportlist as r
    WHERE r.id = _id;
    
    INSERT INTO reports.reportparams (
      reportlistid, ptitle, func_paramtitle,
      ptype, apimethod, completed, orderby 
    )
    SELECT
      _newid, rp.ptitle, rp.func_paramtitle,
      rp.ptype, rp.apimethod, rp.completed, rp.orderby 
    FROM reports.reportparams as rp
    WHERE rp.reportlistid = _id;
    
    SELECT
    	row_to_json(d)
    FROM (
      SELECT r.*
      FROM reports.reportlist as r
      WHERE r.id = _id
    ) as d
    INTO _nw;
    
    INSERT INTO framework.logtable (
      tablename, tableid, opertype,
      oldata, newdata, userid
    ) VALUES (
    	'reports.reportlist', _newid, '1',
        '{}'::json, _nw, _userid
    );
END;
$$;


ALTER FUNCTION reports.fn_report_copy(injson json) OWNER TO postgres;

--
-- TOC entry 3143 (class 0 OID 0)
-- Dependencies: 427
-- Name: FUNCTION fn_report_copy(injson json); Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON FUNCTION fn_report_copy(injson json) IS 'REPORT COPY (DUBLICATE)';


--
-- TOC entry 428 (class 1255 OID 180066)
-- Name: fn_report_getone(json); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION fn_report_getone(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  _userid int;
  _id int;
  _userroles json;
  _reportroles json;
BEGIN
	_userid = injson->>'userid';
    _id = injson->>'id';
    
    SELECT
    	u.roles
    FROM framework.users as u
    WHERE u.id = _userid
	INTO _userroles;
    
	SELECT 
    	rl.roles
    FROM reports.reportlist as rl
    WHERE rl.id = _id
    INTO _reportroles;
    
    
    IF _reportroles is not null AND
    	(SELECT count(*) 
         FROM json_array_elements_text(_reportroles)) <> 0
	THEN
    	IF (SELECT count(*) 
             FROM json_array_elements_text(_reportroles) as r
                JOIN json_array_elements_text(_userroles) as ur on 
                    ur.value::varchar = r.value::varchar) = 0

    	THEN
        	PERFORM raiserror('access denied');
        END IF;                     
    END IF;
    
    SELECT 
   		row_to_json(d)
 	FROM 
	(SELECT 
    	rl.id,
        rl.filename,
        rl.template_path,
        rl.title,
        rl.path,
        COALESCE((
        SELECT 
        	array_to_json(array_agg(row_to_json(p)))
        FROM 
        (SELECT
        	rp.id,
            rp.apimethod,
            rp.func_paramtitle,
            rp.ptitle,
            rp.ptype,
            pt.typename
        FROM reports.reportparams as rp
        	LEFT JOIN reports.paramtypes as pt on pt.id = rp.ptype
        WHERE rp.reportlistid = rl.id
        	AND rp.completed
        ORDER BY rp.orderby) as p
        ),'[]') as params	
    FROM reports.reportlist as rl
    WHERE rl.id = _id and rl.completed) as d
    INTO outjson;
    
    outjson = coalesce(outjson,'{}');

END;
$$;


ALTER FUNCTION reports.fn_report_getone(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 429 (class 1255 OID 180067)
-- Name: tr_reportlist_tr(); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION tr_reportlist_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW."template" is not null THEN
    IF 
      (SELECT
          count(*)
      FROM json_array_elements_text(NEW."template"))>1 THEN
    	PERFORM raiserror('Вы пытаетесь загрузить Больше одного файла');
    END IF;  
    IF NEW."template"->0 is not null THEN
    	NEW.template_path = (NEW."template"->0)::json->>'uri';
        IF (NEW."template"->0)::json->>'filename' not like '%.xlsx' THEN
	    	PERFORM raiserror('Шаблон должен быть файлом xlsx');	
        END IF; 
    	--PERFORM raiserror('Вы пытаетесь загрузить Больше одного файла');
    END IF; 
  END IF;
  
  IF NEW.functitle is not null THEN
    IF (SELECT 
          count(*)
        FROM pg_proc p 
        INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
        WHERE ns.nspname not in ('pg_catalog','information_schema') and 
        		format('%I.%I', ns.nspname, p.proname) = NEW.functitle) = 0 THEN
	    	PERFORM raiserror('Указанная функция не найдена');	
    END IF;
  END IF; 
  
  
  NEW.filename = (NEW."template"->0)::json->>'filename';
  NEW.completed = false;
  
  IF 
  	coalesce(NEW.title,'') <>'' and
 	COALESCE(NEW."path",'')<>'' and
  	NEW.template is not null and
  	coalesce(NEW.template_path,'')<>'' and
  	coalesce(NEW.functitle,'')<>'' and
  
  	coalesce(NEW.section,'')<>'' 
    
  THEN
  	 NEW.completed = true;
  END IF;   
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION reports.tr_reportlist_tr() OWNER TO postgres;

--
-- TOC entry 439 (class 1255 OID 194771)
-- Name: tr_reportlist_tr_del(); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION tr_reportlist_tr_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM reports.reportparams WHERE reportlistid = OLD.ID;
    RETURN OLD;

END;
$$;


ALTER FUNCTION reports.tr_reportlist_tr_del() OWNER TO postgres;

--
-- TOC entry 430 (class 1255 OID 180068)
-- Name: tr_reportlist_tr_ins(); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION tr_reportlist_tr_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	NEW.title = upper(trim(NEW.title));
    NEW.path = trim(NEW.path);
    
    
    RETURN NEW;

END;
$$;


ALTER FUNCTION reports.tr_reportlist_tr_ins() OWNER TO postgres;

--
-- TOC entry 431 (class 1255 OID 180069)
-- Name: tr_reportlist_trigger(); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION tr_reportlist_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW."template" is not null THEN
    IF 
      (SELECT
          count(*)
      FROM json_array_elements_text(NEW."template"))>1 THEN
    	PERFORM raiserror('Вы пытаетесь загрузить Больше одного файла');
    END IF;  
    IF NEW."template"->0 is not null THEN
    	NEW.template_path = (NEW."template"->0)::json->>'uri';
        IF (NEW."template"->0)::json->>'filename' not like '%.xlsx' THEN
	    	PERFORM raiserror('Шаблон должен быть файлом xlsx');	
        END IF; 
    	--PERFORM raiserror('Вы пытаетесь загрузить Больше одного файла');
    END IF; 
  END IF;
  
  IF NEW.functitle is not null THEN
    IF (SELECT 
          count(*)
        FROM pg_proc p 
        INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
        WHERE ns.nspname not in ('pg_catalog','information_schema') and 
        		format('%I.%I', ns.nspname, p.proname) = NEW.functitle) = 0 THEN
	    	PERFORM raiserror('Указанная функция не найдена');	
    END IF;
  END IF; 
  
  
  NEW.filename = (NEW."template"->0)::json->>'filename';
  NEW.completed = false;
  
  IF 
  	coalesce(NEW.title,'') <>'' and
 	COALESCE(NEW."path",'')<>'' and
  	NEW.template is not null and
  	coalesce(NEW.template_path,'')<>'' and
  	coalesce(NEW.functitle,'')<>'' and
  
  	coalesce(NEW.section,'')<>'' 
    
  THEN
  	 NEW.completed = true;
  END IF;   
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION reports.tr_reportlist_trigger() OWNER TO postgres;

--
-- TOC entry 432 (class 1255 OID 180070)
-- Name: tr_reportparams_tr(); Type: FUNCTION; Schema: reports; Owner: postgres
--

CREATE FUNCTION tr_reportparams_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	NEW.completed = false;

  IF NEW.reportlistid is not null and
  	 coalesce(NEW.ptitle,'') <> '' and
  	 coalesce(NEW.func_paramtitle,'')<>'' and
  	 NEW.ptype is not null 
  THEN
  	NEW.completed = true;
  	IF NEW.ptype in (2,3,5) and NEW.apimethod is null THEN
    	NEW.completed = false;
    END IF;
  END IF; 
  
  RETURN NEW;

END;
$$;


ALTER FUNCTION reports.tr_reportparams_tr() OWNER TO postgres;

SET search_path = test, pg_catalog;

--
-- TOC entry 440 (class 1255 OID 194840)
-- Name: fn_act_visible_conditions_intable(json, integer, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_act_visible_conditions_intable(_vs json, act_id integer, INOUT _vid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
  INSERT INTO framework.act_visible_condions (
    actionid,
    val_desc,
    col,
    title,
    operation,
    value
  )
  SELECT
  	act_id,
    (SELECT
       	c.id
     FROM framework.config as c
     WHERE c.viewid = _vid and c.title = (value->'col')->>'value'
    ) as val_desc,
    (v.value->'col')->>'col' as col,
    (v.value->'col')->>'title' as title,
    (v.value->'operation')->>'value' as operation,
    v.value->>'value'
  FROM json_array_elements(_vs) as v;

END;
$$;


ALTER FUNCTION test.fn_act_visible_conditions_intable(_vs json, act_id integer, INOUT _vid integer) OWNER TO postgres;

--
-- TOC entry 3144 (class 0 OID 0)
-- Dependencies: 440
-- Name: FUNCTION fn_act_visible_conditions_intable(_vs json, act_id integer, INOUT _vid integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_act_visible_conditions_intable(_vs json, act_id integer, INOUT _vid integer) IS 'ins act vis conditions from json (table views) into table';


--
-- TOC entry 435 (class 1255 OID 194841)
-- Name: fn_actions_in_table(json, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_actions_in_table(_actions json, INOUT _vid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_kl json;
BEGIN

	INSERT INTO framework.actions (
      column_order,
      viewid, classname, title,
      icon, act_url ,
      api_method ,
      api_type ,
      refresh_data ,
      ask_confirm ,
      roles ,
      forevery ,
      main_action ,
      act_type 
    )
	SELECT
      row_number() over (PARTITION BY 0) as column_order,
      _vid, value->>'classname' as classname, value->>'title' as title,
	  value->>'icon' as icon, value->>'act' as act,
      value->>'actapimethod' as api_method,
      lower(value->>'actapitype') as api_type,
      COALESCE((value->>'actapirefresh')::boolean,FALSE) as refresh_data,
      COALESCE((value->>'actapiconfirm')::boolean,FALSE) as ask_confirm,
      
      json_build_array(array(SELECT
             value->'value'
      	FROM json_array_elements((value->'roles')::json)
      ))->0 as roles,
      
      COALESCE((value->>'isforevery')::boolean,FALSE) as forevery,
      COALESCE((value->>'ismain')::boolean,FALSE) as main_action,
	  value->>'type' as type
    FROM json_array_elements(_actions);
    
    SELECT
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (SELECT
    	test.fn_parametrs_intotables(  
       	  value->'parametrs',
          _vid,
           c.id
        ),
        test.fn_act_visible_conditions_intable(
       	  value->'act_visible_condition',
          c.id,
          _vid  
        )
    FROM json_array_elements(_actions) as a
    	JOIN framework.actions as c on c.viewid = _vid and 
        	c.title = value->>'title') as d
    INTO _kl;
    
    
    
	/*
	[
       {
          "act": "/", 
          "icon": "fa fa-check", 
          "type": "Save", 
          "title": "save", 
          "classname": "p-button-success", 
          "parametrs": [], 
          "isforevery": false, 
          "act_visible_condition": [{
              "col": {
                  "t": 1, 
                  "key": "id_99ad9", 
                  "label": "id", 
                  "value": "vs_id"
              },
              "value": "-1", 
              "operation": {
                  "js": ">", 
                  "label": ">", 
                  "value": ">", 
                  "python": ">"
              }}
          ]
       }, 
       {
         "act": "/composition/act_visible_conditions", 
         "icon": "fa fa-cros",
         "type": "Link", 
         "title": "close", 
         "parametrs": [{
              "paramt": null, 
              "paramconst": "", 
              "paraminput": "actionid", 
              "paramtitle": "actionid", 
              "paramcolumn": null
           }, 
           {
              "paramt": null, 
              "paramconst": "actionid", 
              "paraminput": "", 
              "paramtitle": "relation", 
              "paramcolumn": null
           }, 
           {
              "paramt": null, 
              "paramconst": "-1", 
              "paraminput": "", 
              "paramtitle": "vs_id", 
              "paramcolumn": null
           }, 
           {
              "paramt": null, 
              "paramconst": "", 
              "paraminput": "act_id", 
              "paramtitle": "act_id", 
              "paramcolumn": null
           }
         ], 
         "isforevery": false, 
         "act_visible_condition": [
         	{
            	"col": {
            		"t": 1, 
                    "key": "id_99ad9", 
                	"label": "id", 
                	"value": "vs_id"
            	}, 
         		"const": null, 
            	"value": "-1", 
            	"operation": {
            		"js": ">", 
                	"label": ">", 
                	"value": ">", 
                	"python": ">"
            	}
            }
         ]
   	   }
     ]    
     
	[
        {
        	"act": "/api/postmethodtest_setselectedcolor_black", 
            "type": "API", 
            "title": "set checke black (POST TEST CHECKED)", 
            "parametrs": [
            	{
                	"paramt": null, 
                    "paramconst": "_checked_", 
                    "paraminput": "", 
                    "paramtitle": "checked", 
                    "paramcolumn": null
                }
            ], 
            "actapitype": "POST", 
            "isforevery": false, 
            "actapiconfirm": true, 
            "actapirefresh": true
        }
    ]
    
    */

END;
$$;


ALTER FUNCTION test.fn_actions_in_table(_actions json, INOUT _vid integer) OWNER TO postgres;

--
-- TOC entry 3145 (class 0 OID 0)
-- Dependencies: 435
-- Name: FUNCTION fn_actions_in_table(_actions json, INOUT _vid integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_actions_in_table(_actions json, INOUT _vid integer) IS 'ins actions from json (table views) into table';


--
-- TOC entry 436 (class 1255 OID 194842)
-- Name: fn_config_in_table(json, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_config_in_table(_config json, INOUT _viewid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
--insert all configs in tables
DECLARE 
	mock_json json;
BEGIN
  INSERT INTO framework.config (
    viewid, t, col ,
    column_id ,
    title , type ,
    roles ,
    visible ,
    required ,
    width ,
    "join" ,
    classname ,
    updatable ,
    relation ,
    select_api ,
    multiselecttable ,
    orderby ,
    orderbydesc ,
    relcol ,
    depency ,
    depencycol ,
    relationcolums ,
    multicolums ,
    column_order ,
    fn ,
    fncolumns,
    relatecolumn,
    "table",
    related
  )

  SELECT 
	_viewid, c.value->>'t' as t, c.value->>'col' as col,
    (c.value->>'column_id')::INTEGER as column_id,
    c.value->>'title' as title, c.value->>'type' as type,
    
    (CASE WHEN (c.value->>'roles')::varchar like '[%'
    THEN
    json_build_array(array(SELECT
    		value->'value'
       FROM json_array_elements((c.value->>'roles')::json)
    ))->0
    ELSE
    	'[]'::json
    END)
     as roles,
    
    coalesce((c.value->>'visible' )::BOOLEAN,false) as visible,
    COALESCE((c.value->>'required')::BOOLEAN,false) as required,
    c.value->>'width' as width,
    COALESCE((c.value->>'join')::BOOLEAN,false) as join,
    c.value->>'classname' as classname,
    COALESCE((c.value->>'updatable')::BOOLEAN,false) as updatable,
    c.value->>'relation' as relation,
    c.value->>'select_api' as select_api,   
	c.value->>'multiselecttable' as multiselecttable,
    COALESCE((c.value->>'orderby')::BOOLEAN,false) as orderby,
    COALESCE((c.value->>'orderbydesc')::BOOLEAN,false) as orderbydesc,
    c.value->>'relcol' as relcol,
    COALESCE((c.value->>'depency')::BOOLEAN,false) as depency,
    c.value->>'depencycol' as depencycol,
    
    (CASE WHEN (c.value->>'relationcolums')::varchar like '[%'
    THEN
    json_build_array(array(SELECT
    		value->'value'
       FROM json_array_elements((c.value->>'relationcolums')::json)
    ))->0
    ELSE
   	 '[]'::json
    END)
     as relationcolums,
     
    (CASE WHEN (c.value->>'multicolums')::varchar like '[%'
    THEN
    	json_build_array(array(SELECT
    		value->'value'
       FROM json_array_elements((c.value->>'multicolums')::json)
   		))->0
    ELSE
    	'[]'::json
    END
    ) as multicolums,
    
    row_number() over (PARTITION BY 0) as column_order,
    (c.value->'fn')->>'value' as fn,
    
    (CASE WHEN (c.value->>'fncolumns')::varchar like '[%'
    THEN
    json_build_array(array(SELECT
    		value->'value'
       FROM json_array_elements((c.value->'fncolumns')::json)
    ))->0 
    ELSE
   	 null
    END ) as fncolumns,
    c.value->>'relatecolumn',
    c.value->>'table',
    coalesce((c.value->>'related')::boolean,false)
 FROM json_array_elements(_config) as c;


  SELECT
  	array_to_json(array_agg(row_to_json(d))) 
  FROM
  (SELECT 
    c.value->>'title' as title,
    test.fn_visible_condition_intable(cn.id, (c.value->'visible_condition')) as vc,
    test.fn_select_condition_intable(cn.id,(c.value->'select_condition')) as sc,
    test.fn_defaultval_intable(cn.id,(c.value->'defaultval')) as dv
 FROM json_array_elements(_config) as c
 	JOIN framework.config as cn on cn.title = c.value->>'title'
 WHERE cn.viewid = _viewid) as d
 
 INTO mock_json
 ;  	
END;
$$;


ALTER FUNCTION test.fn_config_in_table(_config json, INOUT _viewid integer) OWNER TO postgres;

--
-- TOC entry 3146 (class 0 OID 0)
-- Dependencies: 436
-- Name: FUNCTION fn_config_in_table(_config json, INOUT _viewid integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_config_in_table(_config json, INOUT _viewid integer) IS 'ins config from json (table views) into table';


--
-- TOC entry 437 (class 1255 OID 194843)
-- Name: fn_config_in_table_fncolumns_fix(json, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_config_in_table_fncolumns_fix(_config json, INOUT _viewid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
-- update all configs , fix fncolumns
DECLARE 
	mock_json json;
BEGIN

  UPDATE framework.config as cc
  SET fncolumns =   
    (CASE WHEN (c.value->>'fncolumns')::varchar like '[%'
    THEN
    	json_build_array(array(SELECT
    		ccc.id
       FROM json_array_elements((c.value->'fncolumns')::json) as n
         JOIN framework.config as ccc on (ccc.title = (value->>'value')) and ccc.viewid = _viewid
    ))->0 
    ELSE
   	 null
    END ) 
 FROM json_array_elements(_config) as c
 WHERE c.value->>'title' = cc.title and cc.viewid = _viewid and 
  ((c.value->'fn')->>'value') is not null ;
 	
END;
$$;


ALTER FUNCTION test.fn_config_in_table_fncolumns_fix(_config json, INOUT _viewid integer) OWNER TO postgres;

--
-- TOC entry 3147 (class 0 OID 0)
-- Dependencies: 437
-- Name: FUNCTION fn_config_in_table_fncolumns_fix(_config json, INOUT _viewid integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_config_in_table_fncolumns_fix(_config json, INOUT _viewid integer) IS 'ins config fn cols from json (table views) into table';


--
-- TOC entry 441 (class 1255 OID 194844)
-- Name: fn_config_in_table_tpath_fix(json, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_config_in_table_tpath_fix(_config json, INOUT _viewid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
-- update all configs , fix fncolumns
DECLARE 
	mock_json json;
BEGIN

 UPDATE framework.config as cc
  SET tpath = coalesce(c.value->'tpath','[]')
 FROM json_array_elements(_config) as c
 WHERE c.value->>'title' = cc.title and cc.viewid = _viewid;
 	
END;
$$;


ALTER FUNCTION test.fn_config_in_table_tpath_fix(_config json, INOUT _viewid integer) OWNER TO postgres;

--
-- TOC entry 3148 (class 0 OID 0)
-- Dependencies: 441
-- Name: FUNCTION fn_config_in_table_tpath_fix(_config json, INOUT _viewid integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_config_in_table_tpath_fix(_config json, INOUT _viewid integer) IS 'ins config tpath from json (table views) into table';


--
-- TOC entry 333 (class 1255 OID 194845)
-- Name: fn_defaultval_intable(integer, json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_defaultval_intable(INOUT _colid integer, _dv json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- put defaultval from json to table 

  /*[{"act": {"label": "=", "value": "="}, 
  "bool": {"label": "and", "value": "and"}, 
  "value": "_orgid_"}]*/
  IF _colid is not null and _dv::varchar like '[%' THEN
    INSERT INTO framework.defaultval(
      configid,
      act,
      bool,
      value 
    )
    SELECT 
    	_colid,
        (v.value->'act')->>'label',
        (v.value->'bool')->>'label',
        v.value ->> 'value'
    FROM json_array_elements(_dv) as v;
  END IF;

END;
$$;


ALTER FUNCTION test.fn_defaultval_intable(INOUT _colid integer, _dv json) OWNER TO postgres;

--
-- TOC entry 3149 (class 0 OID 0)
-- Dependencies: 333
-- Name: FUNCTION fn_defaultval_intable(INOUT _colid integer, _dv json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_defaultval_intable(INOUT _colid integer, _dv json) IS 'put defaultval from json to table ';


--
-- TOC entry 442 (class 1255 OID 194846)
-- Name: fn_filters_in_table(json, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_filters_in_table(filtrs json, INOUT _vid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN

	INSERT INTO framework.filters (
      column_order, 
      viewid, classname, title,
      "column",
      columns,
      t, roles, "type", "table" 
    )
	SELECT
    	 row_number() over (PARTITION BY 0) as column_order,
    	_vid, value->>'classname' as classname, value->>'title' as title,
        (CASE WHEN (value->>'column')::varchar not like '[%'
          THEN 
          (value->>'column')::varchar
          ELSE 
          null
        END) as column,
        (CASE WHEN (value->>'column')::varchar like '[%'
          THEN 
            json_build_array(array(SELECT
                value->'value'
            FROM json_array_elements((value->>'column')::json)
            ))->0
		  ELSE 
          '[]'::json
        END) as columns,
        value->>'t', 
        json_build_array(array(SELECT
            value->'value'
        FROM json_array_elements(value->'roles')
        ))->0, value->>'type', coalesce(value->'table','{}')
   FROM json_array_elements(filtrs);

	

END;
$$;


ALTER FUNCTION test.fn_filters_in_table(filtrs json, INOUT _vid integer) OWNER TO postgres;

--
-- TOC entry 3150 (class 0 OID 0)
-- Dependencies: 442
-- Name: FUNCTION fn_filters_in_table(filtrs json, INOUT _vid integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_filters_in_table(filtrs json, INOUT _vid integer) IS 'ins filters from json (table views) into table';


--
-- TOC entry 443 (class 1255 OID 194847)
-- Name: fn_getmethodtest_setcolorblack(json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_getmethodtest_setcolorblack(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	_id int;
BEGIN
	/*
      TEST GET API METHOD 
      CHANGE test.major_table
      colorpicker COLOR    
    */
	
	_id = injson->>'id';
    
    IF _id is null THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    UPDATE test.major_table
    SET colorpicker = 'ff0000'
    WHERE id = _id;



END;
$$;


ALTER FUNCTION test.fn_getmethodtest_setcolorblack(injson json) OWNER TO postgres;

--
-- TOC entry 3151 (class 0 OID 0)
-- Dependencies: 443
-- Name: FUNCTION fn_getmethodtest_setcolorblack(injson json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_getmethodtest_setcolorblack(injson json) IS 'TEST GET API METHOD 
CHANGE test.major_table
colorpicker COLOR';


--
-- TOC entry 444 (class 1255 OID 194848)
-- Name: fn_gettest_setallcolor_red(json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_gettest_setallcolor_red(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _id int;
BEGIN

	_id = injson->>'id';
    
    UPDATE test.major_table
    SET color = 'red';

END;
$$;


ALTER FUNCTION test.fn_gettest_setallcolor_red(injson json) OWNER TO postgres;

--
-- TOC entry 3152 (class 0 OID 0)
-- Dependencies: 444
-- Name: FUNCTION fn_gettest_setallcolor_red(injson json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_gettest_setallcolor_red(injson json) IS 'set color red for test action in view';


--
-- TOC entry 445 (class 1255 OID 194849)
-- Name: fn_parametrs_intotables(json, integer, integer); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_parametrs_intotables(_params json, vi_id integer, INOUT act_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/*DECLARE
  variable_name datatype;*/
BEGIN
    INSERT INTO framework.act_parametrs (
      actionid,
      paramtitle,
      paramt,
      paramconst,
      paraminput,
      paramcolumn,
      val_desc
    ) 
    SELECT 
    	act_id,
        value->>'paramtitle' as paramtitle,
        value->>'paramt' as paramt,
        value->>'paramconst' as paramconst,
        value->>'paraminput' as paraminput,
        (value->'paramcolumn')->>'value' as paramcolumn,
        (
        SELECT
        	c.id
        FROM framework.config as c
        WHERE c.viewid = vi_id and c.title = (value->'paramcolumn')->>'value'
        ) as val_desc
    FROM json_array_elements(_params) as p;
    
    /*
		"paramt": null, 
        "paramconst": "", 
        "paraminput": "actionid", 
        "paramtitle": "actionid", 
        "paramcolumn": null
    */
END;
$$;


ALTER FUNCTION test.fn_parametrs_intotables(_params json, vi_id integer, INOUT act_id integer) OWNER TO postgres;

--
-- TOC entry 3153 (class 0 OID 0)
-- Dependencies: 445
-- Name: FUNCTION fn_parametrs_intotables(_params json, vi_id integer, INOUT act_id integer); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_parametrs_intotables(_params json, vi_id integer, INOUT act_id integer) IS 'ins acts params from json (table views) into table';


--
-- TOC entry 446 (class 1255 OID 194850)
-- Name: fn_postmethodtest_setcolorblue(json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_postmethodtest_setcolorblue(injson json) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	_id int;
BEGIN
	/*
      TEST POST API METHOD 
      CHANGE test.major_table
      colorpicker COLOR    
    */
	
	_id = injson->>'id';
    
    IF _id is null THEN
    	PERFORM raiserror('id is null');
    END IF;
    
    UPDATE test.major_table
    SET colorpicker = '2f00ff'
    WHERE id = _id;



END;
$$;


ALTER FUNCTION test.fn_postmethodtest_setcolorblue(injson json) OWNER TO postgres;

--
-- TOC entry 3154 (class 0 OID 0)
-- Dependencies: 446
-- Name: FUNCTION fn_postmethodtest_setcolorblue(injson json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_postmethodtest_setcolorblue(injson json) IS 'TEST POST API METHOD 
CHANGE test.major_table
colorpicker COLOR    ';


--
-- TOC entry 447 (class 1255 OID 194851)
-- Name: fn_select_api(json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_select_api(injson json, OUT outjson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
/*
	function must have input variable "injson" type of JSON
    and out variable "outjson" type of JSON,
    objects array with label,value keys
*/
DECLARE 
	_substr varchar(150);
    _data json; -- from data  
    _inputs json; -- query params

BEGIN
	_substr = injson->>'substr';
    _data = injson->'data';
    _inputs = injson->'inputs';
    
    
    _substr = concat('%',lower(_substr),'%');

	SElECT
    	array_to_json(array_agg(row_to_json(f))) 
    FROM
    (SELECT 
    	d.id as value,
        d.dname as label
    FROM test.dictionary_for_select as d
    WHERE lower(d.dname) like _substr OR 
    	  d.id::varchar like _substr -- there must be "id" too
    ) as f
	INTO outjson;
    
    outjson = coalesce(outjson,'[]');
END;
$$;


ALTER FUNCTION test.fn_select_api(injson json, OUT outjson json) OWNER TO postgres;

--
-- TOC entry 3155 (class 0 OID 0)
-- Dependencies: 447
-- Name: FUNCTION fn_select_api(injson json, OUT outjson json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_select_api(injson json, OUT outjson json) IS 'test select_api type';


--
-- TOC entry 448 (class 1255 OID 194852)
-- Name: fn_select_condition_intable(integer, json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_select_condition_intable(INOUT _colid integer, _sc json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- put visible_condition from json to table 

  /*[{"col": {"label": "treesid", "value": "treesid"}, "value": {"t": 1, "key":
  "treesid_9766c", "label": "treesid", "value": "treesid"}, "operation": {"js":
  "===", "label": "=", "value": "=", "python": "=="}}, {"col": {"label": "id",
  "value": "id"}, "value": {"t": 1, "key": "id_512cb", "label": "id", "value":
  "bid"}, "operation": {"js": "!==", "label": "!=", "value": "<>", "python":
  "!="}}]
  */
   IF _colid is not null and _sc::varchar like '[%' THEN
     INSERT INTO framework.select_condition (
        configid,
        col ,
        operation ,
        const,
        value,
        val_desc 
      )
      SELECT
          _colid,
          (v.value->'col')->>'label',
          (v.value->'operation')->>'value',
          v.value->>'const',
          v.value->>'value',
          (SELECT
              c.id
           FROM framework.config as c
           WHERE c.title = ((v.value->'value')->>'value')
           and c.col = ((v.value->'value')->>'label')
           LIMIT 1)
          
          
      FROM json_array_elements(_sc) as v;
    END IF;
    
END;
$$;


ALTER FUNCTION test.fn_select_condition_intable(INOUT _colid integer, _sc json) OWNER TO postgres;

--
-- TOC entry 3156 (class 0 OID 0)
-- Dependencies: 448
-- Name: FUNCTION fn_select_condition_intable(INOUT _colid integer, _sc json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_select_condition_intable(INOUT _colid integer, _sc json) IS 'put visible_condition from json to table ';


--
-- TOC entry 449 (class 1255 OID 194853)
-- Name: fn_setParamsKey(json, jsonb); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION "fn_setParamsKey"(conf json, INOUT paramcol jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
BEGIN

   

   	IF paramcol is not null THEN
     SELECT	
       paramcol::jsonb
            || 
       coalesce(jsonb_build_object('key', (
          SELECT
            c.value->>'key'
          FROM json_array_elements(conf) as c
          WHERE c.value->>'title' = (paramcol)->>'value'
        )),'{}')
     INTO paramcol;
    END IF;

END;
$$;


ALTER FUNCTION test."fn_setParamsKey"(conf json, INOUT paramcol jsonb) OWNER TO postgres;

--
-- TOC entry 3157 (class 0 OID 0)
-- Dependencies: 449
-- Name: FUNCTION "fn_setParamsKey"(conf json, INOUT paramcol jsonb); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION "fn_setParamsKey"(conf json, INOUT paramcol jsonb) IS 'set keys in params into json';


--
-- TOC entry 450 (class 1255 OID 194854)
-- Name: fn_views_in_table(); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_views_in_table() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE	
	x json;
BEGIN
	-- put views data in tables
	SELECT 
    	array_to_json(array_agg(row_to_json(d)))
    FROM
    (
    SELECT
    	test.fn_config_in_table(v.config, v.id) as f,
        test.fn_filters_in_table(v.filters, v.id) as k,
        test.fn_actions_in_table(v.acts, v.id) as a
    FROM framework.views as v
    WHERE v.id in (118,119,120,121)
    ) as d
    INTO x;
    
    
    
   -- INTO x;


END;
$$;


ALTER FUNCTION test.fn_views_in_table() OWNER TO postgres;

--
-- TOC entry 3158 (class 0 OID 0)
-- Dependencies: 450
-- Name: FUNCTION fn_views_in_table(); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_views_in_table() IS 'put views data in tables';


--
-- TOC entry 452 (class 1255 OID 194855)
-- Name: fn_visible_condition_intable(integer, json); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION fn_visible_condition_intable(INOUT _colid integer, _vs json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_viewid int;
BEGIN
  -- put visible_condition from json to table 

  /*[{"col": {"t": 1, "label": "id", "value": "bid"}, 
  		"value": "-1",
  	 "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]*/
   IF _colid is not null and _vs::varchar like '[%' THEN
   	 SELECT
     	c.viewid
     FROM framework.config as c
     WHERE c.id = _colid
     INTO _viewid;	
 
     INSERT INTO framework.visible_condition (
        configid,
        col ,
        operation ,
        value,
        val_desc
      )
      SELECT
          _colid,
          (v.value->'col')->>'label',
          (v.value->'operation')->>'value',
          v.value->>'value',
          (SELECT
              c.id
           FROM framework.config as c
           WHERE c.title = ((v.value->'col')->>'value')
           and c.col = ((v.value->'col')->>'label')
           LIMIT 1)
      FROM json_array_elements(_vs) as v;
    END IF;
    
END;
$$;


ALTER FUNCTION test.fn_visible_condition_intable(INOUT _colid integer, _vs json) OWNER TO postgres;

--
-- TOC entry 3159 (class 0 OID 0)
-- Dependencies: 452
-- Name: FUNCTION fn_visible_condition_intable(INOUT _colid integer, _vs json); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION fn_visible_condition_intable(INOUT _colid integer, _vs json) IS 'put visible_condition from json to table ';


--
-- TOC entry 453 (class 1255 OID 194856)
-- Name: tr_major_table_tr(); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION tr_major_table_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	NEW.gallery = NEW.images;
    NEW.color = NEW.colorpicker;
    NEW.colorrow = NEW.colorpicker;
    IF NEW.colorpicker is not null and NEW.colorpicker not like '#%'
    THEN
    	NEW.color = concat('#',NEW.color);
    	NEW.colorrow = concat('#',NEW.colorrow);
    END IF;
    NEW.link = json_build_object('title', NEW.text, 'link', concat('/view/',NEW.number));
    NEW.label = NEW.text;
    NEW.html = NEW.texteditor;
    RETURN NEW;

END;
$$;


ALTER FUNCTION test.tr_major_table_tr() OWNER TO postgres;

--
-- TOC entry 3160 (class 0 OID 0)
-- Dependencies: 453
-- Name: FUNCTION tr_major_table_tr(); Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON FUNCTION tr_major_table_tr() IS 'test major table trigger';


SET search_path = framework, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 185 (class 1259 OID 180071)
-- Name: act_parametrs; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE act_parametrs (
    id integer NOT NULL,
    actionid integer NOT NULL,
    paramtitle character varying(350),
    paramt character varying(50),
    paramconst character varying(350),
    paraminput character varying(350),
    paramcolumn character varying(350),
    val_desc integer,
    query_type character varying(25) DEFAULT 'query'::character varying NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    "order by" integer
);


ALTER TABLE act_parametrs OWNER TO postgres;

--
-- TOC entry 3161 (class 0 OID 0)
-- Dependencies: 185
-- Name: TABLE act_parametrs; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE act_parametrs IS 'ACTIONS PARAMETERS';


--
-- TOC entry 186 (class 1259 OID 180079)
-- Name: act_parametrs_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE act_parametrs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE act_parametrs_id_seq OWNER TO postgres;

--
-- TOC entry 3162 (class 0 OID 0)
-- Dependencies: 186
-- Name: act_parametrs_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE act_parametrs_id_seq OWNED BY act_parametrs.id;


--
-- TOC entry 187 (class 1259 OID 180081)
-- Name: act_visible_condions; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE act_visible_condions (
    id integer NOT NULL,
    actionid integer NOT NULL,
    val_desc integer,
    col character varying(350),
    title character varying(350),
    operation character varying(30),
    value character varying(350),
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE act_visible_condions OWNER TO postgres;

--
-- TOC entry 3163 (class 0 OID 0)
-- Dependencies: 187
-- Name: TABLE act_visible_condions; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE act_visible_condions IS 'action visible condition';


--
-- TOC entry 3164 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN act_visible_condions.val_desc; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN act_visible_condions.val_desc IS 'column id in config';


--
-- TOC entry 3165 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN act_visible_condions.operation; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN act_visible_condions.operation IS 'bool operation ';


--
-- TOC entry 3166 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN act_visible_condions.value; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN act_visible_condions.value IS 'const value';


--
-- TOC entry 188 (class 1259 OID 180088)
-- Name: act_visible_condions_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE act_visible_condions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE act_visible_condions_id_seq OWNER TO postgres;

--
-- TOC entry 3167 (class 0 OID 0)
-- Dependencies: 188
-- Name: act_visible_condions_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE act_visible_condions_id_seq OWNED BY act_visible_condions.id;


--
-- TOC entry 189 (class 1259 OID 180090)
-- Name: actions; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE actions (
    id integer NOT NULL,
    column_order integer DEFAULT 0 NOT NULL,
    title character varying(350),
    viewid integer NOT NULL,
    icon character varying(100),
    classname character varying(350),
    act_url character varying(400),
    api_method character varying(25),
    api_type character varying(15),
    refresh_data boolean DEFAULT false NOT NULL,
    ask_confirm boolean DEFAULT false NOT NULL,
    roles json DEFAULT '[]'::json NOT NULL,
    forevery boolean DEFAULT false NOT NULL,
    main_action boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    act_type character varying(50) NOT NULL
);


ALTER TABLE actions OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 180103)
-- Name: actions_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE actions_id_seq OWNER TO postgres;

--
-- TOC entry 3168 (class 0 OID 0)
-- Dependencies: 190
-- Name: actions_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE actions_id_seq OWNED BY actions.id;


--
-- TOC entry 191 (class 1259 OID 180105)
-- Name: actparam_querytypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE actparam_querytypes (
    id smallint NOT NULL,
    aqname character varying(50) NOT NULL
);


ALTER TABLE actparam_querytypes OWNER TO postgres;

--
-- TOC entry 3169 (class 0 OID 0)
-- Dependencies: 191
-- Name: TABLE actparam_querytypes; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE actparam_querytypes IS 'action''s parametrs query types';


--
-- TOC entry 192 (class 1259 OID 180108)
-- Name: actparam_querytypes_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE actparam_querytypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE actparam_querytypes_id_seq OWNER TO postgres;

--
-- TOC entry 3170 (class 0 OID 0)
-- Dependencies: 192
-- Name: actparam_querytypes_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE actparam_querytypes_id_seq OWNED BY actparam_querytypes.id;


--
-- TOC entry 193 (class 1259 OID 180110)
-- Name: acttypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE acttypes (
    id smallint NOT NULL,
    actname character varying(150) NOT NULL,
    viewtypes json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE acttypes OWNER TO postgres;

--
-- TOC entry 194 (class 1259 OID 180117)
-- Name: apicallingmethods; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE apicallingmethods (
    id smallint NOT NULL,
    aname character varying(150) NOT NULL
);


ALTER TABLE apicallingmethods OWNER TO postgres;

--
-- TOC entry 3171 (class 0 OID 0)
-- Dependencies: 194
-- Name: TABLE apicallingmethods; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE apicallingmethods IS 'API calling methods
for user methods';


--
-- TOC entry 195 (class 1259 OID 180120)
-- Name: apicallingmethods_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE apicallingmethods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apicallingmethods_id_seq OWNER TO postgres;

--
-- TOC entry 3172 (class 0 OID 0)
-- Dependencies: 195
-- Name: apicallingmethods_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE apicallingmethods_id_seq OWNED BY apicallingmethods.id;


--
-- TOC entry 196 (class 1259 OID 180122)
-- Name: apimethods; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE apimethods (
    id smallint NOT NULL,
    val character varying(150) NOT NULL,
    created timestamp(0) without time zone DEFAULT now()
);


ALTER TABLE apimethods OWNER TO postgres;

--
-- TOC entry 3173 (class 0 OID 0)
-- Dependencies: 196
-- Name: TABLE apimethods; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE apimethods IS 'Different implementations of API calls
Along with the type, a method must be added on the interface (front-end)';


--
-- TOC entry 197 (class 1259 OID 180126)
-- Name: booloper; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE booloper (
    id smallint NOT NULL,
    bname character varying(5) NOT NULL
);


ALTER TABLE booloper OWNER TO postgres;

--
-- TOC entry 3174 (class 0 OID 0)
-- Dependencies: 197
-- Name: TABLE booloper; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE booloper IS 'boolean operations';


--
-- TOC entry 198 (class 1259 OID 180129)
-- Name: booloper_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE booloper_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE booloper_id_seq OWNER TO postgres;

--
-- TOC entry 3175 (class 0 OID 0)
-- Dependencies: 198
-- Name: booloper_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE booloper_id_seq OWNED BY booloper.id;


--
-- TOC entry 199 (class 1259 OID 180131)
-- Name: calendar_actions; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE calendar_actions (
    id integer NOT NULL,
    type character varying(50),
    title character varying(300),
    start timestamp(0) without time zone DEFAULT now() NOT NULL,
    "end" timestamp(0) without time zone DEFAULT now() NOT NULL,
    "desc" character varying(350),
    current_day date
);


ALTER TABLE calendar_actions OWNER TO postgres;

--
-- TOC entry 3176 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN calendar_actions.title; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN calendar_actions.title IS 'title';


--
-- TOC entry 3177 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN calendar_actions.start; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN calendar_actions.start IS 'start date';


--
-- TOC entry 3178 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN calendar_actions."end"; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN calendar_actions."end" IS 'enddate';


--
-- TOC entry 3179 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN calendar_actions."desc"; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN calendar_actions."desc" IS 'description';


--
-- TOC entry 200 (class 1259 OID 180139)
-- Name: calendar_actions_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE calendar_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE calendar_actions_id_seq OWNER TO postgres;

--
-- TOC entry 3180 (class 0 OID 0)
-- Dependencies: 200
-- Name: calendar_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE calendar_actions_id_seq OWNED BY calendar_actions.id;


--
-- TOC entry 201 (class 1259 OID 180141)
-- Name: calendar_test; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE calendar_test (
    id integer NOT NULL,
    calendar_date date NOT NULL,
    month integer DEFAULT 1 NOT NULL
);


ALTER TABLE calendar_test OWNER TO postgres;

--
-- TOC entry 3181 (class 0 OID 0)
-- Dependencies: 201
-- Name: COLUMN calendar_test.calendar_date; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN calendar_test.calendar_date IS 'calendar date';


--
-- TOC entry 3182 (class 0 OID 0)
-- Dependencies: 201
-- Name: COLUMN calendar_test.month; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN calendar_test.month IS 'month';


--
-- TOC entry 202 (class 1259 OID 180145)
-- Name: calendar_test_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE calendar_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE calendar_test_id_seq OWNER TO postgres;

--
-- TOC entry 3183 (class 0 OID 0)
-- Dependencies: 202
-- Name: calendar_test_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE calendar_test_id_seq OWNED BY calendar_test.id;


--
-- TOC entry 203 (class 1259 OID 180147)
-- Name: columntypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE columntypes (
    id integer DEFAULT nextval(('framework.columntypes_id_seq'::text)::regclass) NOT NULL,
    typename character varying(100) NOT NULL,
    viewtypes json DEFAULT '["form full","form not mutable"]'::json NOT NULL
);


ALTER TABLE columntypes OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 180155)
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
-- TOC entry 205 (class 1259 OID 180157)
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
-- TOC entry 206 (class 1259 OID 180166)
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
-- TOC entry 207 (class 1259 OID 180168)
-- Name: config; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE config (
    id integer NOT NULL,
    viewid integer NOT NULL,
    t character varying(50) DEFAULT '1'::character varying,
    col character varying(200) NOT NULL,
    column_id integer,
    title character varying(300) NOT NULL,
    type character varying(100) DEFAULT 'label'::character varying NOT NULL,
    roles json DEFAULT '[]'::json NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    required boolean DEFAULT false NOT NULL,
    width character varying(40),
    "join" boolean DEFAULT false NOT NULL,
    classname character varying(150),
    updatable boolean DEFAULT false NOT NULL,
    relation character varying(150),
    select_api character varying(150),
    multiselecttable character varying(150),
    orderby boolean DEFAULT false NOT NULL,
    orderbydesc boolean DEFAULT false NOT NULL,
    relcol character varying(150),
    depency boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    relationcolums json DEFAULT '[]'::json NOT NULL,
    multicolums json DEFAULT '[]'::json NOT NULL,
    depencycol character varying(150),
    column_order smallint DEFAULT 0 NOT NULL,
    fn character varying(150),
    fncolumns json,
    relatecolumn character varying(150),
    "table" character varying(150),
    related boolean DEFAULT false NOT NULL,
    tpath json DEFAULT '[]'::json NOT NULL,
    editable boolean DEFAULT false NOT NULL,
    copy boolean DEFAULT false NOT NULL
);


ALTER TABLE config OWNER TO postgres;

--
-- TOC entry 3184 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE config; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE config IS 'view columns config';


--
-- TOC entry 3185 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.t; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.t IS 'column allias in query';


--
-- TOC entry 3186 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.col; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.col IS 'column title';


--
-- TOC entry 3187 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.column_id; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.column_id IS 'column id in db
use in createconfig function';


--
-- TOC entry 3188 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.title; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.title IS 'title';


--
-- TOC entry 3189 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.type; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.type IS 'type';


--
-- TOC entry 3190 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.roles; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.roles IS 'roles accessed to this column';


--
-- TOC entry 3191 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.visible; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.visible IS 'is required in WHERE (query)';


--
-- TOC entry 3192 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.required; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.required IS 'is required column value in WHERE';


--
-- TOC entry 3193 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.width; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.width IS 'column width CSS';


--
-- TOC entry 3194 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config."join"; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config."join" IS 'use JOIN if true
LEFT JOIN if false';


--
-- TOC entry 3195 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.classname; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.classname IS 'className CSS';


--
-- TOC entry 3196 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.updatable; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.updatable IS 'refresh data on this column change';


--
-- TOC entry 3197 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.relation; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.relation IS 'relation table';


--
-- TOC entry 3198 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.select_api; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.select_api IS 'api method path for type *_api';


--
-- TOC entry 3199 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.multiselecttable; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.multiselecttable IS 'tablename for type multiselect';


--
-- TOC entry 3200 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.orderby; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.orderby IS 'order by this column by default';


--
-- TOC entry 3201 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.orderbydesc; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.orderbydesc IS 'order by desc or asc';


--
-- TOC entry 3202 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.depency; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.depency IS 'this column is depency table';


--
-- TOC entry 3203 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.relationcolums; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.relationcolums IS 'columns for columns with relations
for typehead, select types in forms
for select filters in lists';


--
-- TOC entry 3204 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.multicolums; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.multicolums IS 'columns array for multiselect type';


--
-- TOC entry 3205 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.column_order; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.column_order IS 'column order in config';


--
-- TOC entry 3206 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.fn; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.fn IS 'function is SELECT';


--
-- TOC entry 3207 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.fncolumns; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.fncolumns IS 'Function input parametrs';


--
-- TOC entry 3208 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config."table"; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config."table" IS 'table name for related col';


--
-- TOC entry 3209 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.related; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.related IS 'is related';


--
-- TOC entry 3210 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.tpath; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.tpath IS 'join path';


--
-- TOC entry 3211 (class 0 OID 0)
-- Dependencies: 207
-- Name: COLUMN config.editable; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN config.editable IS 'is editable cell';


--
-- TOC entry 208 (class 1259 OID 180192)
-- Name: config_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE config_id_seq OWNER TO postgres;

--
-- TOC entry 3212 (class 0 OID 0)
-- Dependencies: 208
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE config_id_seq OWNED BY config.id;


--
-- TOC entry 209 (class 1259 OID 180194)
-- Name: configsettings; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE configsettings (
    id integer NOT NULL,
    sname character varying(150) NOT NULL
);


ALTER TABLE configsettings OWNER TO postgres;

--
-- TOC entry 3213 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE configsettings; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE configsettings IS 'config settings list';


--
-- TOC entry 210 (class 1259 OID 180197)
-- Name: configsettings_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE configsettings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE configsettings_id_seq OWNER TO postgres;

--
-- TOC entry 3214 (class 0 OID 0)
-- Dependencies: 210
-- Name: configsettings_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE configsettings_id_seq OWNED BY configsettings.id;


--
-- TOC entry 211 (class 1259 OID 180199)
-- Name: defaultval; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE defaultval (
    id integer NOT NULL,
    configid integer NOT NULL,
    bool character varying(5),
    act character varying(30),
    value character varying(300),
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE defaultval OWNER TO postgres;

--
-- TOC entry 3215 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE defaultval; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE defaultval IS 'defaultval on config';


--
-- TOC entry 3216 (class 0 OID 0)
-- Dependencies: 211
-- Name: COLUMN defaultval.configid; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN defaultval.configid IS 'id from config table';


--
-- TOC entry 3217 (class 0 OID 0)
-- Dependencies: 211
-- Name: COLUMN defaultval.bool; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN defaultval.bool IS 'bool operator';


--
-- TOC entry 3218 (class 0 OID 0)
-- Dependencies: 211
-- Name: COLUMN defaultval.act; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN defaultval.act IS 'action';


--
-- TOC entry 3219 (class 0 OID 0)
-- Dependencies: 211
-- Name: COLUMN defaultval.value; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN defaultval.value IS 'value';


--
-- TOC entry 212 (class 1259 OID 180203)
-- Name: defaultval_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE defaultval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE defaultval_id_seq OWNER TO postgres;

--
-- TOC entry 3220 (class 0 OID 0)
-- Dependencies: 212
-- Name: defaultval_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE defaultval_id_seq OWNED BY defaultval.id;


--
-- TOC entry 213 (class 1259 OID 180205)
-- Name: dialog_messages; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE dialog_messages (
    id integer NOT NULL,
    userid integer NOT NULL,
    message_text character varying NOT NULL,
    reply_to integer,
    forwarded_from integer,
    dialog_id integer NOT NULL,
    files json DEFAULT '[]'::json NOT NULL,
    images json DEFAULT '[]'::json NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    isread boolean DEFAULT false NOT NULL,
    isupdated boolean DEFAULT false NOT NULL,
    user_reads json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE dialog_messages OWNER TO postgres;

--
-- TOC entry 3221 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.userid; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.userid IS 'who send';


--
-- TOC entry 3222 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.message_text; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.message_text IS 'message';


--
-- TOC entry 3223 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.reply_to; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.reply_to IS 'reply to message id';


--
-- TOC entry 3224 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.forwarded_from; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.forwarded_from IS 'forward from message';


--
-- TOC entry 3225 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.dialog_id; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.dialog_id IS 'dialog';


--
-- TOC entry 3226 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.files; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.files IS 'files';


--
-- TOC entry 3227 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.images; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.images IS 'images';


--
-- TOC entry 3228 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.isread; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.isread IS 'when user read message';


--
-- TOC entry 3229 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.isupdated; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.isupdated IS 'when user update the message';


--
-- TOC entry 3230 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN dialog_messages.user_reads; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_messages.user_reads IS 'users who reads the message';


--
-- TOC entry 214 (class 1259 OID 180217)
-- Name: dialog_messages_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE dialog_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dialog_messages_id_seq OWNER TO postgres;

--
-- TOC entry 3231 (class 0 OID 0)
-- Dependencies: 214
-- Name: dialog_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE dialog_messages_id_seq OWNED BY dialog_messages.id;


--
-- TOC entry 215 (class 1259 OID 180219)
-- Name: dialog_notifications; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE dialog_notifications (
    id integer NOT NULL,
    dialog_id integer NOT NULL,
    sender_userid integer NOT NULL,
    userid integer NOT NULL,
    message_text character varying NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    issend boolean DEFAULT false NOT NULL,
    message_id integer NOT NULL
);


ALTER TABLE dialog_notifications OWNER TO postgres;

--
-- TOC entry 3232 (class 0 OID 0)
-- Dependencies: 215
-- Name: COLUMN dialog_notifications.issend; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialog_notifications.issend IS 'sended';


--
-- TOC entry 216 (class 1259 OID 180227)
-- Name: dialog_notifications_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE dialog_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dialog_notifications_id_seq OWNER TO postgres;

--
-- TOC entry 3233 (class 0 OID 0)
-- Dependencies: 216
-- Name: dialog_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE dialog_notifications_id_seq OWNED BY dialog_notifications.id;


--
-- TOC entry 217 (class 1259 OID 180229)
-- Name: dialog_statuses; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE dialog_statuses (
    id integer NOT NULL,
    sname character varying(150) NOT NULL
);


ALTER TABLE dialog_statuses OWNER TO postgres;

--
-- TOC entry 3234 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE dialog_statuses; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE dialog_statuses IS 'DIALOG STATUSES';


--
-- TOC entry 218 (class 1259 OID 180232)
-- Name: dialog_statuses_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE dialog_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dialog_statuses_id_seq OWNER TO postgres;

--
-- TOC entry 3235 (class 0 OID 0)
-- Dependencies: 218
-- Name: dialog_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE dialog_statuses_id_seq OWNED BY dialog_statuses.id;


--
-- TOC entry 219 (class 1259 OID 180234)
-- Name: dialog_types; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE dialog_types (
    id smallint NOT NULL,
    tname character varying(150) NOT NULL
);


ALTER TABLE dialog_types OWNER TO postgres;

--
-- TOC entry 3236 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE dialog_types; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE dialog_types IS 'DIALOG TYPES';


--
-- TOC entry 220 (class 1259 OID 180237)
-- Name: dialogs; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE dialogs (
    id integer NOT NULL,
    title character varying(350) NOT NULL,
    users json DEFAULT '[]'::json NOT NULL,
    dtype smallint DEFAULT '1'::smallint NOT NULL,
    userid integer NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    status smallint DEFAULT '1'::smallint NOT NULL,
    first_message json DEFAULT '{}'::json NOT NULL,
    last_message_date timestamp(0) without time zone DEFAULT now() NOT NULL,
    photo json DEFAULT '[]'::json NOT NULL,
    dialog_admins json DEFAULT '[]'::json NOT NULL,
    creator integer NOT NULL
);


ALTER TABLE dialogs OWNER TO postgres;

--
-- TOC entry 3237 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE dialogs; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE dialogs IS 'USERS CHAT DIALOGS';


--
-- TOC entry 3238 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.title; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.title IS 'title of dialog';


--
-- TOC entry 3239 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.users; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.users IS 'users of dialog';


--
-- TOC entry 3240 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.dtype; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.dtype IS 'type of dialog';


--
-- TOC entry 3241 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.userid; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.userid IS 'user who create dialog';


--
-- TOC entry 3242 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.created; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.created IS 'create date';


--
-- TOC entry 3243 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.status; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.status IS 'status of dialog';


--
-- TOC entry 3244 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.first_message; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.first_message IS 'first message in dialog';


--
-- TOC entry 3245 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.last_message_date; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.last_message_date IS 'last mesage date';


--
-- TOC entry 3246 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.photo; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.photo IS 'dialog photo
only for groups';


--
-- TOC entry 3247 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.dialog_admins; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.dialog_admins IS 'admin users';


--
-- TOC entry 3248 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN dialogs.creator; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN dialogs.creator IS 'dialog creator userid';


--
-- TOC entry 221 (class 1259 OID 180251)
-- Name: dialogs_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE dialogs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dialogs_id_seq OWNER TO postgres;

--
-- TOC entry 3249 (class 0 OID 0)
-- Dependencies: 221
-- Name: dialogs_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE dialogs_id_seq OWNED BY dialogs.id;


--
-- TOC entry 222 (class 1259 OID 180253)
-- Name: dialogs_status_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE dialogs_status_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dialogs_status_seq OWNER TO postgres;

--
-- TOC entry 3250 (class 0 OID 0)
-- Dependencies: 222
-- Name: dialogs_status_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE dialogs_status_seq OWNED BY dialogs.status;


--
-- TOC entry 223 (class 1259 OID 180255)
-- Name: filters; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE filters (
    id integer NOT NULL,
    column_order smallint DEFAULT 0 NOT NULL,
    viewid integer NOT NULL,
    title character varying(150),
    type character varying(250) NOT NULL,
    classname character varying(150),
    "column" character varying,
    columns json DEFAULT '[]'::json NOT NULL,
    roles json DEFAULT '[]'::json NOT NULL,
    t character varying(150) DEFAULT '1'::character varying,
    "table" json DEFAULT '{}'::json NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    val_desc integer
);


ALTER TABLE filters OWNER TO postgres;

--
-- TOC entry 3251 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE filters; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE filters IS 'view''s filters';


--
-- TOC entry 224 (class 1259 OID 180267)
-- Name: filters_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE filters_id_seq OWNER TO postgres;

--
-- TOC entry 3252 (class 0 OID 0)
-- Dependencies: 224
-- Name: filters_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE filters_id_seq OWNED BY filters.id;


--
-- TOC entry 225 (class 1259 OID 180269)
-- Name: filtertypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE filtertypes (
    id smallint NOT NULL,
    ftname character varying(150) NOT NULL
);


ALTER TABLE filtertypes OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 180272)
-- Name: functions; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE functions (
    id smallint NOT NULL,
    funcname character varying(15) NOT NULL,
    functype character varying(15) NOT NULL
);


ALTER TABLE functions OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 180275)
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
-- TOC entry 228 (class 1259 OID 180283)
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
-- TOC entry 229 (class 1259 OID 180285)
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
    icon character varying(150),
    menuid integer NOT NULL
);


ALTER TABLE mainmenu OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 180296)
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
-- TOC entry 3253 (class 0 OID 0)
-- Dependencies: 230
-- Name: mainmenu_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE mainmenu_id_seq OWNED BY mainmenu.id;


--
-- TOC entry 231 (class 1259 OID 180298)
-- Name: mainsettings; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE mainsettings (
    dsn character varying(200) DEFAULT 'host=127.0.0.1 dbname=framework user=postgres password=Qwerty123 port=5432'::character varying NOT NULL,
    port integer DEFAULT 8080 NOT NULL,
    "developerRole" character varying(30) DEFAULT '0'::character varying NOT NULL,
    maindomain character varying(200) DEFAULT 'http://localhost:8080'::character varying NOT NULL,
    "primaryAuthorization" smallint DEFAULT '1'::smallint NOT NULL,
    redirect401 character varying(200) DEFAULT 'http://localhost:8080/auth'::character varying NOT NULL,
    isactiv boolean DEFAULT true NOT NULL
);


ALTER TABLE mainsettings OWNER TO postgres;

--
-- TOC entry 3254 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN mainsettings.dsn; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN mainsettings.dsn IS 'db connection string';


--
-- TOC entry 3255 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN mainsettings.port; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN mainsettings.port IS 'project server port';


--
-- TOC entry 3256 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN mainsettings."developerRole"; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN mainsettings."developerRole" IS 'developer role id';


--
-- TOC entry 3257 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN mainsettings.maindomain; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN mainsettings.maindomain IS 'main domain';


--
-- TOC entry 3258 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN mainsettings."primaryAuthorization"; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN mainsettings."primaryAuthorization" IS 'primary authorization';


--
-- TOC entry 3259 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN mainsettings.redirect401; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN mainsettings.redirect401 IS 'redirect when status 401';


--
-- TOC entry 232 (class 1259 OID 180311)
-- Name: menus; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE menus (
    id integer NOT NULL,
    menutype smallint,
    menutitle character varying(350),
    ismainmenu boolean DEFAULT false NOT NULL
);


ALTER TABLE menus OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 180315)
-- Name: menus_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menus_id_seq OWNER TO postgres;

--
-- TOC entry 3260 (class 0 OID 0)
-- Dependencies: 233
-- Name: menus_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE menus_id_seq OWNED BY menus.id;


--
-- TOC entry 234 (class 1259 OID 180317)
-- Name: menutypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE menutypes (
    id smallint NOT NULL,
    mtypename character varying NOT NULL
);


ALTER TABLE menutypes OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 180323)
-- Name: menutypes_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE menutypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE menutypes_id_seq OWNER TO postgres;

--
-- TOC entry 3261 (class 0 OID 0)
-- Dependencies: 235
-- Name: menutypes_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE menutypes_id_seq OWNED BY menutypes.id;


--
-- TOC entry 236 (class 1259 OID 180325)
-- Name: methodtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE methodtypes (
    id smallint NOT NULL,
    methotypename character varying(350) NOT NULL
);


ALTER TABLE methodtypes OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 180328)
-- Name: operations; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE operations (
    id integer NOT NULL,
    value character varying(35) NOT NULL,
    js character varying(35),
    python character varying(35),
    sql character varying(35)
);


ALTER TABLE operations OWNER TO postgres;

--
-- TOC entry 3262 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE operations; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE operations IS 'boolean operations for condinions settings';


--
-- TOC entry 238 (class 1259 OID 180331)
-- Name: operations_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE operations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operations_id_seq OWNER TO postgres;

--
-- TOC entry 3263 (class 0 OID 0)
-- Dependencies: 238
-- Name: operations_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE operations_id_seq OWNED BY operations.id;


--
-- TOC entry 239 (class 1259 OID 180333)
-- Name: opertypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE opertypes (
    id smallint NOT NULL,
    typename character varying(150) NOT NULL,
    alias character varying(150)
);


ALTER TABLE opertypes OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 180336)
-- Name: orgs; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE orgs (
    id integer DEFAULT nextval(('framework.orgs_id_seq'::text)::regclass) NOT NULL,
    orgname character varying(350) NOT NULL,
    parentid integer,
    shortname character varying(150),
    created timestamp(0) without time zone DEFAULT now() NOT NULL,
    userid integer NOT NULL
);


ALTER TABLE orgs OWNER TO postgres;

--
-- TOC entry 3264 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN orgs.parentid; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN orgs.parentid IS 'Major org';


--
-- TOC entry 3265 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN orgs.shortname; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN orgs.shortname IS 'Short name';


--
-- TOC entry 241 (class 1259 OID 180348)
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
-- TOC entry 242 (class 1259 OID 180350)
-- Name: paramtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE paramtypes (
    id smallint NOT NULL,
    val character varying(150) NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE paramtypes OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 180359)
-- Name: roles; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE roles (
    id smallint NOT NULL,
    rolename character varying(250) NOT NULL,
    systema character varying(8) DEFAULT 'MIS'::character varying NOT NULL,
    hierarchy smallint,
    ros_rl682_id_id integer
);


ALTER TABLE roles OWNER TO postgres;

--
-- TOC entry 3266 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN roles.systema; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN roles.systema IS 'Система';


--
-- TOC entry 3267 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN roles.hierarchy; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN roles.hierarchy IS 'иерархия ролей';


--
-- TOC entry 3268 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN roles.ros_rl682_id_id; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN roles.ros_rl682_id_id IS 'связь справочник ролей подписантов ЭМД.

перед подписью документ и подписант должен сверятся по этой  справочнику nsi.ros_2ernph8tq8';


--
-- TOC entry 244 (class 1259 OID 180363)
-- Name: select_condition; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE select_condition (
    id integer NOT NULL,
    configid integer NOT NULL,
    col character varying(350) NOT NULL,
    operation character varying(30) NOT NULL,
    const character varying(350),
    value character varying(350),
    created timestamp without time zone DEFAULT now() NOT NULL,
    val_desc integer
);


ALTER TABLE select_condition OWNER TO postgres;

--
-- TOC entry 3269 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE select_condition; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE select_condition IS 'select form method conditions settings';


--
-- TOC entry 245 (class 1259 OID 180370)
-- Name: select_condition_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE select_condition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE select_condition_id_seq OWNER TO postgres;

--
-- TOC entry 3270 (class 0 OID 0)
-- Dependencies: 245
-- Name: select_condition_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE select_condition_id_seq OWNED BY select_condition.id;


--
-- TOC entry 246 (class 1259 OID 180372)
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
-- TOC entry 247 (class 1259 OID 180376)
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
-- TOC entry 3271 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE spapi; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE spapi IS 'Rest Api methods
call plpg function 
always pass in function injson JSON parametr';


--
-- TOC entry 3272 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN spapi.methodname; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN spapi.methodname IS 'API method name (call like this /api/{methodname})';


--
-- TOC entry 3273 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN spapi.procedurename; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN spapi.procedurename IS 'plpg function name
pass all parametrs in injson type of JSON
';


--
-- TOC entry 3274 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN spapi.methodtype; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN spapi.methodtype IS 'rest method type';


--
-- TOC entry 3275 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN spapi.roles; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN spapi.roles IS 'roles';


--
-- TOC entry 248 (class 1259 OID 180384)
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
-- TOC entry 3276 (class 0 OID 0)
-- Dependencies: 248
-- Name: spapi_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE spapi_id_seq OWNED BY spapi.id;


--
-- TOC entry 249 (class 1259 OID 180392)
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
    orgid integer,
    acts json DEFAULT '[]'::json
);


ALTER TABLE trees OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 180401)
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
-- TOC entry 3277 (class 0 OID 0)
-- Dependencies: 250
-- Name: trees_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE trees_id_seq OWNED BY trees.id;


--
-- TOC entry 251 (class 1259 OID 180403)
-- Name: treesacts; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE treesacts (
    id integer NOT NULL,
    treesid integer,
    title character varying(250),
    icon character varying(250),
    classname character varying(250),
    act character varying(250),
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE treesacts OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 180410)
-- Name: treesacts_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE treesacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE treesacts_id_seq OWNER TO postgres;

--
-- TOC entry 3278 (class 0 OID 0)
-- Dependencies: 252
-- Name: treesacts_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE treesacts_id_seq OWNED BY treesacts.id;


--
-- TOC entry 253 (class 1259 OID 180412)
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
    compoid integer,
    orderby smallint,
    ismain boolean DEFAULT false NOT NULL
);


ALTER TABLE treesbranches OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 180420)
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
-- TOC entry 3279 (class 0 OID 0)
-- Dependencies: 254
-- Name: treesbranches_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE treesbranches_id_seq OWNED BY treesbranches.id;


--
-- TOC entry 255 (class 1259 OID 180422)
-- Name: treeviewtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE treeviewtypes (
    id smallint NOT NULL,
    typename character varying(35) NOT NULL
);


ALTER TABLE treeviewtypes OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 180425)
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
    orgid integer,
    userid integer NOT NULL,
    thumbprint character varying(200)
);


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 3280 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE users; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE users IS 'user';


--
-- TOC entry 257 (class 1259 OID 180439)
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
-- TOC entry 3281 (class 0 OID 0)
-- Dependencies: 257
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 258 (class 1259 OID 180441)
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
    subscrible boolean DEFAULT false NOT NULL,
    checker boolean DEFAULT false NOT NULL,
    api json DEFAULT '{}'::json NOT NULL,
    copy boolean DEFAULT false NOT NULL
);


ALTER TABLE views OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 180463)
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
-- TOC entry 3282 (class 0 OID 0)
-- Dependencies: 259
-- Name: views_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE views_id_seq OWNED BY views.id;


--
-- TOC entry 260 (class 1259 OID 180465)
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
    readed timestamp without time zone,
    doublemess uuid
);


ALTER TABLE viewsnotification OWNER TO postgres;

--
-- TOC entry 3283 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE viewsnotification; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE viewsnotification IS 'notifications for views on ws 
you can add here notification for different views on triggers';


--
-- TOC entry 3284 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN viewsnotification.tableid; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN viewsnotification.tableid IS 'id from table';


--
-- TOC entry 3285 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN viewsnotification.notificationtext; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN viewsnotification.notificationtext IS 'message';


--
-- TOC entry 3286 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN viewsnotification.foruser; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN viewsnotification.foruser IS 'user id';


--
-- TOC entry 3287 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN viewsnotification.doublemess; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON COLUMN viewsnotification.doublemess IS 'если это значение одинаковы для нескольких строк то достаточно чтоб был отправлен только один из них,   остальные дубли удаляются в триггере при отметке что информирован первый из них';


--
-- TOC entry 261 (class 1259 OID 180475)
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
-- TOC entry 3288 (class 0 OID 0)
-- Dependencies: 261
-- Name: viewsnotification_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE viewsnotification_id_seq OWNED BY viewsnotification.id;


--
-- TOC entry 262 (class 1259 OID 180477)
-- Name: viewtypes; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE viewtypes (
    id smallint NOT NULL,
    vtypename character varying(200) NOT NULL,
    viewlink character varying(350)
);


ALTER TABLE viewtypes OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 180483)
-- Name: visible_condition; Type: TABLE; Schema: framework; Owner: postgres
--

CREATE TABLE visible_condition (
    id integer NOT NULL,
    configid integer NOT NULL,
    val_desc integer,
    col character varying(350),
    title character varying(350),
    operation character varying(30),
    value character varying(350),
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE visible_condition OWNER TO postgres;

--
-- TOC entry 3289 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE visible_condition; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TABLE visible_condition IS 'form type components columns visible types';


--
-- TOC entry 264 (class 1259 OID 180490)
-- Name: visible_condition_id_seq; Type: SEQUENCE; Schema: framework; Owner: postgres
--

CREATE SEQUENCE visible_condition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE visible_condition_id_seq OWNER TO postgres;

--
-- TOC entry 3290 (class 0 OID 0)
-- Dependencies: 264
-- Name: visible_condition_id_seq; Type: SEQUENCE OWNED BY; Schema: framework; Owner: postgres
--

ALTER SEQUENCE visible_condition_id_seq OWNED BY visible_condition.id;


SET search_path = reports, pg_catalog;

--
-- TOC entry 265 (class 1259 OID 180499)
-- Name: paramtypes; Type: TABLE; Schema: reports; Owner: postgres
--

CREATE TABLE paramtypes (
    id smallint NOT NULL,
    typename character varying(150) NOT NULL
);


ALTER TABLE paramtypes OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 180502)
-- Name: reportlist; Type: TABLE; Schema: reports; Owner: postgres
--

CREATE TABLE reportlist (
    id integer NOT NULL,
    title character varying(350),
    roles json DEFAULT '[]'::json NOT NULL,
    path character varying(150),
    template json,
    template_path character varying(150),
    functitle character varying(150),
    created timestamp without time zone DEFAULT now() NOT NULL,
    section character varying(350),
    completed boolean DEFAULT false NOT NULL,
    filename character varying(200)
);


ALTER TABLE reportlist OWNER TO postgres;

--
-- TOC entry 3291 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE reportlist; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON TABLE reportlist IS 'Список отчётов';


--
-- TOC entry 3292 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN reportlist.title; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportlist.title IS 'Название';


--
-- TOC entry 3293 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN reportlist.roles; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportlist.roles IS 'Роли';


--
-- TOC entry 3294 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN reportlist.path; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportlist.path IS 'Путь';


--
-- TOC entry 3295 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN reportlist.template; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportlist.template IS 'Файл шаблона';


--
-- TOC entry 3296 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN reportlist.functitle; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportlist.functitle IS 'Название функции';


--
-- TOC entry 3297 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN reportlist.section; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportlist.section IS 'Секция';


--
-- TOC entry 267 (class 1259 OID 180511)
-- Name: reportlist_id_seq; Type: SEQUENCE; Schema: reports; Owner: postgres
--

CREATE SEQUENCE reportlist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE reportlist_id_seq OWNER TO postgres;

--
-- TOC entry 3298 (class 0 OID 0)
-- Dependencies: 267
-- Name: reportlist_id_seq; Type: SEQUENCE OWNED BY; Schema: reports; Owner: postgres
--

ALTER SEQUENCE reportlist_id_seq OWNED BY reportlist.id;


--
-- TOC entry 268 (class 1259 OID 180513)
-- Name: reportparams; Type: TABLE; Schema: reports; Owner: postgres
--

CREATE TABLE reportparams (
    id integer NOT NULL,
    reportlistid integer,
    ptitle character varying(150),
    func_paramtitle character varying(150),
    ptype smallint,
    created timestamp without time zone DEFAULT now() NOT NULL,
    apimethod integer,
    completed boolean DEFAULT false NOT NULL,
    orderby smallint DEFAULT 1 NOT NULL
);


ALTER TABLE reportparams OWNER TO postgres;

--
-- TOC entry 3299 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN reportparams.ptitle; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportparams.ptitle IS 'Название параметра';


--
-- TOC entry 3300 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN reportparams.func_paramtitle; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportparams.func_paramtitle IS 'Название параметра в функции';


--
-- TOC entry 3301 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN reportparams.ptype; Type: COMMENT; Schema: reports; Owner: postgres
--

COMMENT ON COLUMN reportparams.ptype IS 'Тип параметра';


--
-- TOC entry 269 (class 1259 OID 180519)
-- Name: reportparams_id_seq; Type: SEQUENCE; Schema: reports; Owner: postgres
--

CREATE SEQUENCE reportparams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE reportparams_id_seq OWNER TO postgres;

--
-- TOC entry 3302 (class 0 OID 0)
-- Dependencies: 269
-- Name: reportparams_id_seq; Type: SEQUENCE OWNED BY; Schema: reports; Owner: postgres
--

ALTER SEQUENCE reportparams_id_seq OWNED BY reportparams.id;


SET search_path = test, pg_catalog;

--
-- TOC entry 273 (class 1259 OID 194799)
-- Name: dictionary_for_select; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE dictionary_for_select (
    id integer NOT NULL,
    dname character varying(150),
    onemoreraltionid integer
);


ALTER TABLE dictionary_for_select OWNER TO postgres;

--
-- TOC entry 3303 (class 0 OID 0)
-- Dependencies: 273
-- Name: TABLE dictionary_for_select; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE dictionary_for_select IS 'dictionary for relation ';


--
-- TOC entry 272 (class 1259 OID 194797)
-- Name: dictionary_for_select_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE dictionary_for_select_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dictionary_for_select_id_seq OWNER TO postgres;

--
-- TOC entry 3304 (class 0 OID 0)
-- Dependencies: 272
-- Name: dictionary_for_select_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE dictionary_for_select_id_seq OWNED BY dictionary_for_select.id;


--
-- TOC entry 275 (class 1259 OID 194859)
-- Name: major_table; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE major_table (
    id integer NOT NULL,
    text text,
    data date,
    "check" boolean,
    "time" time without time zone,
    password character varying,
    color character varying(15),
    multiselect json,
    file json,
    typehead integer,
    image json,
    images json,
    gallery json,
    label character varying(350),
    number integer,
    link json,
    texteditor character varying,
    colorrow character varying(15),
    multitypehead_api json,
    multi_select_api json,
    colorpicker character varying(15),
    "select" integer,
    autocomplete character varying(100),
    textarea text,
    files json,
    typehead_api integer,
    select_api integer,
    multitypehead json,
    datetime timestamp without time zone,
    html character varying
);


ALTER TABLE major_table OWNER TO postgres;

--
-- TOC entry 3305 (class 0 OID 0)
-- Dependencies: 275
-- Name: TABLE major_table; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE major_table IS 'table for testing framework interface';


--
-- TOC entry 274 (class 1259 OID 194857)
-- Name: major_table_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE major_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE major_table_id_seq OWNER TO postgres;

--
-- TOC entry 3306 (class 0 OID 0)
-- Dependencies: 274
-- Name: major_table_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE major_table_id_seq OWNED BY major_table.id;


--
-- TOC entry 271 (class 1259 OID 194791)
-- Name: onemorerelation; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE onemorerelation (
    id integer NOT NULL,
    oname character varying(35) NOT NULL
);


ALTER TABLE onemorerelation OWNER TO postgres;

--
-- TOC entry 3307 (class 0 OID 0)
-- Dependencies: 271
-- Name: TABLE onemorerelation; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE onemorerelation IS 'one more dictionary for tests';


--
-- TOC entry 270 (class 1259 OID 194789)
-- Name: onemorerelation_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE onemorerelation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE onemorerelation_id_seq OWNER TO postgres;

--
-- TOC entry 3308 (class 0 OID 0)
-- Dependencies: 270
-- Name: onemorerelation_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE onemorerelation_id_seq OWNED BY onemorerelation.id;


--
-- TOC entry 277 (class 1259 OID 194881)
-- Name: relate_with_major; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE relate_with_major (
    id integer NOT NULL,
    somecolumn character varying(300) NOT NULL,
    major_table_id integer NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE relate_with_major OWNER TO postgres;

--
-- TOC entry 3309 (class 0 OID 0)
-- Dependencies: 277
-- Name: TABLE relate_with_major; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE relate_with_major IS 'relate table with major_table';


--
-- TOC entry 276 (class 1259 OID 194879)
-- Name: relate_with_major_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE relate_with_major_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE relate_with_major_id_seq OWNER TO postgres;

--
-- TOC entry 3310 (class 0 OID 0)
-- Dependencies: 276
-- Name: relate_with_major_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE relate_with_major_id_seq OWNED BY relate_with_major.id;


SET search_path = framework, pg_catalog;

--
-- TOC entry 2491 (class 2604 OID 180521)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_parametrs ALTER COLUMN id SET DEFAULT nextval('act_parametrs_id_seq'::regclass);


--
-- TOC entry 2493 (class 2604 OID 180522)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_visible_condions ALTER COLUMN id SET DEFAULT nextval('act_visible_condions_id_seq'::regclass);


--
-- TOC entry 2501 (class 2604 OID 180523)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actions ALTER COLUMN id SET DEFAULT nextval('actions_id_seq'::regclass);


--
-- TOC entry 2502 (class 2604 OID 180524)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actparam_querytypes ALTER COLUMN id SET DEFAULT nextval('actparam_querytypes_id_seq'::regclass);


--
-- TOC entry 2504 (class 2604 OID 180525)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY apicallingmethods ALTER COLUMN id SET DEFAULT nextval('apicallingmethods_id_seq'::regclass);


--
-- TOC entry 2506 (class 2604 OID 180526)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY booloper ALTER COLUMN id SET DEFAULT nextval('booloper_id_seq'::regclass);


--
-- TOC entry 2509 (class 2604 OID 180527)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY calendar_actions ALTER COLUMN id SET DEFAULT nextval('calendar_actions_id_seq'::regclass);


--
-- TOC entry 2511 (class 2604 OID 180528)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY calendar_test ALTER COLUMN id SET DEFAULT nextval('calendar_test_id_seq'::regclass);


--
-- TOC entry 2535 (class 2604 OID 180529)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY config ALTER COLUMN id SET DEFAULT nextval('config_id_seq'::regclass);


--
-- TOC entry 2536 (class 2604 OID 180530)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY configsettings ALTER COLUMN id SET DEFAULT nextval('configsettings_id_seq'::regclass);


--
-- TOC entry 2538 (class 2604 OID 180531)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY defaultval ALTER COLUMN id SET DEFAULT nextval('defaultval_id_seq'::regclass);


--
-- TOC entry 2545 (class 2604 OID 180532)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_messages ALTER COLUMN id SET DEFAULT nextval('dialog_messages_id_seq'::regclass);


--
-- TOC entry 2548 (class 2604 OID 180533)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_notifications ALTER COLUMN id SET DEFAULT nextval('dialog_notifications_id_seq'::regclass);


--
-- TOC entry 2549 (class 2604 OID 180534)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_statuses ALTER COLUMN id SET DEFAULT nextval('dialog_statuses_id_seq'::regclass);


--
-- TOC entry 2558 (class 2604 OID 180535)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialogs ALTER COLUMN id SET DEFAULT nextval('dialogs_id_seq'::regclass);


--
-- TOC entry 2565 (class 2604 OID 180536)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filters ALTER COLUMN id SET DEFAULT nextval('filters_id_seq'::regclass);


--
-- TOC entry 2573 (class 2604 OID 180537)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY mainmenu ALTER COLUMN id SET DEFAULT nextval('mainmenu_id_seq'::regclass);


--
-- TOC entry 2582 (class 2604 OID 180538)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY menus ALTER COLUMN id SET DEFAULT nextval('menus_id_seq'::regclass);


--
-- TOC entry 2583 (class 2604 OID 180539)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY menutypes ALTER COLUMN id SET DEFAULT nextval('menutypes_id_seq'::regclass);


--
-- TOC entry 2584 (class 2604 OID 180540)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY operations ALTER COLUMN id SET DEFAULT nextval('operations_id_seq'::regclass);


--
-- TOC entry 2590 (class 2604 OID 180542)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY select_condition ALTER COLUMN id SET DEFAULT nextval('select_condition_id_seq'::regclass);


--
-- TOC entry 2594 (class 2604 OID 180543)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY spapi ALTER COLUMN id SET DEFAULT nextval('spapi_id_seq'::regclass);


--
-- TOC entry 2598 (class 2604 OID 180544)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY trees ALTER COLUMN id SET DEFAULT nextval('trees_id_seq'::regclass);


--
-- TOC entry 2600 (class 2604 OID 180545)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesacts ALTER COLUMN id SET DEFAULT nextval('treesacts_id_seq'::regclass);


--
-- TOC entry 2603 (class 2604 OID 180546)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches ALTER COLUMN id SET DEFAULT nextval('treesbranches_id_seq'::regclass);


--
-- TOC entry 2612 (class 2604 OID 180547)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 2629 (class 2604 OID 180548)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY views ALTER COLUMN id SET DEFAULT nextval('views_id_seq'::regclass);


--
-- TOC entry 2634 (class 2604 OID 180549)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewsnotification ALTER COLUMN id SET DEFAULT nextval('viewsnotification_id_seq'::regclass);


--
-- TOC entry 2636 (class 2604 OID 180550)
-- Name: id; Type: DEFAULT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY visible_condition ALTER COLUMN id SET DEFAULT nextval('visible_condition_id_seq'::regclass);


SET search_path = reports, pg_catalog;

--
-- TOC entry 2640 (class 2604 OID 180551)
-- Name: id; Type: DEFAULT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportlist ALTER COLUMN id SET DEFAULT nextval('reportlist_id_seq'::regclass);


--
-- TOC entry 2644 (class 2604 OID 180552)
-- Name: id; Type: DEFAULT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportparams ALTER COLUMN id SET DEFAULT nextval('reportparams_id_seq'::regclass);


SET search_path = test, pg_catalog;

--
-- TOC entry 2646 (class 2604 OID 194802)
-- Name: id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY dictionary_for_select ALTER COLUMN id SET DEFAULT nextval('dictionary_for_select_id_seq'::regclass);


--
-- TOC entry 2647 (class 2604 OID 194862)
-- Name: id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY major_table ALTER COLUMN id SET DEFAULT nextval('major_table_id_seq'::regclass);


--
-- TOC entry 2645 (class 2604 OID 194794)
-- Name: id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY onemorerelation ALTER COLUMN id SET DEFAULT nextval('onemorerelation_id_seq'::regclass);


--
-- TOC entry 2648 (class 2604 OID 194884)
-- Name: id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY relate_with_major ALTER COLUMN id SET DEFAULT nextval('relate_with_major_id_seq'::regclass);


SET search_path = framework, pg_catalog;

--
-- TOC entry 2978 (class 0 OID 180071)
-- Dependencies: 185
-- Data for Name: act_parametrs; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY act_parametrs (id, actionid, paramtitle, paramt, paramconst, paraminput, paramcolumn, val_desc, query_type, created, "order by") FROM stdin;
5622	2750	reportlistid	\N	0	\N	\N	\N	query	2019-12-25 11:04:47.818399	\N
5623	2751	paramid	\N	-1	\N	\N	\N	query	2019-12-25 11:04:47.818399	\N
5624	2751	reportlistid	\N		\N	id	19342	query	2019-12-25 11:04:47.818399	\N
5625	2752	id	\N		\N	id	19342	query	2019-12-25 11:04:47.818399	\N
5626	2754	id	\N	\N	\N	id	19342	query	2019-12-25 11:04:47.818399	\N
5627	2757	paramid	\N	0	\N	\N	\N	query	2019-12-25 11:04:47.818399	\N
5628	2757	relation	\N	reportlistid	\N	\N	\N	query	2019-12-25 11:04:47.818399	\N
5629	2757	reportlistid	\N		\N	reportlistid	19367	query	2019-12-25 11:04:47.818399	\N
5630	2758	paramid	\N		\N	param_id	19406	query	2019-12-25 11:04:47.818399	\N
5631	2758	reportlistid	\N		\N	reportlistid	19367	query	2019-12-25 11:04:47.818399	\N
5632	2761	paramid	\N	-1	\N	\N	\N	query	2019-12-25 11:04:47.818399	\N
5633	2761	reportlistid	\N		\N	reportlistid	19376	query	2019-12-25 11:04:47.818399	\N
5049	2141	viewid	\N	\N	viewid	\N	\N	query	2019-12-03 11:11:24.059376	\N
5048	2186	viewid	\N	\N	id	\N	\N	query	2019-12-03 11:10:49.325566	\N
5054	2092	viewid	\N	\N	viewid	\N	\N	query	2019-12-03 11:15:40.030556	\N
5058	2139	viewid	\N	\N	viewid	\N	\N	query	2019-12-03 11:21:39.899014	\N
5066	2398	id	\N	\N	viewid	\N	\N	query	2019-12-03 11:26:52.013714	\N
5075	2029	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:39:21.168145	\N
5050	2397	id	\N	\N	viewid	\N	\N	query	2019-12-03 11:11:43.894366	\N
5051	2397	act_id	\N	-1		\N	\N	query	2019-12-03 11:12:10.847087	\N
5052	2397	fl_id	\N	-1		\N	\N	query	2019-12-03 11:12:23.352866	\N
5062	2152	viewid	\N	\N	viewid	\N	\N	query	2019-12-03 11:25:22.290336	\N
5053	2397	N	\N	-1		\N	\N	query	2019-12-03 11:12:39.009882	\N
5055	2141	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:19:20.985548	\N
5056	2092	_sub_title	\N		_sub_title	\N	\N	query	2019-12-03 11:19:38.113472	\N
5061	2143	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:24:50.655449	\N
5057	2139	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:21:30.118959	\N
5063	2152	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:25:30.098891	\N
5068	2398	fl_id	\N	-1	\N	\N	\N	query	2019-12-03 11:28:10.073305	\N
5069	2398	act_id	\N	-1	\N	\N	\N	query	2019-12-03 11:28:19.971311	\N
4104	2021	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4105	2021	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4106	2021	_sub_title	\N		_sub_title	\N	\N	query	2019-11-05 10:00:17.290746	\N
4107	2021	CN	\N			id	12701	query	2019-11-05 10:00:17.290746	\N
4108	2021	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4109	2021	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4110	2022	id	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4111	2022	N	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4112	2024	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4113	2024	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4114	2024	_sub_title	\N		_sub_title	\N	\N	query	2019-11-05 10:00:17.290746	\N
4115	2024	CN	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4116	2024	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4117	2024	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4121	2029	relation	\N		relation	\N	\N	query	2019-11-05 10:00:17.290746	\N
4122	2029	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4123	2029	CN	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4124	2029	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4125	2030	relation	\N		relation	\N	\N	query	2019-11-05 10:00:17.290746	\N
4126	2030	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4127	2030	CN	\N			id	12753	query	2019-11-05 10:00:17.290746	\N
4128	2030	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4129	2031	id	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4130	2031	N	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4131	2033	id	\N	\N	\N	id	12759	query	2019-11-05 10:00:17.290746	\N
4132	2033	treesid	\N	\N	\N	treesid	12760	query	2019-11-05 10:00:17.290746	\N
4133	2034	relation	\N	treesid	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4134	2034	treesid	\N	\N	\N	treesid	12760	query	2019-11-05 10:00:17.290746	\N
4135	2034	bid	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4136	2035	id	\N	\N	\N	id	12759	query	2019-11-05 10:00:17.290746	\N
4137	2040	id	\N	\N	\N	id	12784	query	2019-11-05 10:00:17.290746	\N
4138	2041	path	\N	\N	\N	path	12786	query	2019-11-05 10:00:17.290746	\N
4139	2042	id	\N	\N	\N	id	12784	query	2019-11-05 10:00:17.290746	\N
4144	2048	id	\N	\N	\N	id	12822	query	2019-11-05 10:00:17.290746	\N
4145	2049	id	\N		\N	id	12834	query	2019-11-05 10:00:17.290746	\N
4146	2050	menuid	\N		\N	id	12834	query	2019-11-05 10:00:17.290746	\N
4147	2052	id	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4148	2054	N	\N	\N	\N	id	12839	query	2019-11-05 10:00:17.290746	\N
4149	2055	id	\N	\N	\N	id	12839	query	2019-11-05 10:00:17.290746	\N
4168	2073	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4169	2073	configid	\N			N	12912	query	2019-11-05 10:00:17.290746	\N
4170	2073	CN	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4171	2073	viewid	\N			id	12913	query	2019-11-05 10:00:17.290746	\N
4172	2074	configid	\N			N	12912	query	2019-11-05 10:00:17.290746	\N
4173	2074	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4174	2074	_sub_title	\N			title	12917	query	2019-11-05 10:00:17.290746	\N
4175	2074	CN	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4176	2074	viewid	\N			id	12913	query	2019-11-05 10:00:17.290746	\N
4177	2075	N	\N			N	12912	query	2019-11-05 10:00:17.290746	\N
4178	2075	configid	\N			N	12912	query	2019-11-05 10:00:17.290746	\N
4179	2075	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4180	2075	CN	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4181	2075	table	\N			relation table	12931	query	2019-11-05 10:00:17.290746	\N
4182	2075	_sub_title	\N			title	12917	query	2019-11-05 10:00:17.290746	\N
4183	2075	viewid	\N			id	12913	query	2019-11-05 10:00:17.290746	\N
4184	2076	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4185	2076	N	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4186	2076	fl_id	\N		fl_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4187	2076	act_id	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4188	2078	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4189	2078	CN	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4190	2078	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4191	2078	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4192	2078	table	\N		table	\N	\N	query	2019-11-05 10:00:17.290746	\N
4193	2078	_sub_title	\N		_sub_title	\N	\N	query	2019-11-05 10:00:17.290746	\N
4194	2078	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4195	2080	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4196	2080	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4197	2080	_sub_title	\N		_sub_title	\N	\N	query	2019-11-05 10:00:17.290746	\N
4198	2080	CN	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4199	2080	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4200	2080	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4201	2082	relation	\N		relation	\N	\N	query	2019-11-05 10:00:17.290746	\N
4202	2082	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4203	2082	CN	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4204	2082	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
5059	2187	viewid	\N	\N	id	\N	\N	query	2019-12-03 11:24:18.469893	\N
5065	2153	viewid	\N	\N	viewid	\N	\N	query	2019-12-03 11:26:04.689502	\N
4209	2085	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4210	2085	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4211	2085	fl_id	\N		fl_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4212	2085	act_id	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4213	2085	relation	\N	viewid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4214	2085	viewid	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4215	2087	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4216	2087	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4217	2087	fl_id	\N		fl_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4218	2087	act_id	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4219	2088	actionid	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4220	2088	relation	\N	actionid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4221	2088	paramid	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4222	2088	act_id	\N			act_id	12995	query	2019-11-05 10:00:17.290746	\N
4223	2089	actionid	\N			act_id	12995	query	2019-11-05 10:00:17.290746	\N
4224	2089	relation	\N	actionid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4225	2089	act_id	\N			act_id	12995	query	2019-11-05 10:00:17.290746	\N
4226	2089	vs_id	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4227	2092	actionid	\N		actionid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4228	2092	relation	\N	actionid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4229	2092	id	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4233	2093	viewid	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4234	2094	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4235	2094	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4236	2094	fl_id	\N		fl_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4237	2094	act_id	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4238	2094	a	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4239	2095	col	\N			column title	13039	query	2019-11-05 10:00:17.290746	\N
4240	2095	viewid	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4241	2096	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4242	2096	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4243	2096	fl_id	\N		fl_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4244	2096	act_id	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4245	2096	i	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4246	2097	viewid	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4247	2097	setting	\N			setting	13043	query	2019-11-05 10:00:17.290746	\N
4248	2097	col	\N			column	13044	query	2019-11-05 10:00:17.290746	\N
4249	2098	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4250	2098	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4251	2098	fl_id	\N		fl_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4252	2098	act_id	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4253	2098	ttt	\N	1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4254	2099	id	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4255	2100	id	\N	\N	\N	id	13045	query	2019-11-05 10:00:17.290746	\N
4256	2101	treesid	\N			id	13045	query	2019-11-05 10:00:17.290746	\N
4257	2101	bid	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4258	2102	treesid	\N	\N	\N	id	13045	query	2019-11-05 10:00:17.290746	\N
4259	2102	bid	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4260	2103	id	\N	\N	\N	id	13045	query	2019-11-05 10:00:17.290746	\N
4261	2107	treesid	\N	\N	\N	treesid	13058	query	2019-11-05 10:00:17.290746	\N
4262	2107	bid	\N	\N	\N	id	13057	query	2019-11-05 10:00:17.290746	\N
4263	2108	id	\N	\N	\N	id	13057	query	2019-11-05 10:00:17.290746	\N
4264	2109	bid	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4265	2109	relation	\N	treesid	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4266	2109	treesid	\N		treesid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4267	2111	bid	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4268	2111	treesid	\N		treesid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4269	2112	treesid	\N	\N	\N	treesid	13079	query	2019-11-05 10:00:17.290746	\N
4270	2112	bid	\N	-1	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4271	2113	id	\N	\N	\N	id	13085	query	2019-11-05 10:00:17.290746	\N
4272	2113	o	\N	\N	\N	title	13086	query	2019-11-05 10:00:17.290746	\N
4273	2114	id	\N	\N	\N	id	13085	query	2019-11-05 10:00:17.290746	\N
4274	2115	id	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4275	2115	relation	\N	menuid	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4276	2115	menuid	\N		\N	menuid	13095	query	2019-11-05 10:00:17.290746	\N
4277	2117	menuid	\N		\N	menuid	13106	query	2019-11-05 10:00:17.290746	\N
4278	2118	id	\N	\N	\N	id	13107	query	2019-11-05 10:00:17.290746	\N
4279	2119	id	\N	\N	\N	id	13107	query	2019-11-05 10:00:17.290746	\N
4280	2120	id	\N	0	\N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4231	2093	fn	\N			function	13029	query	2019-11-05 10:00:17.290746	\N
4230	2093	title	\N			title	13028	query	2019-11-05 10:00:17.290746	\N
4286	2124	id	\N		\N	id	13117	query	2019-11-05 10:00:17.290746	\N
5060	2143	viewid	\N	\N	viewid	\N	\N	query	2019-12-03 11:24:39.428532	\N
4291	2130	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4292	2130	id	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4293	2131	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4294	2131	CN	\N			cni	13167	query	2019-11-05 10:00:17.290746	\N
4295	2131	relation	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4296	2131	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4297	2131	table	\N		table	\N	\N	query	2019-11-05 10:00:17.290746	\N
4298	2131	_sub_title	\N		_sub_title	\N	\N	query	2019-11-05 10:00:17.290746	\N
4299	2131	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4300	2133	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4301	2133	CN	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4302	2133	relation	\N	configid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4303	2133	configid	\N		configid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4304	2133	table	\N		table	\N	\N	query	2019-11-05 10:00:17.290746	\N
4305	2133	_sub_title	\N		_sub_title	\N	\N	query	2019-11-05 10:00:17.290746	\N
4306	2133	viewid	\N		viewid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4311	2136	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4312	2136	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4313	2136	act_id	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4314	2136	relation	\N	viewid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4315	2136	viewid	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4316	2136	fl_id	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4317	2138	id	\N		id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4318	2138	N	\N		N	\N	\N	query	2019-11-05 10:00:17.290746	\N
4319	2138	fl_id	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4320	2138	act_id	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4321	2139	actionid	\N		actionid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4322	2139	paramid	\N			p_id	13201	query	2019-11-05 10:00:17.290746	\N
4323	2139	relation	\N	actionid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4324	2141	actionid	\N		actionid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4325	2141	relation	\N	actionid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4326	2141	paramid	\N	0		\N	\N	query	2019-11-05 10:00:17.290746	\N
4327	2143	actionid	\N		actionid	\N	\N	query	2019-11-05 10:00:17.290746	\N
4328	2143	relation	\N	actionid		\N	\N	query	2019-11-05 10:00:17.290746	\N
4329	2143	vs_id	\N	-1		\N	\N	query	2019-11-05 10:00:17.290746	\N
4330	2143	act_id	\N		act_id	\N	\N	query	2019-11-05 10:00:17.290746	\N
4333	2123	id	\N	0	\N	\N	\N	query	2019-11-05 11:49:26.003741	\N
5064	2153	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:25:45.233795	\N
4344	2139	act_id	\N	\N	act_id	\N	\N	query	2019-11-05 17:31:21.8216	\N
4345	2141	act_id	\N	\N	act_id	\N	\N	query	2019-11-05 17:32:00.473986	\N
4369	2092	paramid	\N	-1	\N	\N	\N	query	2019-11-06 13:45:27.260521	\N
4370	2092	act_id	\N	\N	act_id	\N	\N	query	2019-11-06 13:45:50.236083	\N
4371	2152	actionid	\N	\N	actionid	\N	\N	query	2019-11-06 13:48:50.435347	\N
4372	2152	relation	\N	actionid	\N	\N	\N	query	2019-11-06 13:49:02.617198	\N
4373	2152	act_id	\N	\N	act_id	\N	\N	query	2019-11-06 13:49:12.250123	\N
4374	2152	vs_id	\N	0	\N	\N	\N	query	2019-11-06 13:49:25.557885	\N
4375	2153	act_id	\N	\N	act_id	\N	\N	query	2019-11-06 13:50:48.872392	\N
4376	2153	actionid	\N	\N	actionid	\N	\N	query	2019-11-06 13:50:58.50819	\N
4377	2153	relation	\N	actionid	\N	\N	\N	query	2019-11-06 13:51:13.255356	\N
4378	2153	vs_id	\N	\N	\N	\N	13032	query	2019-11-06 13:51:26.269503	\N
4232	2093	fncols	\N			columns	13030	query	2019-11-05 10:00:17.290746	\N
4449	2184	_sub_title	\N	\N	\N	\N	13147	query	2019-11-11 16:54:36.90807	\N
4450	2184	relation	\N	configid	\N	\N	\N	query	2019-11-11 16:55:08.44819	\N
4451	2184	configid	\N	\N	\N	\N	13142	query	2019-11-11 16:55:36.50379	\N
4452	2184	CN	\N	-1	\N	\N	\N	query	2019-11-11 16:55:59.399052	\N
4453	2184	viewid	\N	\N	\N	\N	13143	query	2019-11-11 16:56:16.105455	\N
4455	2185	configid	\N	\N	\N	\N	13142	query	2019-11-11 17:04:23.543054	\N
4459	2185	table	\N	\N	\N	\N	13158	query	2019-11-11 17:06:08.439169	\N
5067	2398	N	\N	-1		\N	\N	query	2019-12-03 11:27:54.96914	\N
4454	2185	N	\N	\N	\N	\N	13142	query	2019-11-11 17:04:05.00802	\N
4456	2185	relation	\N	configid	\N	\N	\N	query	2019-11-11 17:04:42.114409	\N
4457	2185	CN	\N	-1	\N	\N	\N	query	2019-11-11 17:05:14.313201	\N
4458	2185	viewid	\N	\N	\N	\N	13143	query	2019-11-11 17:05:46.135291	\N
4460	2185	_sub_title	\N		\N	\N	13147	query	2019-11-11 17:06:42.751963	\N
4461	2186	actionid	\N	\N	\N	\N	12979	query	2019-11-12 08:38:30.402451	\N
4462	2186	relation	\N	actionid	\N	\N	\N	query	2019-11-12 08:39:12.126697	\N
4463	2186	paramid	\N	-1	\N	\N	\N	query	2019-11-12 08:39:41.343084	\N
4464	2186	act_id	\N	\N	\N	\N	12979	query	2019-11-12 08:39:57.839483	\N
4466	2187	actionid	\N	\N	\N	\N	12979	query	2019-11-12 09:41:42.386233	\N
4467	2187	relation	\N	actionid	\N	\N	\N	query	2019-11-12 09:42:03.319002	\N
4468	2187	act_id	\N	\N	\N	\N	12979	query	2019-11-12 09:42:18.923298	\N
4469	2187	vs_id	\N	-1	\N	\N	\N	query	2019-11-12 09:42:30.800282	\N
4470	2187	_sub_title	\N	\N	\N	\N	12981	query	2019-11-12 09:42:49.549042	\N
4465	2186	_sub_title	\N	\N	\N	\N	12981	query	2019-11-12 08:40:23.705068	\N
4472	2189	_sub_title	\N		\N	\N	13145	query	2019-11-12 10:09:02.759353	\N
4473	2189	relation	\N	configid	\N	\N	\N	query	2019-11-12 10:10:37.004788	\N
4474	2189	configid	\N		\N	\N	13142	query	2019-11-12 10:10:55.269391	\N
4475	2189	CN	\N	-1	\N	\N	\N	query	2019-11-12 10:11:33.155995	\N
4476	2189	viewid	\N	\N	\N	\N	13143	query	2019-11-12 10:11:49.284601	\N
5074	2082	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:38:10.648788	\N
4490	2211	id	\N	\N	\N	\N	12979	query	2019-11-12 20:58:51.973144	\N
5076	2030	_sub_title	\N	\N	_sub_title	\N	\N	query	2019-12-03 11:39:32.394043	\N
4626	2263	id	\N	\N	\N	\N	14589	query	2019-11-18 10:50:01.284734	\N
\.


--
-- TOC entry 3311 (class 0 OID 0)
-- Dependencies: 186
-- Name: act_parametrs_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('act_parametrs_id_seq', 5708, true);


--
-- TOC entry 2980 (class 0 OID 180081)
-- Dependencies: 187
-- Data for Name: act_visible_condions; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY act_visible_condions (id, actionid, val_desc, col, title, operation, value, created) FROM stdin;
773	2072	12912	\N	\N	>	-1	2019-11-05 10:00:17.290746
774	2073	12912	\N	\N	>	-1	2019-11-05 10:00:17.290746
775	2074	12941	\N	\N	like	form	2019-11-05 10:00:17.290746
776	2075	12918	\N	\N	in	select,typehead	2019-11-05 10:00:17.290746
777	2075	12941	\N	\N	like	form	2019-11-05 10:00:17.290746
778	2076	12912	\N	\N	>	-1	2019-11-05 10:00:17.290746
779	2077	12942	\N	\N	>	-1	2019-11-05 10:00:17.290746
780	2078	12942	\N	\N	>	-1	2019-11-05 10:00:17.290746
781	2079	12950	\N	\N	>	-1	2019-11-05 10:00:17.290746
782	2080	12950	\N	\N	>	-1	2019-11-05 10:00:17.290746
783	2086	12995	\N	\N	>	-1	2019-11-05 10:00:17.290746
784	2087	12995	\N	\N	>	-1	2019-11-05 10:00:17.290746
785	2088	12995	\N	\N	is not null	\N	2019-11-05 10:00:17.290746
786	2089	12995	\N	\N	>	-1	2019-11-05 10:00:17.290746
787	2089	12995	\N	\N	is not null	\N	2019-11-05 10:00:17.290746
788	2091	13020	\N	\N	>	-1	2019-11-05 10:00:17.290746
789	2092	13020	\N	\N	>	-1	2019-11-05 10:00:17.290746
791	2137	13189	\N	\N	>	-1	2019-11-05 10:00:17.290746
792	2138	13189	\N	\N	>	-1	2019-11-05 10:00:17.290746
793	2142	13210	\N	\N	>	-1	2019-11-05 10:00:17.290746
794	2143	13210	\N	\N	>	-1	2019-11-05 10:00:17.290746
813	2185	13158	\N	\N	is not null		2019-11-11 17:26:10.726976
1073	2752	19351	\N	\N	=	true	2019-12-25 11:04:47.818399
\.


--
-- TOC entry 3312 (class 0 OID 0)
-- Dependencies: 188
-- Name: act_visible_condions_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('act_visible_condions_id_seq', 1092, true);


--
-- TOC entry 2982 (class 0 OID 180090)
-- Dependencies: 189
-- Data for Name: actions; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY actions (id, column_order, title, viewid, icon, classname, act_url, api_method, api_type, refresh_data, ask_confirm, roles, forevery, main_action, created, act_type) FROM stdin;
2796	1	Save	55	default	\N	/	\N	\N	f	f	[]	f	f	2019-12-31 14:38:02.63699	Save
2281	1	untitled_2281	5463	default	\N	/	\N	\N	f	f	[]	f	f	2019-11-18 13:58:26.109607	Link
2398	3	go back	231	arrow left	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-12-03 11:26:13.429586	Link
2397	4	go back	243	arrow-left	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-12-03 11:07:50.785664	Link
2081	1	Save	226	\N	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2028	1	OK	211	fa fa-	btn btn	/list/projectmenus	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Link
2033	1	edit	100	fa fa-edit	\N	/composition/treesacts	\N	get	f	f	[]	t	f	2019-11-05 10:00:17.290746	Link
2034	2	add	100	fa fa-plus	\N	/composition/treesacts	\N	get	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2035	3	del	100	fa fa-trash	\N	/getone/treesact	\N	get	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2036	4	go back	100	fa fa-arrow-left	\N	/list/trees	\N	get	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2038	1	назад	213	fa fa-arrow-left	btn btn-success	/list/users	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2037	2	back	212	fa  fa-arrow-left	btn btn-outline-secondary	/list/spapi	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2048	1	look	216	fa fa-eye	\N	/getone/log	\N	get	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2049	1	edit	150	fa fa-edit	btn	/getone/projectmenu	\N	get	t	t	[]	t	t	2019-11-05 10:00:17.290746	Link
2050	2	menu list	150	fa fa-list		/list/menusettings	\N	get	t	t	[]	t	f	2019-11-05 10:00:17.290746	Link
2051	3	del	150	fa fa-trash	btn	/getone/projectmenu	\N	get	t	t	[]	t	f	2019-11-05 10:00:17.290746	Delete
2052	4	add	150	fa fa-plus	btn	/getone/projectmenu	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Link
2053	1	add	217	fa fa-plus	\N	/getone/spapiform?N=0	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2054	2	edit	217	fa fa-pencil	\N	/getone/spapiform	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2055	3	del	217	fa fa-trash	\N	/schema/deleterow	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2072	1	save	221	\N	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2073	2	default value	221	pi pi-key	p-button-primary	/composition/defaultval	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2074	3	visible condition	221	pi pi-question	\N	/composition/visible_conditions	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	LinkTo
2075	4	select conditions	221	pi pi-question	p-button-warning	/composition/select_condition	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	LinkTo
2076	5	close	221	\N	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2077	1	save	222		p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2078	2	close	222	pi pi-cross	\N	/composition/select_condition	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2079	1	save	223	\N	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2080	2	close	223	pi pi-cross	\N	/composition/visible_conditions	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2082	2	Close	226	fa fa-cross	\N	/composition/defaultval	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2086	1	save	228	fa fa-check	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2087	2	close	228	fa fa-cross	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2088	3	parametrs	228	pi pi-primary	p-button-warning	/composition/act_params	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	LinkTo
2089	4	visible condition	228	pi pi-question	\N	/composition/act_visible_conditions	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	LinkTo
2090	1	back	56	fa fa-arrow-left		/list/logs	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Link
2031	3	Go back	225	\N	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2091	1	save	229	fa fa-check	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2092	2	close	229	fa fa-cross	\N	/composition/act_params	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2093	1	add	230	pi pi-plus	p-button-success	/api/addfncol	\N	post	t	t	[]	f	f	2019-11-05 10:00:17.290746	API
2094	2	refresh	230	fa fa-refresh	p-button-primary	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2095	1	add	232	pi pi-plus	p-button-success	/api/addcol	\N	post	t	t	[]	f	f	2019-11-05 10:00:17.290746	API
2096	2	refresh	232	fa fa-refresh	p-button-primary	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2097	1	apply to all	233	fa fa-check	p-buton-success	/api/applysettings	\N	post	t	t	[]	f	f	2019-11-05 10:00:17.290746	API
2098	2	refresh	233	fa fa-refresh	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2104	1	save	28		btn btn-outline-success	/	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Save
2105	2	back	28	fa fa-arrow-left	btn	/list/trees	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2106	1	back	30	fa fa-arrow-left	btn 	/list/trees	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2107	2	edit	30	fa fa-pencil	\N	/composition/branches	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2108	3	del	30	fa fa-trash	\N	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2109	4	add	30	fa fa-plus	\N	/composition/branches	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2110	1	save	32	\N	\N	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2111	2	close	32	\N	\N	/composition/branches	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2112	1	ok	101	fa fa-check	\N	/composition/treesacts	\N	get	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2113	1	edit	234	fa fa-edit	\N	/getone/menuedit	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2114	2	delete menu	234	fa fa-trash	btn	/schema/deleterow	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2115	3	add menu	234	fa fa-plus	\N	/getone/menuedit	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2116	4	back	234	fa fa-arrow-left		/list/projectmenus	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Link
2117	1	back	235	fa fa-arrow-left	btn	/list/menusettings	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2118	1	edit user	236	fa fa-pencil	\N	/getone/userone	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Link
2119	2	delete	236	fa fa-trash	\N	/schema/deleterow	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2120	3	add	236	fa fa-plus		/getone/userone	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Link
2125	5	del	237	fa fa-trash		/	\N	post	t	t	[]	t	f	2019-11-05 10:00:17.290746	Delete
2126	1	save main info	238	fa fa-check	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2127	2	back to list	238	fa fa-arrow-left	\N	/list/views	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2130	1	go back	240	arrow-left	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2137	1	save	242	pi pi-check	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2138	2	close	242	fa fa-cross	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2142	1	save	244	fa fa-check	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2143	2	close	244	fa fa-cros	\N	/composition/act_visible_conditions	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2144	1	save main info	245	fa fa-check	p-button-success	/	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Save
2145	2	back to list	245	fa fa-arrow-left	\N	/list/views	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2101	3	branches	26	branches	\N	/composition/branches	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Link
2100	2	edit	26	edit	\N	/getone/treeform	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2099	1	add	26	plus	btn btn	/getone/treeform	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2103	5	delete	26	delete	\N	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2123	3	create view	237	fa fa-plus		/getone/viewadd	\N	get	t	t	[]	f	f	2019-11-05 10:00:17.290746	Link
2131	2	edit	240	edit	\N	/composition/select_condition	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Link
2132	3	delete	240	delete	p-button-danger	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2133	4	add	240	plus	\N	/composition/select_condition	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2153	1	edit	231	fa fa-pencil		/composition/act_visible_conditions	\N	\N	f	f	[]	t	t	2019-11-06 13:50:25.690898	Link
2154	2	delete	231	fa fa-trash	p-button-danger	\N	\N	\N	f	f	[]	t	f	2019-11-06 13:52:05.02372	Delete
2152	0	add	231	fa fa-plus	\N	/composition/act_visible_conditions	\N	\N	f	f	[]	f	f	2019-11-06 13:41:46.193098	Link
2124	4	copy	237	copy		/api/copyview	\N	post	t	t	[0]	t	f	2019-11-05 10:00:17.290746	API
2349	1	save	212	default	\N	/	\N	\N	f	f	[]	f	f	2019-11-25 08:18:53.335585	Save
2755	1	Save	119	save	btn-success	/api/save	\N	\N	f	f	[]	f	f	2019-12-25 11:04:47.818399	Save
2139	1	edit	243	edit	\N	/composition/act_params	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2141	3	add	243	add	\N	/composition/act_params	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2140	2	delete	243	delete	\N	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2756	2	Go back	119	\N	btn btn-success	/list/reports	\N	get	t	t	[]	f	f	2019-12-25 11:04:47.818399	Link
2041	3	, to compo	214	link	\N	/composition	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Link
2042	4	delete	214	delete	\N	/schema/deleterow	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2040	2	edit	214	edit	\N	/compo/l	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2039	1	add	214	plus	\N	/compo/l?id=0	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2135	2	delete	241	delete	delete	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2136	4	add	241	plus	add	/api/filter_add_untitle	\N	post	t	t	[]	f	f	2019-11-05 10:00:17.290746	API
2760	1	Save	121	save	btn btn-success	/api/save	\N	\N	f	f	[]	f	f	2019-12-25 11:04:47.818399	Save
2761	2	Refresh	121	refresh	btn btn-outline-primary	/composition/reportone	\N	get	t	t	[]	f	f	2019-12-25 11:04:47.818399	Link
2757	1	Add	120	plus		/composition/reportone	\N	get	t	t	[]	f	f	2019-12-25 11:04:47.818399	Link
2758	2	Edit	120	edit		/composition/reportone	\N	get	t	t	[]	t	f	2019-12-25 11:04:47.818399	Link
2759	3	Delete	120	delete		/composition/reportone	\N	get	t	t	[]	t	f	2019-12-25 11:04:47.818399	Delete
2750	1	add	118	plus		/getone/reportone	\N	get	t	t	[]	f	f	2019-12-25 11:04:47.818399	Link
2751	2	edit	118	edit		/composition/reportone	\N	get	t	t	[]	t	t	2019-12-25 11:04:47.818399	Link
2752	3	перейти к отчёту	118	link		/report	\N	get	t	t	[]	t	f	2019-12-25 11:04:47.818399	Link
2753	4	del	118	delete		/	\N	get	t	t	[]	t	f	2019-12-25 11:04:47.818399	Delete
2754	5	Копировать отчёт	118	copy		/api/report_copy	\N	post	t	t	[0]	t	f	2019-12-25 11:04:47.818399	API
2187	3	visible conditions	227	eye	\N	/composition/act_visible_conditions	\N	\N	f	f	[]	t	f	2019-11-12 09:39:59.56735	Link
2084	5	delete	227	delete	p-button-danger	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2021	1	edit	224	edit	\N	/composition/visible_conditions	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2023	3	delete	224	delete	p-button-danger	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2024	4	add	224	plus	\N	/composition/visible_conditions	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2022	2	go back	224	fa fa-arrow-left	\N	/composition/view	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2184	1	visible condition	239	eye		/composition/visible_conditions	\N	\N	f	f	[]	t	f	2019-11-11 16:53:58.539744	Link
2185	2	select_condition	239	question	\N	/composition/select_condition	\N	\N	f	f	[]	t	f	2019-11-11 17:02:07.08031	Link
2189	3	default value	239	swap	\N	/composition/defaultval	\N	\N	f	f	[]	t	f	2019-11-12 10:06:06.161021	Link
2211	4	copy	227	copy	\N	/api/action_copy	\N	post	t	t	[]	t	f	2019-11-12 20:56:46.824784	API
2129	4	delete	239	fa fa-trash	p-button-danger	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2186	1	parametrs	227	code	\N	/composition/act_params	\N	\N	f	f	[]	t	t	2019-11-12 08:37:53.930855	Link
2085	2	add	227	plus	\N	/api/action_add_untitle	\N	post	t	t	[]	f	f	2019-11-05 10:00:17.290746	API
2029	1	Add	225	plus	\N	/composition/defaultval	\N	\N	f	f	[]	f	f	2019-11-05 10:00:17.290746	Link
2030	2	edit	225	edit	\N	/composition/defaultval	\N	\N	f	f	[]	t	t	2019-11-05 10:00:17.290746	Link
2032	4	delete	225	delete	\N	/	\N	\N	f	f	[]	t	f	2019-11-05 10:00:17.290746	Delete
2263	1	add	5469	default	\N	/getone/log	\N	\N	f	f	[]	t	f	2019-11-15 15:22:47.491619	Link
2102	4	actions	26	apartment	\N	/composition/treesacts	\N	get	f	f	[]	t	f	2019-11-05 10:00:17.290746	Link
\.


--
-- TOC entry 3313 (class 0 OID 0)
-- Dependencies: 190
-- Name: actions_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('actions_id_seq', 2796, true);


--
-- TOC entry 2984 (class 0 OID 180105)
-- Dependencies: 191
-- Data for Name: actparam_querytypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY actparam_querytypes (id, aqname) FROM stdin;
1	query
2	link
\.


--
-- TOC entry 3314 (class 0 OID 0)
-- Dependencies: 192
-- Name: actparam_querytypes_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('actparam_querytypes_id_seq', 2, true);


--
-- TOC entry 2986 (class 0 OID 180110)
-- Dependencies: 193
-- Data for Name: acttypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY acttypes (id, actname, viewtypes) FROM stdin;
1	API	["table","tiles","form full","form not mutable"]
2	Link	["table","tiles","form full","form not mutable"]
4	Delete	["table","tiles"]
5	Save	["form not mutable"]
6	Back	["table","tiles","form full","form not mutable"]
7	LinkTo	["form not mutable"]
8	Print Data	[]
9	Expand	["table"]
\.


--
-- TOC entry 2987 (class 0 OID 180117)
-- Dependencies: 194
-- Data for Name: apicallingmethods; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY apicallingmethods (id, aname) FROM stdin;
1	simple
2	mdlp
\.


--
-- TOC entry 3315 (class 0 OID 0)
-- Dependencies: 195
-- Name: apicallingmethods_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('apicallingmethods_id_seq', 2, true);


--
-- TOC entry 2989 (class 0 OID 180122)
-- Dependencies: 196
-- Data for Name: apimethods; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY apimethods (id, val, created) FROM stdin;
1	simple	2019-04-25 08:58:30
2	mdlp	2019-04-25 08:59:56
\.


--
-- TOC entry 2990 (class 0 OID 180126)
-- Dependencies: 197
-- Data for Name: booloper; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY booloper (id, bname) FROM stdin;
2	or
1	and
\.


--
-- TOC entry 3316 (class 0 OID 0)
-- Dependencies: 198
-- Name: booloper_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('booloper_id_seq', 2, true);


--
-- TOC entry 2992 (class 0 OID 180131)
-- Dependencies: 199
-- Data for Name: calendar_actions; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY calendar_actions (id, type, title, start, "end", "desc", current_day) FROM stdin;
9	\N	ttt	2019-11-15 13:32:56	2019-11-15 15:32:56	\N	2019-11-15
11	\N	a	2019-11-10 10:33:41	2019-11-10 12:33:41	\N	2019-11-10
12	\N	b	2019-11-07 08:33:46	2019-11-07 11:33:46	\N	2019-11-07
13	\N	c	2019-11-15 13:33:50	2019-11-15 14:30:50	\N	2019-11-15
\.


--
-- TOC entry 3317 (class 0 OID 0)
-- Dependencies: 200
-- Name: calendar_actions_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('calendar_actions_id_seq', 13, true);


--
-- TOC entry 2994 (class 0 OID 180141)
-- Dependencies: 201
-- Data for Name: calendar_test; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY calendar_test (id, calendar_date, month) FROM stdin;
1	2019-01-01	1
2	2019-01-02	1
4	2019-01-03	1
5	2019-01-04	1
6	2019-01-05	1
7	2019-01-06	1
8	2019-01-07	1
9	2019-01-08	1
10	2019-01-09	1
11	2019-01-10	1
12	2019-01-11	1
13	2019-01-12	1
14	2019-01-13	1
15	2019-01-14	1
16	2019-01-15	1
17	2019-01-16	1
18	2019-01-17	1
19	2019-01-18	1
20	2019-01-19	1
21	2019-01-20	1
22	2019-01-21	1
23	2019-11-01	11
24	2019-11-02	11
25	2019-11-03	11
26	2019-11-04	11
27	2019-11-05	11
28	2019-11-06	11
29	2019-11-08	11
30	2019-11-09	11
31	2019-11-10	11
32	2019-11-11	11
33	2019-11-12	11
34	2019-11-13	11
35	2019-11-14	11
36	2019-11-15	11
37	2019-11-16	11
38	2019-11-17	11
39	2019-11-18	11
40	2019-11-19	11
41	2019-11-20	11
42	2019-11-21	11
43	2019-11-22	11
44	2019-11-23	11
45	2019-11-24	11
46	2019-11-25	11
47	2019-11-26	11
48	2019-11-27	11
49	2019-11-28	11
50	2019-11-29	11
51	2019-11-30	11
\.


--
-- TOC entry 3318 (class 0 OID 0)
-- Dependencies: 202
-- Name: calendar_test_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('calendar_test_id_seq', 51, true);


--
-- TOC entry 2996 (class 0 OID 180147)
-- Dependencies: 203
-- Data for Name: columntypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY columntypes (id, typename, viewtypes) FROM stdin;
1	text	["form full","form not mutable"]
2	number	["form full","form not mutable"]
3	date	["form full","form not mutable"]
4	checkbox	["form full","form not mutable"]
5	select	["form full","form not mutable"]
6	typehead	["form full","form not mutable"]
9	password	["form full","form not mutable"]
10	autocomplete	["form full","form not mutable"]
11	multiselect	["form full","form not mutable"]
12	multitypehead	["form full","form not mutable"]
2013	datetime	["form full","form not mutable"]
2014	time	["form full","form not mutable"]
15	select_api	["form full","form not mutable"]
16	typehead_api	["form full","form not mutable"]
17	multiselect_api	["form full","form not mutable"]
18	multitypehead_api	["form full","form not mutable"]
20	textarea	["form full","form not mutable"]
21	texteditor	["form full","form not mutable"]
8	label	["form full","form not mutable","tiles","table"]
7	array	["tiles","table"]
13	color	["form full","form not mutable","tiles","table"]
14	colorpicker	["form full","form not mutable","tiles","table"]
19	link	["form full","form not mutable","tiles","table"]
22	colorrow	["form full","form not mutable","tiles","table"]
1010	file	["form full","form not mutable","tiles","table"]
1011	files	["form full","form not mutable","tiles","table"]
1012	image	["form full","form not mutable","tiles","table"]
1013	images	["form full","form not mutable","tiles","table"]
2011	gallery	["form full","form not mutable","tiles","table"]
2012	filelist	["form full","form not mutable","tiles","table"]
23	certificate	["form full","form not mutable"]
24	innerHtml	["form full","form not mutable"]
26	calendarEndDate	["calendar"]
25	calendarStartDate	["calendar"]
27	calendarTitle	["form full","form not mutable"]
\.


--
-- TOC entry 3319 (class 0 OID 0)
-- Dependencies: 204
-- Name: columntypes_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('columntypes_id_seq', 27, true);


--
-- TOC entry 2998 (class 0 OID 180157)
-- Dependencies: 205
-- Data for Name: compos; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY compos (id, title, path, config, created) FROM stdin;
2	branches	branches	[{"cols": [{"path": {"id": 32, "path": "branchesform", "descr": "branches form", "label": "branches form", "title": "branches form", "value": "branches form", "rownum": 11, "viewlink": null, "viewtype": "form full", "tablename": "framework.treesbranches", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 30, "path": "branches", "descr": "branches", "label": "branches", "title": "branches", "value": "branches", "rownum": 10, "viewlink": null, "viewtype": "table", "tablename": "framework.treesbranches", "subscrible": true}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-03-14 13:48:10.468984
6	Tree Acts	treesacts	[{"cols": [{"path": {"id": 101, "path": "treesact", "descr": "Trees Act", "label": "Trees Act", "title": "Trees Act", "value": "Trees Act", "rownum": 48, "viewlink": null, "viewtype": "form full", "tablename": "framework.treesacts", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 100, "path": "treesacts", "descr": "Trees Acts", "label": "Trees Acts", "title": "Trees Acts", "value": "Trees Acts", "rownum": 47, "viewlink": null, "viewtype": "table", "tablename": "framework.treesacts", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-04-17 10:28:01.836527
7	Общее сведение	common	[{"cols": [{"path": {"id": 108, "path": "f025_1u", "descr": "Талона 025-1/у", "label": "Талона 025-1/у", "title": "Талона 025-1/у", "value": "Талона 025-1/у", "rownum": 52, "viewlink": "", "viewtype": "form full", "tablename": "emdocs.f025_1u", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}, {"path": null, "heigh": null, "width": null, "rownum": 2}], "rownum": 1}, {"cols": [{"path": null, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-05-23 08:17:30.019554
10	select condition	select_condition	[{"cols": [{"path": {"id": 5066, "path": "select_condition_edit", "descr": "select condition edit", "label": "select condition edit", "title": "select condition edit", "value": "select condition edit", "rownum": 30, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.select_condition", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 5065, "path": "select_condition", "descr": "select condition", "label": "select condition", "title": "select condition", "value": "select condition", "rownum": 29, "viewlink": "", "viewtype": "table", "tablename": "framework.select_condition", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-10-27 14:36:37
11	visible conditions	visible_conditions	[{"cols": [{"path": {"id": 5068, "path": "visibles_condition", "descr": "visibles condition", "label": "visibles condition", "title": "visibles condition", "value": "visibles condition", "rownum": 32, "viewlink": "", "viewtype": "form full", "tablename": "framework.visible_condition", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 5067, "path": "visibles_conditions", "descr": "visibles conditions", "label": "visibles conditions", "title": "visibles conditions", "value": "visibles conditions", "rownum": 31, "viewlink": "", "viewtype": "table", "tablename": "framework.visible_condition", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-10-27 17:14:47
12	default value	defaultval	[{"cols": [{"path": {"id": 5070, "path": "default_value", "descr": "default value", "label": "default value", "title": "default value", "value": "default value", "rownum": 34, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.defaultval", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 5069, "path": "default_values", "descr": "default values", "label": "default values", "title": "default values", "value": "default values", "rownum": 33, "viewlink": "", "viewtype": "table", "tablename": "framework.defaultval", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-10-27 21:27:14
8	action parametrs	act_params	[{"cols": [{"path": {"id": 5076, "path": "action's parametr", "descr": "action's parametr", "label": "parametr", "title": "parametr", "value": "parametr", "rownum": 40, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.act_parametrs", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 243, "key": "parametrs", "path": "parametrs", "descr": "ACTIONS PARAMETERS", "title": "parametrs", "rownum": 133, "viewlink": "", "viewtype": "table", "tablename": "framework.act_parametrs", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-10-29 16:36:50
26	act visible conditions	act_visible_conditions	[{"cols": [{"path": {"id": 5079, "path": "act_visible", "descr": "act visible condition", "label": "act visible condition", "title": "act visible condition", "value": "act visible condition", "rownum": 42, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.act_visible_condions", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [{"path": {"id": 5077, "path": "act_visible_condition", "descr": "visible condition (act)", "label": "visible condition (act)", "title": "visible condition (act)", "value": "visible condition (act)", "rownum": 41, "viewlink": "", "viewtype": "table", "tablename": "framework.act_visible_condions", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 2}]	2019-10-29 17:48:04
1	View	view	[{"cols": [{"path": {"id": 5060, "path": "view", "descr": "this is for admins views main information", "label": "View", "title": "View", "value": "View", "rownum": 26, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.views", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 1}, {"cols": [], "rownum": 2}, {"cols": [], "rownum": 3}, {"cols": [{"path": {"id": 5081, "path": "colinconf", "descr": "add column in config", "label": "add column", "title": "add column", "value": "add column", "rownum": 44, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.config", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 5}, {"cols": [{"path": {"id": 5061, "path": "configs", "descr": "View's column's configuration", "label": "Columns config", "title": "Columns config", "value": "Columns config", "rownum": 27, "viewlink": "", "viewtype": "table", "tablename": "framework.config", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 7}, {"cols": [{"path": {"id": 5080, "path": "fncol", "descr": "add function column in config", "label": "add function column", "title": "add function column", "value": "add function column", "rownum": 43, "viewlink": "", "viewtype": "form not mutable", "tablename": "framework.config", "subscrible": false}, "heigh": null, "width": "", "rownum": 1}], "rownum": 8}, {"cols": [{"path": {"id": 5071, "path": "filters", "descr": "filters", "label": "filters", "title": "filters", "value": "filters", "rownum": 35, "viewlink": "", "viewtype": "table", "tablename": "framework.filters", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 10}, {"cols": [{"path": {"id": 5073, "path": "acts", "descr": "view's actions", "label": "actions", "title": "actions", "value": "actions", "rownum": 37, "viewlink": "", "viewtype": "table", "tablename": "framework.actions", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 12}]	2019-10-24 16:16:10
117	Report	reportone	[{"cols": [], "rownum": 2}, {"cols": [{"path": {"id": 119, "key": "Report", "path": "reportone", "descr": "reports add/edit", "title": "Report", "rownum": 16, "viewlink": "", "viewtype": "form not mutable", "tablename": "reports.reportlist", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 3}, {"cols": [{"path": {"id": 121, "key": "report parametrs", "path": "reportparam", "descr": "report parametrs", "title": "report parametrs", "rownum": 18, "viewlink": "", "viewtype": "form not mutable", "tablename": "reports.reportparams", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 4}, {"cols": [{"path": {"id": 120, "key": "Reports parametrs", "path": "reportparams", "descr": "Reports parametrs", "title": "Reports parametrs", "rownum": 17, "viewlink": "", "viewtype": "table", "tablename": "reports.reportparams", "subscrible": false}, "heigh": null, "width": null, "rownum": 1}], "rownum": 5}]	2019-06-25 16:06:27
\.


--
-- TOC entry 3320 (class 0 OID 0)
-- Dependencies: 206
-- Name: compos_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('compos_id_seq', 126, true);


--
-- TOC entry 3000 (class 0 OID 180168)
-- Dependencies: 207
-- Data for Name: config; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY config (id, viewid, t, col, column_id, title, type, roles, visible, required, width, "join", classname, updatable, relation, select_api, multiselecttable, orderby, orderbydesc, relcol, depency, created, relationcolums, multicolums, depencycol, column_order, fn, fncolumns, relatecolumn, "table", related, tpath, editable, copy) FROM stdin;
20081	218	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
20082	218	2	text	2	text	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
20083	218	3	data	3	data	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
20084	218	4	check	4	check	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
20085	218	5	time	5	time	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
20086	218	6	password	6	password	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
20087	218	7	color	7	color	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
20088	218	8	multiselect	8	multiselect	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
20089	218	9	file	9	file	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13111	236	11	photo	14	Фото	image	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	50	\N	\N	\N	\N	f	[]	f	f
20090	218	10	typehead	10	typehead	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:48.541076	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
20091	218	11	image	11	image	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
20092	218	12	images	12	images	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
20093	218	13	gallery	13	gallery	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
20094	218	14	label	14	label	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
20095	218	15	number	15	number	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
20096	218	16	link	16	link	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
20097	218	17	texteditor	17	texteditor	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	17	\N	\N	\N	\N	f	[]	f	f
20098	218	18	colorrow	18	colorrow	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	18	\N	\N	\N	\N	f	[]	f	f
20099	218	19	multitypehead_api	19	multitypehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	19	\N	\N	\N	\N	f	[]	f	f
20100	218	20	multi_select_api	20	multi_select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	20	\N	\N	\N	\N	f	[]	f	f
20101	218	21	colorpicker	21	colorpicker	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	21	\N	\N	\N	\N	f	[]	f	f
20102	218	22	select	22	select	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:48.541076	[]	[]	\N	22	\N	\N	\N	\N	f	[]	f	f
20103	218	23	autocomplete	23	autocomplete	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	23	\N	\N	\N	\N	f	[]	f	f
20104	218	24	textarea	24	textarea	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	24	\N	\N	\N	\N	f	[]	f	f
20105	218	25	files	25	files	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	25	\N	\N	\N	\N	f	[]	f	f
20106	218	26	typehead_api	26	typehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	26	\N	\N	\N	\N	f	[]	f	f
20107	218	27	select_api	27	select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	27	\N	\N	\N	\N	f	[]	f	f
20108	218	28	multitypehead	28	multitypehead	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	28	\N	\N	\N	\N	f	[]	f	f
20109	218	29	datetime	29	datetime	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	29	\N	\N	\N	\N	f	[]	f	f
20110	218	30	html	30	html	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:48.541076	[]	[]	\N	30	\N	\N	\N	\N	f	[]	f	f
20111	218	31	relate_with_major	31	relate_with_major	array	[]	f	f		f		f	test.relate_with_major	\N	\N	f	f	\N	t	2019-12-31 14:50:48.541076	[]	[]	major_table_id	31	\N	\N	\N	\N	f	[]	f	f
20112	215	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
20113	215	2	text	2	text	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
20114	215	3	data	3	data	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
20115	215	4	check	4	check	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
20116	215	5	time	5	time	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
20117	215	6	password	6	password	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
20118	215	7	color	7	color	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
20119	215	8	multiselect	8	multiselect	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
20120	215	9	file	9	file	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
20121	215	10	typehead	10	typehead	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:49.878765	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
20122	215	11	image	11	image	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
20123	215	12	images	12	images	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
20124	215	13	gallery	13	gallery	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
20125	215	14	label	14	label	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
20126	215	15	number	15	number	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
20127	215	16	link	16	link	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
20128	215	17	texteditor	17	texteditor	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	17	\N	\N	\N	\N	f	[]	f	f
19975	236	14	Организации	\N	Организации	label	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-12-30 08:51:17.474284	[]	[]	\N	81	public.fn_users_getorgs	[13114]	\N	\N	f	[]	f	f
20129	215	18	colorrow	18	colorrow	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	18	\N	\N	\N	\N	f	[]	f	f
20130	215	19	multitypehead_api	19	multitypehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	19	\N	\N	\N	\N	f	[]	f	f
20131	215	20	multi_select_api	20	multi_select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	20	\N	\N	\N	\N	f	[]	f	f
20132	215	21	colorpicker	21	colorpicker	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	21	\N	\N	\N	\N	f	[]	f	f
20133	215	22	select	22	select	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:49.878765	[]	[]	\N	22	\N	\N	\N	\N	f	[]	f	f
20134	215	23	autocomplete	23	autocomplete	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	23	\N	\N	\N	\N	f	[]	f	f
20135	215	24	textarea	24	textarea	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	24	\N	\N	\N	\N	f	[]	f	f
20136	215	25	files	25	files	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	25	\N	\N	\N	\N	f	[]	f	f
20137	215	26	typehead_api	26	typehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	26	\N	\N	\N	\N	f	[]	f	f
20138	215	27	select_api	27	select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	27	\N	\N	\N	\N	f	[]	f	f
20139	215	28	multitypehead	28	multitypehead	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	28	\N	\N	\N	\N	f	[]	f	f
20140	215	29	datetime	29	datetime	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	29	\N	\N	\N	\N	f	[]	f	f
20141	215	30	html	30	html	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:49.878765	[]	[]	\N	30	\N	\N	\N	\N	f	[]	f	f
20142	215	31	relate_with_major	31	relate_with_major	array	[]	f	f		f		f	test.relate_with_major	\N	\N	f	f	\N	t	2019-12-31 14:50:49.878765	[]	[]	major_table_id	31	\N	\N	\N	\N	f	[]	f	f
20143	220	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
20144	220	2	text	2	text	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
20145	220	3	data	3	data	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
20146	220	4	check	4	check	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
20147	220	5	time	5	time	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
20148	220	6	password	6	password	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
20149	220	7	color	7	color	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
20150	220	8	multiselect	8	multiselect	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
20151	220	9	file	9	file	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
20152	220	10	typehead	10	typehead	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:51.178646	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
20153	220	11	image	11	image	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
20154	220	12	images	12	images	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
20155	220	13	gallery	13	gallery	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
20156	220	14	label	14	label	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
13576	221	4	col	4	col title fn	text	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-07 15:37:15.70217	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
20157	220	15	number	15	number	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
20158	220	16	link	16	link	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
20159	220	17	texteditor	17	texteditor	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	17	\N	\N	\N	\N	f	[]	f	f
20160	220	18	colorrow	18	colorrow	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	18	\N	\N	\N	\N	f	[]	f	f
20161	220	19	multitypehead_api	19	multitypehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	19	\N	\N	\N	\N	f	[]	f	f
20162	220	20	multi_select_api	20	multi_select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	20	\N	\N	\N	\N	f	[]	f	f
20163	220	21	colorpicker	21	colorpicker	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	21	\N	\N	\N	\N	f	[]	f	f
20164	220	22	select	22	select	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:51.178646	[]	[]	\N	22	\N	\N	\N	\N	f	[]	f	f
13644	228	9	api_type	9	api_type	select	[]	t	f	\N	f	\N	f	framework.methodtypes	\N	\N	f	f	methotypename	f	2019-11-08 11:08:46.710689	["methotypename"]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
20165	220	23	autocomplete	23	autocomplete	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	23	\N	\N	\N	\N	f	[]	f	f
20166	220	24	textarea	24	textarea	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	24	\N	\N	\N	\N	f	[]	f	f
20167	220	25	files	25	files	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	25	\N	\N	\N	\N	f	[]	f	f
20168	220	26	typehead_api	26	typehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	26	\N	\N	\N	\N	f	[]	f	f
20169	220	27	select_api	27	select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	27	\N	\N	\N	\N	f	[]	f	f
20170	220	28	multitypehead	28	multitypehead	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	28	\N	\N	\N	\N	f	[]	f	f
20171	220	29	datetime	29	datetime	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	29	\N	\N	\N	\N	f	[]	f	f
20172	220	30	html	30	html	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:51.178646	[]	[]	\N	30	\N	\N	\N	\N	f	[]	f	f
20173	220	31	relate_with_major	31	relate_with_major	array	[]	f	f		f		f	test.relate_with_major	\N	\N	f	f	\N	t	2019-12-31 14:50:51.178646	[]	[]	major_table_id	31	\N	\N	\N	\N	f	[]	f	f
20174	219	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
20175	219	2	text	2	text	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
20176	219	3	data	3	data	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
20177	219	4	check	4	check	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
20178	219	5	time	5	time	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
20179	219	6	password	6	password	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
20180	219	7	color	7	color	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
20181	219	8	multiselect	8	multiselect	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
20182	219	9	file	9	file	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
20183	219	10	typehead	10	typehead	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:52.443351	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
20184	219	11	image	11	image	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
20185	219	12	images	12	images	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
20186	219	13	gallery	13	gallery	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
13577	242	13	val_desc	13	col	select_api	[]	t	f	\N	f	\N	f	framework.config	/api/tabcolumns_for_filters	\N	f	f	id	f	2019-11-07 16:03:45.333515	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
20187	219	14	label	14	label	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
20188	219	15	number	15	number	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
20189	219	16	link	16	link	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
20190	219	17	texteditor	17	texteditor	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	17	\N	\N	\N	\N	f	[]	f	f
20191	219	18	colorrow	18	colorrow	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	18	\N	\N	\N	\N	f	[]	f	f
20192	219	19	multitypehead_api	19	multitypehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	19	\N	\N	\N	\N	f	[]	f	f
20193	219	20	multi_select_api	20	multi_select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	20	\N	\N	\N	\N	f	[]	f	f
20194	219	21	colorpicker	21	colorpicker	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	21	\N	\N	\N	\N	f	[]	f	f
20195	219	22	select	22	select	label	[]	t	f		f		f	test.dictionary_for_select	\N	\N	f	f	id	f	2019-12-31 14:50:52.443351	[]	[]	\N	22	\N	\N	\N	\N	f	[]	f	f
13647	239	30	table	30	table	label	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-09 09:06:53.086775	[]	[]	\N	28	\N	\N	\N	\N	f	[]	f	f
20196	219	23	autocomplete	23	autocomplete	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	23	\N	\N	\N	\N	f	[]	f	f
20197	219	24	textarea	24	textarea	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	24	\N	\N	\N	\N	f	[]	f	f
20198	219	25	files	25	files	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	25	\N	\N	\N	\N	f	[]	f	f
20199	219	26	typehead_api	26	typehead_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	26	\N	\N	\N	\N	f	[]	f	f
20200	219	27	select_api	27	select_api	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	27	\N	\N	\N	\N	f	[]	f	f
20201	219	28	multitypehead	28	multitypehead	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	28	\N	\N	\N	\N	f	[]	f	f
20202	219	29	datetime	29	datetime	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	29	\N	\N	\N	\N	f	[]	f	f
20203	219	30	html	30	html	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:50:52.443351	[]	[]	\N	30	\N	\N	\N	\N	f	[]	f	f
20204	219	31	relate_with_major	31	relate_with_major	array	[]	f	f		f		f	test.relate_with_major	\N	\N	f	f	\N	t	2019-12-31 14:50:52.443351	[]	[]	major_table_id	31	\N	\N	\N	\N	f	[]	f	f
20221	5542	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-31 14:56:02.682963	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12914	221	3	t	3	t	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
16467	5542	17	orgid	14	МО	select_api	[]	t	f		f		f	framework.orgs	/api/userorgss	\N	f	f	id	f	2019-12-09 18:09:00	["id", "orgname"]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
12701	224	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12702	224	2	configid	2	configid	label	[]	f	t		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["title"]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12704	224	5	operation	5	operation	label	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12705	224	6	value	6	value	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13011	56	1	id	1	id	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13067	32	1	id	1	bid	label	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13189	242	1	id	1	fl_id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13190	242	12	column_order	2	column_order	number	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13196	242	7	columns	7	columns	multiselect_api	[]	t	f		f		f	\N	/api/tabcolumns_for_filters_arr	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13197	242	8	roles	8	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	9	\N	\N	\N	\N	f	[]	f	f
13239	224	3	val_desc	3	val_desc	select	[]	f	f	\N	f	\N	f	framework.config	\N	\N	f	f	id	f	2019-11-05 13:50:29.934237	["title"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13198	242	9	t	9	t	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13199	242	10	table	10	table	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
13200	242	11	created	11	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
13210	244	1	id	1	vs_id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13023	229	8	val_desc	8	val_desc	select_api	[]	t	f		f		f	framework.config	/api/view_cols_for_param	\N	f	f	id	f	2019-11-05 10:00:17.290746	["id", "title"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12752	211	4	ismainmenu	4	is main menu	checkbox	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13119	237	\N	tit	\N	view title	link	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	framework.fn_view_title_link	[13117,13118]		\N	t	null	f	f
13261	238	1	SHOW SQL	\N	SHOW SQL	link	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-06 09:00:53.832788	[]	[]	\N	21	framework.fn_view_link_showsql	[13130]	\N	\N	f	[]	f	f
12706	224	7	created	7	created	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13240	224	3	title	\N	title	label	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 13:57:11.162051	[]	[]	\N	1	\N	\N	val_desc	framework.config	t	[]	f	f
12707	44	1	id	1	id	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12708	44	2	viewid	2	viewid	number	[]	f	f		f	\N	f	framework.views	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12709	44	3	col	3	col	text	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12710	44	4	tableid	4	tableid	text	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12711	44	5	notificationtext	5	notificationtext	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12712	44	6	foruser	6	foruser	number	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12713	44	7	issend	7	issend	checkbox	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12714	44	8	isread	8	isread	checkbox	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12715	44	9	created	9	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
12716	44	10	sended	10	sended	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
12717	44	11	readed	11	readed	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
12749	211	1	id	1	id	number	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12750	211	3	menutitle	3	menu title	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12751	211	2	menutype	2	menu type	select	[]	t	f		f	col-md-11	f	framework.menutypes	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["id","mtypename"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12965	55	8	created	9	created	label	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13068	32	2	treesid	2	treesid	label	[]	f	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13069	32	3	title	3	title	text	[]	t	f		f	col-md-12	t	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13070	32	5	parentid	5	parentid	select	[]	t	f		f	col-md-12	f	framework.treesbranches	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["id","title"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13071	32	6	icon	6	icon	text	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13072	32	7	created	7	created	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13073	32	15	treeviewtype	8	treeviewtype	select	[]	t	f		f	col-md-12	f	framework.treeviewtypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["id","typename"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13074	32	23	viewid	9	viewid	select	[]	t	f		f	col-md-12	f	framework.views	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["id","title","path"]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13075	32	14	compoid	10	compoid	select	[]	t	f		f	col-md-12	f	framework.compos	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["id","title"]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13076	32	10	orderby	11	orderby	number	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13077	32	11	ismain	12	ismain	checkbox	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
12832	34	1	id	1	id	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12833	34	2	orgname	2	orgname	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12958	55	1	id	1	id	number	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12964	55	7	isactive	8	isactive	checkbox	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12966	55	9	roles	11	roles	label	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
12967	55	10	roleid	12	roleid	number	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
12968	55	12	orgs	15	orgs	label	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
12969	55	13	usersettings	16	usersettings	text	[]	f	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
12970	55	14	orgid	17	orgid	number	[]	f	f		f	col-md-11 form-group row	f	framework.orgs	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["orgname"]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
12972	55	11	photo	14	photo	image	[]	t	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
13012	56	10	userid	10	userid	number	[]	f	f		f	col-md-12	f	framework.users	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["login"]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13013	56	2	tablename	2	tablename	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13014	56	3	tableid	3	tableid	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13015	56	4	opertype	4	opertype	label	[]	f	f		f	col-md-12	f	framework.opertypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["typename"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13016	56	10	login	\N	login	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	userid	framework.users	t	[]	f	f
13017	56	6	oldata	6	oldata	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13018	56	7	newdata	7	newdata	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13019	56	8	created	8	created	label	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
12960	55	3	im	3	First Name	label	[]	t	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12961	55	4	ot	4	Second Name	label	[]	t	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12962	55	5	login	5	Login	label	[]	t	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12963	55	6	password	6	Password	password	[]	t	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12971	55	14	orgname	\N	Orgname	label	[]	t	f	\N	f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	orgid	framework.orgs	t	[]	f	f
12784	214	1	id	1	id	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12785	214	2	title	2	title	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12786	214	3	path	3	path	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12787	214	4	config	4	config	text	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12788	214	5	created	5	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12973	226	1	id	1	CN	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12974	226	2	configid	2	configid	label	[]	f	t		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12978	226	6	created	6	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12995	228	1	id	1	act_id	label	[]	f	f		f		f	\N	\N	\N	t	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12996	228	2	column_order	2	order by	number	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12997	228	3	title	3	act title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12998	228	16	act_type	16	act_type	select	[]	t	f		f		f	framework.acttypes	\N	\N	f	f	actname	f	2019-11-05 10:00:17.290746	["actname"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12999	228	4	viewid	4	id	label	[]	f	t		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13000	228	5	icon	5	act icon	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13001	228	6	classname	6	class name	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13002	228	7	act_url	7	act url	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13003	228	8	api_method	8	api method	select	[]	t	f		f		f	framework.apicallingmethods	\N	\N	f	f	aname	f	2019-11-05 10:00:17.290746	["aname"]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13005	228	10	refresh_data	10	refresh data	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
13006	228	11	ask_confirm	11	ask confirm	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
13007	228	12	roles	12	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	13	\N	\N	\N	\N	f	[]	f	f
13008	228	13	forevery	13	for every row	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
13009	228	14	main_action	14	main_action	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
13010	228	15	created	15	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
13028	230	6	title	6	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13029	230	27	fn	27	function	select_api	[]	t	f		f		f	\N	/api/getfunctions	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13030	230	28	fncolumns	28	columns	multiselect_api	[]	t	f		f		f	\N	/api/view_cols_for_fn	framework.config	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13031	230	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13032	231	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13033	231	3	val_desc	3	val_desc	label	[]	t	f		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["title"]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13034	231	2	actionid	2	act_id	label	[]	f	t		f		f	framework.actions	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13035	231	3	title	\N	column title	label	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	val_desc	framework.config	t	[]	f	f
13036	231	6	operation	6	operation	label	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13037	231	7	value	7	value	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13038	231	8	created	8	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13039	232	4	col	4	column title	select_api	[]	t	f		f		f	\N	/api/config_selectapi	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12976	226	4	act	4	Action	select	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	["value"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12977	226	5	value	5	Value	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13040	232	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13085	234	1	id	1	id	number	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13086	234	2	title	2	title	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13087	234	8	path	8	path	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13088	234	4	roles	4	roles	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13089	234	6	systemfield	6	systemfield	checkbox	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13090	234	9	icon	10	icon	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13091	234	3	parentid	3	parentid	select	[]	f	f		f	\N	f	framework.mainmenu	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["title"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13092	234	3	title	\N	parent	text	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	parentid	framework.mainmenu	t	[]	f	f
13093	234	7	orderby	7	orderby	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13094	234	5	created	5	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13212	244	3	val_desc	3	val_desc	select_api	[]	t	f		f		f	framework.config	/api/view_cols_for_param	\N	f	f	id	f	2019-11-05 10:00:17.290746	["id", "title"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13095	234	10	menuid	10	menuid	number	[]	f	f		f		f	framework.menus	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
13191	242	2	viewid	2	id	label	[]	f	t		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13192	242	3	title	3	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13193	242	4	type	4	type	select	[]	t	f		f		f	framework.filtertypes	\N	\N	f	f	ftname	f	2019-11-05 10:00:17.290746	["ftname"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13194	242	5	classname	5	classname	text	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13211	244	2	actionid	2	actionid	label	[]	f	t		f		f	framework.actions	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13213	244	6	operation	6	operation	select	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	["value"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13214	244	7	value	7	value	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13215	244	8	created	8	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
19974	236	13	Роли	\N	Роли	label	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-12-30 08:49:48.46858	[]	[]	\N	71	public.fn_users_getroles	[13113]	\N	\N	f	[]	f	f
13117	237	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	t	t	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13118	237	2	title	2	title	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13120	237	4	tablename	4	tablename	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13121	237	5	vtypename	\N	view type	text	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	viewtype	framework.viewtypes	t	[]	f	f
13122	237	3	descr	3	descr	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13123	237	8	path	8	path	link	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13124	237	5	viewtype	5	viewtype	label	[]	f	f		f		f	framework.viewtypes	\N	\N	f	f	vtypename	f	2019-11-05 10:00:17.290746	["vtypename"]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12839	217	1	id	1	id	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12840	217	6	methodtype	6	methodtype	select	[]	f	f		f	\N	f	framework.methodtypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["methotypename"]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12841	217	2	methodname	2	method name	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12842	217	3	procedurename	3	procedure name	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12843	217	6	methotypename	\N	methotypename	text	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	methodtype	framework.methodtypes	t	[]	f	f
12844	217	4	roles	4	roles	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12845	217	5	created	5	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12753	225	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12754	225	2	configid	2	configid	label	[]	f	f		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12758	225	6	created	6	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12759	100	1	id	1	id	number	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12760	100	2	treesid	2	treesid	number	[]	f	f		f	\N	f	framework.trees	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12761	100	3	title	3	title	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12762	100	4	icon	4	icon	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12763	100	5	classname	5	classname	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12764	100	6	act	6	act	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12765	100	7	created	7	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12766	212	1	id	1	N	number	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12768	212	2	methodname	2	method name	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12769	212	6	methodtype	6	methodtype	select	[]	t	f		f	col-md-11	f	framework.methodtypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["id","methotypename"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12770	212	4	roles	4	roles	multiselect	[]	t	f		f	col-md-11	f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	5	\N	\N	\N	\N	f	[]	f	f
12771	212	5	created	5	created	label	[]	f	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12772	213	2	fam	2	fam	text	[]	t	f		f	col-md-11	t	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12773	213	3	im	3	im	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12774	213	4	ot	4	ot	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12775	213	5	login	5	login	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12776	213	6	password	6	password	password	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12777	213	8	isactive	8	isactive	checkbox	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12778	213	9	created	9	created	label	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12779	213	10	roles	11	roles	multiselect	[]	t	f		f	col-md-11	f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	8	\N	\N	\N	\N	f	[]	f	f
12780	213	12	orgs	12	orgs	multiselect	[]	t	f		f	col-md-11	f	\N	\N	framework.orgs	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","orgname"]	\N	9	\N	\N	\N	\N	f	[]	f	f
12781	213	1	id	1	id	number	[]	f	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
12782	213	11	roleid	12	roleid	number	[]	f	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
12783	213	12	photo	13	photo	image	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
12756	225	4	act	4	Action	select	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	["id","value"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12757	225	5	value	5	Value	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12834	150	1	id	1	id	number	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12835	150	3	menutitle	3	menu title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12836	150	2	mtypename	\N	menu type	text	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	menutype	framework.menutypes	t	[]	f	f
12837	150	4	ismainmenu	4	is main menu	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12838	150	2	menutype	2	menutype	number	[]	f	f		f		f	framework.menutypes	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["mtypename"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12822	216	1	id	1	id	number	[0]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12823	216	2	tablename	2	tablename	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12824	216	3	tableid	3	tableid	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12825	216	4	typename	\N	typename	text	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	opertype	framework.opertypes	t	[]	f	f
12826	216	10	userid	10	userid	number	[]	f	f		f	\N	f	framework.users	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["login"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12827	216	4	opertype	4	opertype	select	[]	f	f		f	\N	f	framework.opertypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["typename"]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12828	216	10	login	\N	login	text	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	userid	framework.users	t	[]	f	f
12829	216	6	oldata	6	oldata	text	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12830	216	7	newdata	7	newdata	text	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
12831	216	8	created	8	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
12912	221	1	id	1	N	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12913	221	2	viewid	2	id	label	[]	f	f		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["viewtype"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12915	221	4	col	4	column title	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12916	221	5	column_id	5	column_id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12917	221	6	title	6	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12918	221	7	type	7	type	select	[]	t	f		f		f	framework.columntypes	\N	\N	f	f	typename	f	2019-11-05 10:00:17.290746	["typename"]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12919	221	27	fn	27	fn	select_api	[]	t	f		f		f	\N	/api/getfunctions	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
12921	221	8	roles	8	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	11	\N	\N	\N	\N	f	[]	f	f
12922	221	9	visible	9	visible	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
12923	221	10	required	10	is required	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
12924	221	11	width	11	width	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
12925	221	12	join	12	join	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
12926	221	13	classname	13	classname	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
12927	221	14	updatable	14	updatable	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	17	\N	\N	\N	\N	f	[]	f	f
12928	221	16	select_api	16	select_api	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	18	\N	\N	\N	\N	f	[]	f	f
12929	221	18	orderby	18	order by	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	19	\N	\N	\N	\N	f	[]	f	f
12930	221	19	orderbydesc	19	order by desc	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	20	\N	\N	\N	\N	f	[]	f	f
12931	221	15	relation	15	relation table	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	21	\N	\N	\N	\N	f	[]	f	f
12932	221	17	multiselecttable	17	multiselecttable	select_api	[]	t	f		f		f	\N	/api/gettables	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	22	\N	\N	\N	\N	f	[]	f	f
12933	221	20	relcol	20	relcol	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	23	\N	\N	\N	\N	f	[]	f	f
12934	221	21	depency	21	 is depency	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	24	\N	\N	\N	\N	f	[]	f	f
12935	221	24	multicolums	24	multicolums	multiselect_api	[]	t	f		f		f	\N	/api/multi_tabcolumns	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	25	\N	\N	\N	\N	f	[]	f	f
12936	221	23	relationcolums	23	relationcolums	multiselect_api	[]	t	f		f		f	\N	/api/rel_tabcolumns	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	26	\N	\N	\N	\N	f	[]	f	f
12937	221	25	depencycol	25	depencycol	label	[]	f	f		f		f	\N	/api/dep_tabcolumns	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	27	\N	\N	\N	\N	f	[]	f	f
12938	221	29	defaultval	29	defaultval	array	[]	t	f		f		f	framework.defaultval	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	[]	[]	configid	28	\N	\N	\N	\N	f	[]	f	f
12939	221	30	select_condition	29	select_condition	array	[]	t	f		f		f	framework.select_condition	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	["col","operation","const","val_desc"]	[]	configid	29	\N	\N	\N	\N	f	[]	f	f
12940	221	31	visible_condition	29	visible_condition	array	[]	t	f		f		f	framework.visible_condition	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	[]	[]	configid	30	\N	\N	\N	\N	f	[]	f	f
12942	222	1	id	1	CN	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12943	222	2	configid	2	N	label	[]	f	t		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12944	222	3	col	3	col	select_api	[]	t	f		f		f	\N	/api/tabcolumns_for_sc	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12945	222	5	operation	5	operation	select	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	["value"]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12946	222	9	val_desc	9	val_desc	select_api	[]	t	f		f		f	\N	/api/view_cols_for_sc	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12947	222	6	const	6	const	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12948	222	7	value	7	value	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12949	222	8	created	8	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12950	223	1	id	1	CN	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
12951	223	2	configid	2	configid	label	[]	f	t		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12952	223	8	val_desc	3	val_desc	select_api	[]	t	f		f		f	framework.config	/api/view_cols_for_sc	\N	f	f	id	f	2019-11-05 10:00:17.290746	["id","title"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
12953	223	3	col	3	col	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
12954	223	4	title	4	title	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
12955	223	5	operation	5	operation	select	[]	t	f		f		f	framework.operations	\N	\N	f	f	value	f	2019-11-05 10:00:17.290746	["value"]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
12956	223	6	value	6	value	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
12957	223	7	created	7	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12983	227	4	viewid	4	id	label	[]	f	t		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13020	229	1	id	1	paramid	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13021	229	2	actionid	2	act_id	label	[]	f	t		f		f	framework.actions	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13022	229	3	paramtitle	3	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13024	229	5	paramconst	5	const	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13025	229	6	paraminput	6	input	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13026	229	4	paramt	4	method type	select	[]	t	f		f		f	framework.paramtypes	\N	\N	f	f	val	f	2019-11-05 10:00:17.290746	["val"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13027	229	9	query_type	9	query type	select	[]	t	f		f		f	framework.actparam_querytypes	\N	\N	f	f	aqname	f	2019-11-05 10:00:17.290746	["aqname"]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13045	26	1	id	1	id	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13046	26	2	title	2	title	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13047	26	3	url	3	url	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13048	26	4	descr	4	descr	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13049	26	5	roles	5	roles	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13050	26	6	created	6	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13051	28	1	id	1	id	label	[]	f	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13052	28	2	title	2	title	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13053	28	3	url	3	url	text	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13054	28	4	descr	4	descr	textarea	[]	t	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13055	28	5	roles	5	roles	multiselect	[]	t	f		f	col-md-11	f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	5	\N	\N	\N	\N	f	[]	f	f
13056	28	6	created	6	created	label	[]	f	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13057	30	1	id	1	id	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13058	30	2	treesid	2	treesid	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13059	30	3	title	3	title	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13061	30	6	icon	6	icon	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13062	30	7	created	7	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13063	30	7	treeviewtype	8	treeviewtype	number	[]	t	f		f	\N	f	framework.treeviewtypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13065	30	9	compoid	10	compoid	number	[]	f	f		f	\N	f	framework.compos	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13041	233	2	viewid	2	viewid	label	[]	f	f		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13042	233	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13043	233	6	title	6	setting	select_api	[]	t	f		f		f	\N	/api/configsettings_selectapi	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13044	233	4	col	4	column	select_api	[]	t	f		f		f	\N	/api/view_cols_for_fn	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13078	101	1	id	1	bid	number	[]	f	f	30%	f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13079	101	2	treesid	2	treesid	number	[]	f	f	30%	f	col-md-11	f	framework.trees	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13080	101	3	title	3	title	text	[]	t	f	30%	f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13081	101	4	icon	4	icon	text	[]	t	f	30%	f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13082	101	5	classname	5	classname	text	[]	t	f	30%	f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13083	101	6	act	6	act	text	[]	t	f	30%	f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13084	101	7	created	7	created	date	[]	f	f		f	col-md-11	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13096	235	1	id	1	id	label	[]	f	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13097	235	2	title	2	title	text	[]	t	f		f	col-md-12	t	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13098	235	3	parentid	3	parent	select	[]	t	f		f	col-md-12	f	framework.mainmenu	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	["id","title"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13099	235	4	roles	4	roles	multiselect	[]	t	f		f	col-md-12	f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	4	\N	\N	\N	\N	f	[]	f	f
13100	235	5	created	5	created	label	[]	f	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13101	235	6	systemfield	6	system field	checkbox	[]	f	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13102	235	7	orderby	7	order by	number	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13103	235	8	path	8	path	text	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13104	235	10	test	10	test	array	[]	f	f		f	col-md-12	f	framework.test	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	[]	[]	relat	9	\N	\N	\N	\N	f	[]	f	f
13105	235	9	icon	10	icon	text	[]	t	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13106	235	11	menuid	10	menuid	number	[]	f	f		f	col-md-12	f	framework.menus	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
13129	238	3	descr	3	descr	textarea	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13125	238	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13126	238	4	tablename	4	table name	select_api	[]	t	f		f		f	\N	/api/gettables	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13127	238	21	tablename	4	tablename	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13128	238	2	title	2	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13130	238	8	path	8	path	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13131	238	5	viewtype	5	viewtype	select	[]	t	f		f		f	framework.viewtypes	\N	\N	f	f	vtypename	f	2019-11-05 10:00:17.290746	["vtypename"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13132	238	13	roles	13	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	8	\N	\N	\N	\N	f	[]	f	f
13133	238	14	classname	14	classname	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13134	238	6	pagination	6	pagination	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13135	238	15	orderby	15	orderby	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
13136	238	16	ispagesize	16	ispagesize	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
13137	238	17	pagecount	17	pagecount	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
13138	238	18	foundcount	18	foundcount	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
13139	238	19	subscrible	19	subscrible	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
13140	238	20	checker	20	checker	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
13060	30	5	parentid	5	parentid	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	t	f
13116	236	9	created	9	created	date	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	100	\N	\N	\N	\N	f	[]	f	f
13115	236	8	isactive	8	isactive	checkbox	[]	f	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	90	\N	\N	\N	\N	f	[]	f	f
13114	236	12	orgs	15	orgs	multiselect	[]	f	f		f	\N	f	\N	\N	framework.orgs	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["orgname"]	\N	80	\N	\N	\N	\N	f	[]	f	f
13112	236	5	login	5	login	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	60	\N	\N	\N	\N	f	[]	f	f
13110	236	4	ot	4	Отчество	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	40	\N	\N	\N	\N	f	[]	f	f
13109	236	3	im	3	Имя	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	30	\N	\N	\N	\N	f	[]	f	f
13108	236	2	fam	2	Фамилия	text	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	20	\N	\N	\N	\N	f	[]	f	f
13107	236	1	id	1	id	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13113	236	9	roles	11	roles	multiselect	[]	f	f		f	\N	f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["rolename"]	\N	70	\N	\N	\N	\N	f	[]	f	f
13163	239	21	depency	21	depency	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	23	\N	\N	\N	\N	f	[]	f	f
13167	240	1	id	1	cni	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13168	240	2	configid	2	N	label	[]	f	t		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["viewid"]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13169	240	3	col	3	col	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13170	240	5	operation	5	operation	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13171	240	9	val_desc	10	val_desc	label	[]	f	f		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["title"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13172	240	6	const	6	const	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13173	240	7	value	7	val	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13174	240	8	created	8	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13175	240	9	title	\N	value	label	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	val_desc	framework.config	t	[]	f	f
13176	240	2	viewid	\N	viewid	label	[]	f	f	\N	f		f	framework.views	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	configid	framework.config	t	[]	f	f
13178	241	2	viewid	2	id	label	[]	f	t		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13202	243	2	actionid	2	act_id	label	[]	f	t		f		f	framework.actions	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13203	243	3	paramtitle	3	title	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13204	243	8	title	\N	column	label	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	val_desc	framework.config	t	[]	f	f
13205	243	5	paramconst	5	const	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13206	243	6	paraminput	6	input	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13207	243	4	paramt	4	method type	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13208	243	8	val_desc	8	val_desc	label	[]	f	f		f		f	framework.config	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	["title"]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13209	243	9	query_type	9	query type	label	[]	t	f		f		f	framework.actparam_querytypes	\N	\N	f	f	aqname	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13216	245	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13217	245	4	tablename	4	table name	select_api	[]	t	f		f		f	\N	/api/gettables	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
13218	245	21	tablename	4	tablename	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13219	245	2	title	2	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
13220	245	3	descr	3	descr	textarea	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13221	245	8	path	8	path	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
13222	245	5	viewtype	5	viewtype	select	[]	t	f		f		f	framework.viewtypes	\N	\N	f	f	vtypename	f	2019-11-05 10:00:17.290746	["vtypename"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
13223	245	13	roles	13	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	["id","rolename"]	\N	8	\N	\N	\N	\N	f	[]	f	f
13224	245	14	classname	14	classname	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
13225	245	6	pagination	6	pagination	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13226	245	15	orderby	15	orderby	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
13227	245	16	ispagesize	16	ispagesize	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	f	f
13228	245	17	pagecount	17	pagecount	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	13	\N	\N	\N	\N	f	[]	f	f
13229	245	18	foundcount	18	foundcount	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	\N	\N	f	[]	f	f
13230	245	19	subscrible	19	subscrible	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	15	\N	\N	\N	\N	f	[]	f	f
13231	245	20	checker	20	checker	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
13663	221	40	editable	34	is editable cell	checkbox	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-09 09:35:28.103632	[]	[]	\N	21	\N	\N	\N	\N	f	[]	f	f
13201	243	1	id	1	p_id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13145	239	4	col	4	column	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
13165	239	25	depencycol	25	depencycol	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	25	\N	\N	\N	\N	f	[]	f	f
13183	241	6	column	6	column	select_api	[]	t	f		f		f	\N	/api/tabcolumns_for_filters	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
13182	241	5	classname	5	classname	text	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	t	f
12911	221	26	column_order	26	column order	number	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13185	241	8	roles	8	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	["id", "rolename"]	[]	\N	10	\N	\N	\N	\N	f	[]	t	f
13179	241	12	column_order	2	column_order	number	[]	t	f		f		f	\N	\N	\N	t	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	t	f
13180	241	3	title	3	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	4	\N	\N	\N	\N	f	[]	t	f
13181	241	4	type	4	type	select	[]	t	f		f		f	framework.filtertypes	\N	\N	f	f	ftname	f	2019-11-05 10:00:17.290746	["ftname"]	[]	\N	5	\N	\N	\N	\N	f	[]	t	f
13773	239	2	viewtype	\N	viewtype	label	[]	f	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-11 17:02:52.048476	[]	[]	\N	29	\N	\N	viewid	framework.views	t	[]	f	f
13789	241	13	val_desc	13	col	select	[]	t	f	\N	f	\N	f	framework.config	\N	\N	f	f	id	f	2019-11-11 21:53:56.51403	["id", "title"]	[]	\N	7	\N	\N	\N	\N	f	[]	t	f
12981	227	3	title	3	act title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	t	f
12984	227	5	icon	5	act icon	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	t	f
12985	227	6	classname	6	class name	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	t	f
12986	227	7	act_url	7	act url	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	t	f
12987	227	8	api_method	8	api method	select	[]	t	f		f		f	framework.apicallingmethods	\N	\N	f	f	aname	f	2019-11-05 10:00:17.290746	["aname"]	[]	\N	9	\N	\N	\N	\N	f	[]	t	f
12982	227	16	act_type	16	act_type	select	[]	t	f		f		f	framework.acttypes	\N	\N	f	f	actname	f	2019-11-05 10:00:17.290746	["actname"]	[]	\N	4	\N	\N	\N	\N	f	[]	t	f
12980	227	2	column_order	2	order by	number	[]	t	f		f		f	\N	\N	\N	t	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	t	f
13154	239	13	classname	13	classname	text	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	\N	\N	f	[]	t	f
13152	239	11	width	11	width	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	17	\N	\N	\N	\N	f	[]	t	f
13166	239	27	defaultval	27	default value	array	[]	t	f		f		f	framework.defaultval	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	["bool", "act", "value"]	[]	configid	26	\N	\N	\N	\N	f	[]	f	f
12920	221	28	fncolumns	28	fn columns	multiselect_api	[]	t	f		f		f	\N	/api/view_cols_for_fn	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
13184	241	7	columns	7	columns	multiselect_api	[]	t	f		f		f	\N	/api/tabcolumns_for_filters_arr	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	t	f
12992	227	13	forevery	13	for every row	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	14	\N	\N	\N	\N	f	[]	t	f
12993	227	14	main_action	14	main_action	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	15	\N	\N	\N	\N	f	[]	t	f
12989	227	10	refresh_data	10	refresh data	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	t	f
12990	227	11	ask_confirm	11	ask confirm	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	t	f
12991	227	12	roles	12	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	["id", "rolename"]	[]	\N	13	\N	\N	\N	\N	f	[]	t	f
13796	227	9	api_type	9	api_type	select	[]	t	f	\N	f	\N	f	framework.methodtypes	\N	\N	f	f	methotypename	f	2019-11-11 22:21:30.217723	["methotypename"]	[]	\N	10	\N	\N	\N	\N	f	[]	t	f
13177	241	1	id	1	f_id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13847	221	28	fncolumns	28	Function input parametrs	label	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-12 11:19:41.149179	[]	[]	\N	34	\N	\N	\N	\N	f	[]	f	f
12941	221	2	viewtype	\N	viewtype	label	[]	f	f	\N	f		f	framework.viewtypes	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	0	\N	\N	viewid	framework.views	t	[]	f	f
13142	239	1	id	1	key	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12979	227	1	id	1	a_id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13146	239	5	column_id	5	column_id	label	[]	f	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
16153	239	28	fncolumns	28	fn_columns	label	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-12-05 15:54:51.85706	[]	[]	\N	30	\N	\N	\N	\N	f	[]	f	f
13733	239	7	type	7	type	select	[]	t	f	200px	f	\N	f	framework.columntypes	\N	\N	f	f	typename	f	2019-11-11 09:30:09.143427	["typename"]	[]	\N	8	\N	\N	\N	\N	f	[]	t	f
14589	5469	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-15 08:42:17.617568	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
14591	5469	3	type	3	type	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-15 08:42:17.617568	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
14595	5469	7	desc	7	description	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-15 08:42:17.617568	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
14593	5469	5	start	5	start date	calendarStartDate	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-15 08:42:17.617568	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
14594	5469	6	end	6	enddate	calendarEndDate	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-15 08:42:17.617568	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
14592	5469	4	title	4	title	calendarTitle	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-15 08:42:17.617568	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
14967	243	11	order by	12	order by	number	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-20 17:02:33.822277	[]	[]	\N	10	\N	\N	\N	\N	f	[]	t	f
13156	239	18	orderby	18	order by	checkbox	[]	t	f	\N	f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	11	\N	\N	\N	\N	f	[]	t	f
13157	239	19	orderbydesc	19	order by desc	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	12	\N	\N	\N	\N	f	[]	t	f
13155	239	14	updatable	14	updatable	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	13	\N	\N	\N	\N	f	[]	t	f
13241	239	27	fn	27	fn	select_api	[]	t	f		f	\N	f	\N	/api/getfunctions	\N	f	f	\N	f	2019-11-05 14:31:51.940762	[]	[]	\N	1	\N	\N	\N	\N	f	[]	t	f
13147	239	6	title	6	title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	7	\N	\N	\N	\N	f	[]	t	f
13150	239	9	visible	9	visible	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	9	\N	\N	\N	\N	f	[]	t	f
13151	239	10	required	10	required	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	t	f
13153	239	12	join	12	join	checkbox	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	16	\N	\N	\N	\N	f	[]	t	f
13143	239	2	viewid	2	id	label	[]	f	t		f		f	framework.views	\N	\N	f	f	id	f	2019-11-05 10:00:17.290746	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13149	239	8	roles	8	roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	18	\N	\N	\N	\N	f	[]	t	f
13751	239	23	relationcolums	23	relation columns	multiselect_api	[]	t	f	\N	f	\N	f	\N	/api/rel_tabcolumns	\N	f	f	\N	f	2019-11-11 14:49:20.081457	[]	[]	\N	20	\N	\N	\N	\N	f	[]	t	f
13160	239	28	select_condition	27	select condition	text	[]	t	f		f		f	framework.select_condition	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	["val_desc", "operation", "value"]	[]	configid	21	\N	\N	\N	\N	f	[]	f	f
13161	239	29	visible_condition	27	visible condition	array	[]	t	f		f		f	framework.visible_condition	\N	\N	f	f	\N	t	2019-11-05 10:00:17.290746	["val_desc", "operation", "value"]	[]	configid	22	\N	\N	\N	\N	f	[]	f	f
13158	239	\N	relation	\N	relation table	text	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	19	framework.fn_config_relation	[13142]		\N	t	null	t	f
14488	5463	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-14 11:28:40.509753	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
13064	30	8	viewid	9	viewid	number	[]	t	f		f	\N	f	framework.views	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	8	\N	\N	\N	\N	f	[]	t	f
14494	5463	3	month	3	month	label	[]	t	t	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-14 13:09:54.411374	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
14495	5463	4	calendar_actions	4	calendar_actions	array	[]	t	f	\N	f	\N	f	framework.calendar_actions	\N	\N	f	f	\N	t	2019-11-14 13:10:03.839596	["id", "title", "type", "start", "end", "calendar_id", "desc"]	[]	calendar_id	4	\N	\N	\N	\N	f	[]	f	f
15337	5469	7	current_day	8	current_day_6	date	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-25 08:28:21.802253	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
12767	212	3	procedurename	3	function	select_api	[]	t	f		f	col-md-11	f	\N	/api/functions_getall_spapi	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
12755	225	3	bool	3	Bool operator	select	[]	t	f		f		f	framework.booloper	\N	\N	f	f	bname	f	2019-11-05 10:00:17.290746	["id","bname"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13662	239	40	editable	34	editable cell	checkbox	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-09 09:34:37.399096	[]	[]	\N	15	\N	\N	\N	\N	f	[]	t	f
12975	226	3	bool	3	Bool operator	select	[]	t	f		f		f	framework.booloper	\N	\N	f	f	bname	f	2019-11-05 10:00:17.290746	["bname"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
13141	239	26	column_order	26	column order	number	[]	t	f		f		f	\N	\N	\N	t	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	0	\N	\N	\N	\N	f	[]	t	f
12959	55	2	fam	2	Last Name	label	[]	t	f		f	col-md-11 form-group row	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
16656	55	16	thumbprint	17	Certificate	certificate	[]	t	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-12-11 11:15:13.088394	[]	[]	\N	16	\N	\N	\N	\N	f	[]	f	f
13066	30	10	orderby	11	orderby	number	[]	t	f		f	\N	f	\N	\N	\N	f	f	\N	f	2019-11-05 10:00:17.290746	[]	[]	\N	10	\N	\N	\N	\N	f	[]	t	f
14489	5463	2	calendar_date	2	calendar_date	calendarStartDate	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-11-14 11:28:40.509753	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
19396	119	13	id	1	reportlistid	number	[]	f	f		f	col-md-12	f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19368	120	3	ptitle	3	Title	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:45.989848	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
19369	120	4	func_paramtitle	4	Parametr in Function	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:45.989848	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
19426	120	18	colorr	\N	colorr	colorrow	[]	f	f	\N	f	\N	f	\N	\N	\N	f	f	\N	f	2019-12-25 11:15:57.01164	[]	[]	\N	10	public.fn_completed_colorblack	[19373]	\N	\N	f	[]	f	f
19342	118	1	id	1	id	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19344	118	3	roles	3	Roles	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
19377	121	3	ptitle	3	Title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:57:10.533471	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
19364	119	11	filename	11	filename	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
19382	121	8	completed	8	completed	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:57:10.533471	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
19378	121	4	func_paramtitle	4	Paramtr in function	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:57:10.533471	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
19379	121	5	ptype	5	Parametr type	select	[]	t	f		f		f	reports.paramtypes	\N	\N	f	f	id	f	2019-12-25 10:57:10.533471	["id", "typename"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
19381	121	7	apimethod	7	Method	select	[]	t	f		f		f	framework.spapi	\N	\N	f	f	id	f	2019-12-25 10:57:10.533471	["id", "methodname", "procedurename"]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
19355	119	2	title	2	Title	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
19356	119	3	roles	3	Roles	multiselect	[]	t	f		f		f	\N	\N	framework.roles	f	f	\N	f	2019-12-25 10:56:44.415375	["id", "rolename"]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
19357	119	4	path	4	Path	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
19358	119	5	template	5	Template	file	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
19362	119	9	section	9	Section	autocomplete	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
19353	118	12	reportparams	12	reportparams	array	[]	f	f		f		f	reports.reportparams	\N	\N	f	f	\N	t	2019-12-25 10:56:42.165857	[]	[]	reportlistid	12	\N	\N	\N	\N	f	[]	f	f
19365	119	12	reportparams	12	reportparams	array	[]	f	f		f		f	reports.reportparams	\N	\N	f	f	\N	t	2019-12-25 10:56:44.415375	[]	[]	reportlistid	12	\N	\N	\N	\N	f	[]	f	f
19363	119	10	completed	10	completed	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
19354	119	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:44.415375	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19373	120	8	completed	8	completed	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:45.989848	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
19370	120	5	ptype	5	Тип параметра	label	[]	f	f		f		f	reports.paramtypes	\N	\N	f	f	id	f	2019-12-25 10:56:45.989848	["typename"]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
19371	120	6	created	6	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:45.989848	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
19367	120	2	reportlistid	2	reportlistid	label	[]	f	f		f		f	reports.reportlist	\N	\N	f	f	id	f	2019-12-25 10:56:45.989848	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
19366	120	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:45.989848	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19372	120	7	apimethod	7	API Method	label	[]	t	f		f		f	framework.spapi	\N	\N	f	f	id	f	2019-12-25 10:56:45.989848	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
19374	120	9	orderby	9	Sort By	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:45.989848	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
19376	121	2	reportlistid	2	reportlistid	label	[]	f	f		f		f	reports.reportlist	\N	\N	f	f	id	f	2019-12-25 10:57:10.533471	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
19375	121	1	id	1	id	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:57:10.533471	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19352	118	11	filename	11	filename	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	11	\N	\N	\N	\N	f	[]	f	f
19351	118	10	completed	10	completed	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	10	\N	\N	\N	\N	f	[]	f	f
19349	118	8	created	8	created	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
19347	118	6	template_path	6	template_path	label	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
19388	118	17	filename	13	File Name	text	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
19346	118	5	template	5	Template File	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	5	\N	\N	\N	\N	f	[]	f	f
19348	118	7	functitle	7	Report Function	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	7	\N	\N	\N	\N	f	[]	f	f
19350	118	9	section	9	Report Section	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
19406	120	10	id	1	param_id	number	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19416	121	10	id	1	paramid	number	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	1	\N	\N	\N	\N	f	[]	f	f
19421	121	15	created	7	created	date	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	6	\N	\N	\N	\N	f	[]	f	f
19392	118	21	created	8	Дата создания	date	[]	f	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	9	\N	\N	\N	\N	f	[]	f	f
19423	121	17	orderby	9	Sort By	number	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	8	\N	\N	\N	\N	f	[]	f	f
19398	119	15	functitle	7	Function	select_api	[]	t	f		f	col-md-12	f	\N	/api/getreports_fn	\N	f	f	\N	f	2019-12-25 11:04:47.818399	[]	[]	\N	3	\N	\N	\N	\N	f	[]	f	f
19427	120	5	typename	\N	Type	label	[]	t	f	\N	f		f	\N	\N	\N	f	f	id	f	2019-12-25 11:24:06.247663	[]	[]	\N	5	\N	\N	ptype	reports.paramtypes	t	[]	f	f
19343	118	2	title	2	Title	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	2	\N	\N	\N	\N	f	[]	f	f
19345	118	4	path	4	Path	label	[]	t	f		f		f	\N	\N	\N	f	f	\N	f	2019-12-25 10:56:42.165857	[]	[]	\N	4	\N	\N	\N	\N	f	[]	f	f
\.


--
-- TOC entry 3321 (class 0 OID 0)
-- Dependencies: 208
-- Name: config_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('config_id_seq', 20251, true);


--
-- TOC entry 3002 (class 0 OID 180194)
-- Dependencies: 209
-- Data for Name: configsettings; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY configsettings (id, sname) FROM stdin;
1	types
2	roles
3	visible
4	default value
5	width
6	visible condition
7	select condition
8	join
9	updatable
10	class name
\.


--
-- TOC entry 3322 (class 0 OID 0)
-- Dependencies: 210
-- Name: configsettings_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('configsettings_id_seq', 10, true);


--
-- TOC entry 3004 (class 0 OID 180199)
-- Dependencies: 211
-- Data for Name: defaultval; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY defaultval (id, configid, bool, act, value, created) FROM stdin;
86	12712	and	=	_userid_	2019-11-05 10:00:17.290746
88	12970	and	=	_orgid_	2019-11-05 10:00:17.290746
89	13031	and	=	0	2019-11-05 10:00:17.290746
90	13040	and	=	0	2019-11-05 10:00:17.290746
\.


--
-- TOC entry 3323 (class 0 OID 0)
-- Dependencies: 212
-- Name: defaultval_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('defaultval_id_seq', 212, true);


--
-- TOC entry 3006 (class 0 OID 180205)
-- Dependencies: 213
-- Data for Name: dialog_messages; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY dialog_messages (id, userid, message_text, reply_to, forwarded_from, dialog_id, files, images, created, isread, isupdated, user_reads) FROM stdin;
\.


--
-- TOC entry 3324 (class 0 OID 0)
-- Dependencies: 214
-- Name: dialog_messages_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('dialog_messages_id_seq', 670, true);


--
-- TOC entry 3008 (class 0 OID 180219)
-- Dependencies: 215
-- Data for Name: dialog_notifications; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY dialog_notifications (id, dialog_id, sender_userid, userid, message_text, created, issend, message_id) FROM stdin;
\.


--
-- TOC entry 3325 (class 0 OID 0)
-- Dependencies: 216
-- Name: dialog_notifications_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('dialog_notifications_id_seq', 2790, true);


--
-- TOC entry 3010 (class 0 OID 180229)
-- Dependencies: 217
-- Data for Name: dialog_statuses; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY dialog_statuses (id, sname) FROM stdin;
1	Active
2	Closed
\.


--
-- TOC entry 3326 (class 0 OID 0)
-- Dependencies: 218
-- Name: dialog_statuses_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('dialog_statuses_id_seq', 2, true);


--
-- TOC entry 3012 (class 0 OID 180234)
-- Dependencies: 219
-- Data for Name: dialog_types; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY dialog_types (id, tname) FROM stdin;
2	group
1	personal
\.


--
-- TOC entry 3013 (class 0 OID 180237)
-- Dependencies: 220
-- Data for Name: dialogs; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY dialogs (id, title, users, dtype, userid, created, status, first_message, last_message_date, photo, dialog_admins, creator) FROM stdin;
\.


--
-- TOC entry 3327 (class 0 OID 0)
-- Dependencies: 221
-- Name: dialogs_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('dialogs_id_seq', 133, true);


--
-- TOC entry 3328 (class 0 OID 0)
-- Dependencies: 222
-- Name: dialogs_status_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('dialogs_status_seq', 1, false);


--
-- TOC entry 3016 (class 0 OID 180255)
-- Dependencies: 223
-- Data for Name: filters; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY filters (id, column_order, viewid, title, type, classname, "column", columns, roles, t, "table", created, val_desc) FROM stdin;
132	1	214	found	typehead	\N	\N	["path","title"]	[0]	\N	{}	2019-11-05 10:00:17.290746	\N
137	1	217	found	typehead	form-control	\N	["methodname","procedure name"]	[]	\N	{}	2019-11-05 10:00:17.290746	\N
152	1	26	found	typehead	\N	\N	["title","url","descr"]	[]	\N	{}	2019-11-05 10:00:17.290746	\N
154	2	234	search	typehead		\N	["title","path"]	[]	\N	{}	2019-11-05 10:00:17.290746	\N
159	1	239	seach	typehead	\N	\N	["column title","title"]	[]	\N	{}	2019-11-05 10:00:17.290746	\N
133	1	216	table name	substr	\N	tablename	[]	[]	1	null	2019-11-05 10:00:17.290746	12823
130	1	44	sended	check	\N	issend	[]	[]	1	null	2019-11-05 10:00:17.290746	12713
131	2	44	readed	check	\N	isread	[]	[]	1	null	2019-11-05 10:00:17.290746	12714
134	2	216	operation type	select	\N	opertype	[]	[]	1	{"t": 4, "col": "opertype", "join": 0, "type": "select", "roles": "[]", "title": "opertype", "width": "", "depency": null, "visible": 0, "relation": "framework.opertypes", "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "value": "typename"}]}	2019-11-05 10:00:17.290746	12827
135	3	216	created	period	\N	created	[]	[]	1	null	2019-11-05 10:00:17.290746	12831
136	4	216	table id	substr	form-control	tableid	[]	[]	1	{"t": 3, "col": "tableid", "join": 0, "type": "text", "roles": "[]", "title": "tableid", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}	2019-11-05 10:00:17.290746	12824
155	1	236	isactive	check	\N	isactive	[]	[]	1	null	2019-11-05 10:00:17.290746	13115
156	2	236	login	substr	form-control	login	[]	[]	1	null	2019-11-05 10:00:17.290746	13112
157	3	236	roles	multijson	\N	roles	[]	[]	1	null	2019-11-05 10:00:17.290746	13113
153	1	234	parent	multiselect	\N	parentid	[]	[0]	1	"framework.mainmenu"	2019-11-05 10:00:17.290746	13091
162	0	237	Title	substr	\N	title	[]	[]	1	{}	2019-11-07 14:34:20.394455	13118
187	1	237	Path	substr	\N	path	[]	[]	1	{}	2019-12-02 09:01:54.162823	13123
188	2	237	Table	substr	\N	tablename	[]	[]	1	{}	2019-12-02 09:06:20.264493	13120
217	1	118	Found	typehead		\N	["Название","Название функции","Путь"]	[]	\N	{}	2019-12-25 11:04:47.818399	\N
\.


--
-- TOC entry 3329 (class 0 OID 0)
-- Dependencies: 224
-- Name: filters_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('filters_id_seq', 234, true);


--
-- TOC entry 3018 (class 0 OID 180269)
-- Dependencies: 225
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
-- TOC entry 3019 (class 0 OID 180272)
-- Dependencies: 226
-- Data for Name: functions; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY functions (id, funcname, functype) FROM stdin;
1	concat	concat
7	count	groupby
8	sum	groupby
9	max	groupby
10	min	groupby
\.


--
-- TOC entry 3020 (class 0 OID 180275)
-- Dependencies: 227
-- Data for Name: logtable; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY logtable (id, tablename, tableid, opertype, oldata, newdata, created, colname, userid) FROM stdin;
\.


--
-- TOC entry 3330 (class 0 OID 0)
-- Dependencies: 228
-- Name: logtable_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('logtable_id_seq', 74694, true);


--
-- TOC entry 3022 (class 0 OID 180285)
-- Dependencies: 229
-- Data for Name: mainmenu; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY mainmenu (id, title, parentid, created, systemfield, orderby, path, roles, icon, menuid) FROM stdin;
63	Menus	57	2019-03-15 09:29:46.75475	f	6	/menus	[0]	pi pi-fw pi-plus	1
64	Messages	57	2019-03-15 09:30:12.903699	f	7	/messages	[0]	pi pi-fw pi-spinner	1
65	Charts	57	2019-03-15 09:30:39.657018	f	8	/charts	[0]	pi pi-fw pi-chart-bar	1
58	Sample Page	57	2019-03-15 09:27:06.583319	f	1	/sample	[0]	pi pi-fw pi-th-large	1
59	Forms	57	2019-03-15 09:27:37.780909	f	2	/forms	[0]	pi pi-fw pi-file	1
66	Misc	57	2019-03-15 09:31:03.89889	f	8	/misc	[0]	pi pi-fw pi-upload	1
60	Data	57	2019-03-15 09:28:05.012457	f	3	/data	[0]	pi pi-fw pi-table	1
67	Documentation	56	2019-03-15 10:11:53.306876	f	2	/documentation	[0]	pi pi-fw pi-question	1
61	Panels	57	2019-03-15 09:28:44.88184	f	4	/panels	[0]	pi pi-fw pi-list	1
68	View Source	56	2019-03-15 10:12:39.958606	f	3	/sigmasource	[0]	pi pi-fw pi-search	1
62	Overlays	57	2019-03-15 09:29:15.673439	f	5	/overlays	[0]	pi pi-fw pi-clone	1
70	English	72	2019-03-21 12:28:58.473125	f	0	/jdocumentation	[0]	\N	1
71	Русский	72	2019-03-21 12:29:37.606743	f	2	/jdocumentation_rus	[0]	\N	1
4	Menu Settings	2	2018-11-30 12:44:57.98	t	1	/list/projectmenus	[0]	menu	1
72	Framework Documentation	\N	2019-03-22 09:22:48.47185	f	200	/	[0]	cn_dictionary	1
2	Project Settings	\N	2018-11-30 12:43:58.967	t	190	/	[0]	setting	1
69	Global Settings	2	2019-03-15 11:41:44.701615	f	0	/projectsettings	[0]	cn_global	1
47	Trees	2	2019-03-14 11:33:25.912516	f	3	/list/trees	[0]	cn_tree-table	1
6	Compositions	2	2018-12-11 08:40:45.927	f	4	/list/compos	[0]	cn_web-grid	1
9	SP API	2	2018-12-21 14:32:59.333	f	7	/list/spapi	[1]	cn_api-1	1
5	Users	2	2018-11-30 15:19:17.057	f	11	/list/users	[0]	cn_users-group	1
82	Views	2	2019-08-08 15:37:47.118891	f	1	/list/views	[0]	cn_viewlist	1
139	Request's logs	2	2019-10-02 15:35:10.476118	f	10	/logfiles	[]		1
8	Logs	2	2018-12-17 16:59:24.177	f	9	/list/logs	[1]	cn_logs	1
145	Test	\N	2019-11-05 11:36:25.050314	f	1000	/list/test	[0]	\N	1
81	Reports	2	2019-07-30 13:30:47.272032	f	185	/list/reports	[0]	cn_paper-report	1
\.


--
-- TOC entry 3331 (class 0 OID 0)
-- Dependencies: 230
-- Name: mainmenu_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('mainmenu_id_seq', 190, true);


--
-- TOC entry 3024 (class 0 OID 180298)
-- Dependencies: 231
-- Data for Name: mainsettings; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY mainsettings (dsn, port, "developerRole", maindomain, "primaryAuthorization", redirect401, isactiv) FROM stdin;
host=127.0.0.1 dbname=framework user=postgres password=Qwerty123 port=5432	8080	0	http://94.230.251.78:8080	1	http://localhost:8080/auth	t
\.


--
-- TOC entry 3025 (class 0 OID 180311)
-- Dependencies: 232
-- Data for Name: menus; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY menus (id, menutype, menutitle, ismainmenu) FROM stdin;
1	1	Main menu	f
\.


--
-- TOC entry 3332 (class 0 OID 0)
-- Dependencies: 233
-- Name: menus_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('menus_id_seq', 21, true);


--
-- TOC entry 3027 (class 0 OID 180317)
-- Dependencies: 234
-- Data for Name: menutypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY menutypes (id, mtypename) FROM stdin;
1	Left Menu
2	Header Menu
3	Footer Menu
\.


--
-- TOC entry 3333 (class 0 OID 0)
-- Dependencies: 235
-- Name: menutypes_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('menutypes_id_seq', 3, true);


--
-- TOC entry 3029 (class 0 OID 180325)
-- Dependencies: 236
-- Data for Name: methodtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY methodtypes (id, methotypename) FROM stdin;
1	get
2	post
3	put
4	delete
\.


--
-- TOC entry 3030 (class 0 OID 180328)
-- Dependencies: 237
-- Data for Name: operations; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY operations (id, value, js, python, sql) FROM stdin;
1	=	===	==	=
2	<>	!==	!=	<>
3	>	>	>	>
4	<	<	<	<
5	>=	>=	>=	>=
6	<=	<=	<=	<=
7	like	indexOf	find	like
8	like in	indexOfSubstr	find in	like in
9	in	in	in	in
10	not in	not in	not in	not in
11	is null	===null	is None	is null
12	is not null	!==null	is not None	is not null
13	likeOr	likeOr	likeOr	likeOr
14	contain	contain	contain	contain
\.


--
-- TOC entry 3334 (class 0 OID 0)
-- Dependencies: 238
-- Name: operations_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('operations_id_seq', 14, true);


--
-- TOC entry 3032 (class 0 OID 180333)
-- Dependencies: 239
-- Data for Name: opertypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY opertypes (id, typename, alias) FROM stdin;
1	add	add
2	update	edit
3	delete	delete
\.


--
-- TOC entry 3033 (class 0 OID 180336)
-- Dependencies: 240
-- Data for Name: orgs; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY orgs (id, orgname, parentid, shortname, created, userid) FROM stdin;
1	OOO test	\N	\N	2019-04-09 17:04:34	1
\.


--
-- TOC entry 3335 (class 0 OID 0)
-- Dependencies: 241
-- Name: orgs_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('orgs_id_seq', 80, true);


--
-- TOC entry 3035 (class 0 OID 180350)
-- Dependencies: 242
-- Data for Name: paramtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY paramtypes (id, val, created) FROM stdin;
1	simple	2019-04-25 10:54:32
2	mdlpsign	2019-04-25 10:54:41
\.


--
-- TOC entry 3036 (class 0 OID 180359)
-- Dependencies: 243
-- Data for Name: roles; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY roles (id, rolename, systema, hierarchy, ros_rl682_id_id) FROM stdin;
0	developer	MIS	0	\N
1	Администратор системы	MIS	\N	\N
2	Администратор МО	MIS	\N	\N
6	ФРМО просмотр	MIS	\N	\N
8	ФРМР просмотр	MIS	\N	\N
7	Отдел кадров полный доступ	MIS	\N	\N
9	Администратор склада	MIS	\N	\N
10	Экономист	MIS	\N	\N
11	Подписанты эл. мед. док.	MIS	\N	\N
12	Врач	MIS	11	1
13	Хирург	MIS	11	2
14	Ассистент	MIS	11	3
15	Анестезиолог	MIS	11	4
16	Заведующий отделением	MIS	11	5
17	Главный врач	MIS	11	6
18	Медсестра	MIS	11	7
19	Акушер	MIS	11	8
20	Санитар	MIS	11	9
21	Фельдшер	MIS	11	10
22	Старший фельдшер	MIS	11	11
23	Диспетчер	MIS	11	12
24	Старший диспетчер	MIS	11	13
25	Председатель	MIS	11	14
26	Заместитель председателя	MIS	11	15
27	Член комиссии	MIS	11	16
28	Секретарь	MIS	11	17
29	Врач-онколог	MIS	\N	\N
\.


--
-- TOC entry 3037 (class 0 OID 180363)
-- Dependencies: 244
-- Data for Name: select_condition; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY select_condition (id, configid, col, operation, const, value, created, val_desc) FROM stdin;
577	13098	menuid	=	\N	{"t": 1, "label": "menuid", "value": "menuid"}	2019-11-05 10:00:17.290746	13106
576	13070	id	<>	\N	{"t": 1, "key": "id_512cb", "label": "id", "value": "bid"}	2019-11-05 10:00:17.290746	13067
575	13070	treesid	=	\N	{"t": 1, "key": "treesid_9766c", "label": "treesid", "value": "treesid"}	2019-11-05 10:00:17.290746	13068
654	13789	viewid	=	\N	\N	2019-12-02 09:04:50.152974	13178
\.


--
-- TOC entry 3336 (class 0 OID 0)
-- Dependencies: 245
-- Name: select_condition_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('select_condition_id_seq', 950, true);


--
-- TOC entry 3039 (class 0 OID 180372)
-- Dependencies: 246
-- Data for Name: sess; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY sess (id, userid, created, killed) FROM stdin;
ac7ce579-72f4-74b4-c44a-63985284830a	1	2019-03-20 16:23:09.351753	\N
a88e45ad-db0d-c0b7-c76d-3b0aad9d3721	1	2019-02-19 10:20:24.710044	\N
c1e76887-483a-e4d7-c376-f8b8e5422564	1	2019-02-20 10:41:01.417766	2019-02-21 14:43:49.750845
89e32af8-383b-e58b-a2fe-907a6f82b82a	1	2019-02-21 14:43:54.138611	2019-02-21 16:57:12.920391
4f94b8ec-6d2e-c1de-d603-e085eb7acd67	1	2019-03-21 08:16:23.792441	\N
9465bae3-5d6f-a171-f14d-94e4d7429908	1	2019-03-20 15:46:27.477038	2019-03-21 15:16:41.755943
71eaa5df-a847-12a8-5718-d2aa1c849f29	1	2019-03-21 15:34:46.984366	\N
01f2ff62-8c8c-d889-d287-b826f69fce25	1	2019-03-28 09:58:36.971485	\N
2d155283-6b76-f1ac-7adb-43262cc90804	1	2019-03-29 16:40:23.523954	\N
ed1c0e77-fa79-a23d-e6c8-43dc25202253	1	2019-03-29 16:44:35.763024	\N
bc964bdc-d3b7-ec04-f6da-796f4218dcdb	1	2019-03-29 17:07:10.229697	\N
8509ff2a-a0a1-9f0d-95a6-9ce11c6e1c2e	1	2019-03-29 20:29:59.725384	\N
14c743b2-94cc-c6c8-f387-48a7d257ee28	1	2019-04-01 16:40:40.480506	\N
352d21dd-b632-0f3b-d152-0a57ccc79e60	1	2019-04-01 17:51:44.657894	\N
4eb9ade0-33f0-d434-c1b5-9afac39f949e	1	2019-04-02 13:03:18.730561	\N
1664d0f2-f6c6-5ea1-e227-c5a14b0559c8	1	2019-04-04 09:49:31.87619	\N
1a8ae0f1-782c-ca28-e512-f947e49656d0	1	2019-04-04 11:13:09.235535	\N
139e4577-bbad-a7f3-096f-8117ff32f2d1	1	2019-04-04 13:53:57.930716	\N
a797f2af-d7ba-18bb-5cde-13ca1c7b0135	1	2019-04-04 18:25:11.034169	\N
05b9d888-d561-3ac3-f467-6b1501fba941	1	2055-02-13 15:31:00	2055-02-14 01:25:00
2919c682-2240-c592-0928-47ddcc81f14e	1	2019-02-25 15:22:44.461396	\N
9a116744-6084-e57e-34d3-e0aa3a95ade2	1	2019-02-25 16:39:11.348662	\N
86878c1f-1bc8-89ce-cc39-bbdcb3cfabbe	1	2019-02-27 16:50:31.047691	\N
572f5552-e4e8-d557-d310-09bce930d596	1	2019-02-21 16:57:21.958373	2019-02-28 09:07:54.770845
57a39c63-1862-1fc4-cb45-44487b84f644	1	2019-02-28 09:08:09.572648	2019-03-05 17:04:43.10977
fab17752-2604-1e5f-3f9c-7677f7b11853	1	2019-03-05 17:07:56.252173	\N
a49707b5-8f02-59e6-e57a-20df7d7332bd	1	2019-03-05 17:06:31.63789	2019-03-06 09:21:56.568194
0f6e3a13-0ff1-0102-254b-88adf9607b9a	1	2019-03-06 09:22:42.131212	\N
4f5e222b-ac74-d146-48dd-b22626d3cdd1	1	2019-03-11 08:40:47.767444	2019-03-12 13:37:25.25797
a52a72b2-c4d9-1bb3-9123-5cdb50e5d336	1	2019-03-12 13:37:36.340487	\N
77e02ffa-dd81-d501-bcf8-a1c0b894693b	1	2019-03-12 13:49:53.81809	\N
30b55d6a-8998-ef42-0f7d-541b6a25c444	1	2019-03-13 18:00:13.75662	\N
23ff62f5-f117-7104-3439-32d9b9161000	1	2019-03-13 18:03:39.087225	\N
80d95981-8ee0-c069-5ecf-c25684879544	1	2019-03-13 18:56:32.674737	\N
aaa0ef67-d934-b5a2-8529-bb001aabe3c9	1	2019-03-13 09:55:59.721848	2019-03-14 18:29:16.74252
90dd1746-3c56-c4c9-a6fc-790501abd802	1	2019-03-14 18:29:39.419905	2019-03-15 09:20:42.272413
08776905-0f48-0879-99b4-84cc1ef54568	1	2019-03-15 09:21:34.487331	2019-03-15 12:51:41.687059
16a6263d-e4db-8e3d-9ef2-dfd950f72a5f	1	2019-03-15 13:11:40.006495	2019-03-15 13:13:04.740804
b7a8b521-a16c-89d3-e85c-e4b2509f5eaf	1	2019-03-15 13:13:44.384177	2019-03-15 13:28:59.977104
a993b8cd-93bd-9799-9a65-243a8ee5ab90	1	2019-03-15 13:29:11.971686	2019-03-18 09:25:09.424228
b41858cf-f281-575a-9c1f-b9fe74415de1	1	2019-03-18 09:27:58.922739	\N
a5f47b64-fb97-ede6-37de-3fd7402b610c	1	2019-03-18 11:42:54.972827	\N
0e8531c3-6af2-5a0d-a08c-c769b02ed428	1	2019-03-19 10:58:01.301183	\N
0cbdc4bf-1659-6011-8966-0076eda6f208	1	2019-03-19 13:38:13.931615	\N
119e9843-0e00-37ef-9640-0f8377ffaab4	1	2019-03-19 15:58:31.429901	\N
d6dd3fe3-685c-4588-eb7b-6b358b308072	1	2019-03-20 08:40:07.364526	2019-03-20 10:41:53.324497
af316923-3a59-5d08-06e4-50abed99451c	1	2019-03-20 10:41:58.297237	2019-03-20 11:03:47.835057
1f789ef6-fb39-bead-18e3-a50b624094ee	1	2019-03-20 11:04:05.644525	2019-03-20 12:00:37.075111
5ab00596-fe90-2a24-78da-112bb8110370	1	2019-03-20 12:01:18.090876	2019-03-20 13:46:34.189695
43ceee2f-c731-c2ae-d25b-be7862729c9b	1	2019-03-20 13:50:29.887763	2019-03-20 15:36:07.674627
52ac0486-1635-458f-8772-b7034b0dd7ce	1	2019-04-08 14:48:10.126184	\N
a9b2952e-8b83-0e92-2a06-0b6cd75868d1	1	2019-04-08 15:19:07.570823	\N
530944ef-ff08-f2ea-9fc9-fc260cdce62e	1	2019-04-08 15:55:56.600571	2019-04-09 16:05:42.857948
7efda56e-15d8-ae5c-c78b-4eeaee6f3e8c	1	2019-04-09 16:06:09.300646	\N
810c1dc0-96f5-30ab-c47b-675ec97a75cd	1	2019-04-11 10:30:12.286667	\N
3d74c0b6-7d70-144a-f767-fcd499f0ddcf	1	2019-04-12 08:45:42.967236	2019-04-13 11:23:24.683493
dd79260b-a597-9e17-f447-69184ac413bb	1	2019-04-13 11:24:46.3883	2019-04-15 14:29:18.035404
4ae250ba-7bf1-9842-b5d2-9b821cb6f039	1	2019-04-15 14:30:02.741266	2019-04-15 14:30:20.475528
c34b0f24-e7c1-0d37-5be7-45ed1d015785	1	2019-04-16 09:44:47.486164	\N
de0f5720-bde0-babd-1a42-c94eda653a65	1	2019-04-16 10:02:42.6893	\N
ad0c6766-fed1-f7ab-8703-0650b425aef1	1	2019-04-16 12:52:51.911258	\N
2758ce41-cee2-03e7-51f4-599958fe835f	1	2019-04-22 13:56:52.384391	\N
3e8d855d-f274-08ca-84d7-9cf6da7da581	1	2019-04-23 14:08:04.358084	\N
6398add8-1fc7-93d9-94cb-b05f9663b1d5	1	2019-04-24 08:28:04.844457	\N
f4036582-e454-9b72-ba2b-3eee034d5579	1	2019-04-24 15:35:04.024372	\N
87649091-e692-48c0-2f48-c37ca9cb1e26	1	2019-04-24 16:33:31.385309	\N
676e3111-f8e1-3e41-36b1-6bf75afbe84c	1	2019-04-25 09:02:38.301903	\N
c4569904-8458-ca1d-45ae-152d898b786f	1	2019-04-26 10:26:04.069601	2019-05-01 08:21:06.636709
0047dc64-fade-8bcf-a7e2-b5449ad621ce	1	2019-05-01 08:21:10.52488	\N
11ea6716-a510-1f3a-fe1f-e9786c10ec4f	1	2019-05-01 08:24:12.370016	\N
4a778c8a-d210-2f7a-04d3-829c129e7497	1	2019-05-01 08:25:04.337165	\N
2244d5b3-e70d-48f0-bfa7-c9b1ac8ff131	1	2019-05-01 08:25:27.365538	\N
5d33a657-4fab-6fed-4400-7606d07c7ee4	1	2019-05-07 14:10:47.12578	\N
90948c08-c993-08eb-01f0-a673930bab7a	1	2019-05-08 09:42:56.030585	\N
17daa982-352b-c685-3a34-b82b97c24e12	1	2019-05-08 09:44:54.011169	\N
89756d28-9f5e-5208-bf2c-e1e151e1dab4	1	2019-05-08 10:19:22.489577	\N
a0f69022-8eb0-9996-0f4c-b8c72520f47e	1	2019-05-08 14:52:01.342908	\N
a92625ca-5fdc-65ad-8876-f50b74886fff	1	2019-05-13 16:31:58.276791	\N
44219642-2117-9d08-2223-e6c79018333f	1	2019-05-14 08:46:01.069567	\N
036977b1-f254-da18-1b42-d4b69c00a8f8	1	2019-05-14 09:03:32.44098	\N
570d3db4-657f-e98c-3edf-b48d75fe3cff	1	2019-05-16 14:07:51.620626	\N
18795350-2c67-7c63-8da1-ab2ee2732ae7	1	2019-05-16 15:05:42.08105	\N
caf8282f-8d6f-39e5-6455-f654c2500866	1	2019-05-17 08:11:25.410582	\N
f5d66b37-4ef2-ece3-2fc0-ddcc3003b5d3	1	2019-05-17 08:11:56.283701	\N
6bb59081-4e40-9e6e-a5e4-969d898e7a1b	1	2019-05-20 10:03:56.967811	\N
aafa6492-fd42-29ff-f4d6-fb4e93e5c699	1	2019-05-20 11:42:29.993856	\N
c574018d-54b9-a01b-c7da-b609444963e4	1	2019-05-20 15:49:46.528654	\N
1e7f45d0-0221-3d23-cbbe-7dcfa8f4d772	1	2019-05-21 13:25:26.16556	\N
e076d6ca-8e2b-1ed8-0e3f-54b9964d9f00	1	2019-05-21 14:52:22.922457	\N
a3b67d15-afd6-80a7-05ed-726a4e8723e6	1	2019-05-21 14:52:44.679731	\N
c22dfeca-6286-a66a-830c-700bc68ea84d	1	2019-05-21 16:11:33.687194	\N
766cf5ac-6e07-cd27-6013-e9db4cc14fff	1	2019-05-23 15:58:16.14622	\N
106b657f-36cc-820e-d619-8695d32ec78b	1	2019-05-28 09:52:30.57933	\N
cb6eb998-64c1-27d9-b86b-79cb06d9a2e1	1	2019-05-28 11:24:54.82618	\N
1793de00-000f-ece7-8d50-da3a9e77f9c5	1	2019-05-28 15:16:16.808111	\N
40b5c84a-1e52-f784-717d-cdadbbdbc1c8	1	2019-05-28 16:05:21.440142	\N
19729849-de03-5afe-26da-b1de38a52328	1	2019-05-28 16:44:52.064702	\N
3eb876b0-2d20-c92c-065d-a535779a0f68	1	2019-05-29 09:20:23.280221	\N
2649cd63-1eeb-2b50-ba7e-992bddfd60ca	1	2019-05-30 18:19:26.41632	\N
76fb39e9-c76d-bb20-b7a1-e27e63d03b67	1	2019-06-03 11:52:21.175975	\N
2bfde66e-4459-bd32-4c57-7a64c49014bb	1	2019-06-03 16:54:47.92333	\N
3e7f2bff-ab6b-6ad8-b096-eac8826bdd0e	1	2019-06-03 20:29:50.181051	\N
5b32274b-7116-d8f1-5522-03c8ccf0f227	1	2019-06-04 17:47:35.45664	\N
ba49fdbb-2721-b489-a407-5cdabf93ac68	1	2019-06-05 09:37:12.745456	\N
01ce6265-9628-0178-0a52-8ed34ce0e695	1	2019-06-06 10:01:03.715414	\N
17e401a2-37bc-77ce-247d-570882c7fe77	1	2019-06-07 10:07:47.599086	\N
72a3b4af-6657-5ee5-be98-5a32fc6316f3	1	2019-06-07 17:39:38.598139	\N
62cc7601-4d01-76ff-f3fc-4747075b8027	1	2019-06-07 17:42:09.317116	\N
e064a0cd-3e1d-04fa-2adb-d37ed6aa27ac	1	2019-06-08 15:41:22.211427	\N
6cc083fc-a66a-b657-2997-5a5d0049c9d8	1	2019-06-08 15:42:11.14296	\N
b541d13d-7ab2-3256-3dd7-27fd1dd656ad	1	2019-06-09 23:48:04.703951	\N
d4ab67cd-bbf3-d4e1-8d67-49db91ff0e2f	1	2019-06-10 10:58:25.184943	\N
415a840a-5b8b-84dc-bdf5-4cf7348b2293	1	2019-06-10 11:06:16.047694	\N
d820e3ac-df51-c1c3-3d0c-9c650157d998	1	2019-06-10 11:11:23.664996	\N
607b8a89-7bc1-37ee-08a5-dccbac06c5cb	1	2019-06-10 11:18:18.806167	\N
edc565dd-3497-9133-5302-1ede10a2fb2a	1	2019-06-10 11:21:43.420542	\N
f41b842d-c309-00d0-8306-c7376a0225ed	1	2019-06-10 11:22:31.012671	\N
15552848-c9ed-4d2a-8743-f12df5940818	1	2019-06-10 11:24:43.976241	\N
f6d92013-585e-b904-eae9-a503eff116b1	1	2019-06-10 11:27:13.968317	\N
26c77448-5dfe-af3c-ed6b-465f1fac98ac	1	2019-06-10 11:29:43.45305	\N
feec2ee3-f76a-89d1-17f2-3f3419b5f762	1	2019-06-10 11:31:02.351301	\N
84706dec-1e48-85c7-1efe-09760bd30cdb	1	2019-06-10 11:31:51.501777	\N
50b45272-e1d8-5c8b-8aa5-456b97ff0248	1	2019-06-10 11:32:31.601576	\N
cfcc27b9-f241-93b4-5f0c-da2e936149ad	1	2019-06-10 11:33:47.465083	\N
253e8b2e-5e8b-5aab-4368-38729c0724da	1	2019-06-10 11:35:55.004415	\N
63da6b31-150f-d942-33ee-1ac3fa77adf3	1	2019-06-10 11:36:46.028974	\N
f74615cd-affe-6126-96d5-8efc2d428eb3	1	2019-06-10 11:37:28.489397	\N
a58c4032-2d77-29bb-ab60-1bf900eb2cee	1	2019-06-10 11:38:24.031075	\N
d3d9772c-b71b-c572-79ea-e2153021ad7e	1	2019-06-10 11:39:29.981563	\N
6531d4a7-f808-a122-5948-8b2e73c985e5	1	2019-06-10 11:45:17.869866	\N
66659c35-5fac-dd95-39b6-033064c5c19e	1	2019-06-10 11:50:57.151264	\N
cb971cbb-b020-c32a-c295-8f2a490548b3	1	2019-06-10 11:52:12.531887	\N
6d8373ec-d001-bc84-3c45-93d3b6b04968	1	2019-06-10 11:52:29.840547	\N
f0b93f55-9dc0-4069-27a4-d56a98cab60a	1	2019-06-10 11:53:30.12064	\N
5d6b9ec1-3290-1fdb-7899-d4f3648c10db	1	2019-06-10 11:55:17.163684	\N
74725a2f-a010-0d49-fa70-90c7794dfa8a	1	2019-06-10 11:58:31.228253	\N
8b742679-2452-a3dc-0fc9-b02c2c037fe0	1	2019-06-10 11:59:39.502863	\N
b48359e5-d9c8-208e-f18a-7e0642258828	1	2019-06-10 12:04:28.050053	\N
69daeaf8-87d5-d7cb-e6a7-fe0f266cee8d	1	2019-06-10 12:05:31.636863	\N
f3d6b69c-d94a-8b35-6ce7-ba10a99720c9	1	2019-06-10 13:26:30.82286	\N
813964d3-81b3-7483-5aa1-5a7160b292d8	1	2019-06-10 16:38:07.11842	\N
8f994f5c-213f-69ba-6eea-90fc96daec44	1	2019-06-10 16:40:43.723081	\N
3c7b5824-adf3-8cb8-fcb9-34f19efc7c60	1	2019-06-10 16:43:57.793726	\N
c5b546dd-e9be-d5e3-4c81-5d7c159d0399	1	2019-06-10 16:45:34.919576	\N
b1471986-33f3-4d26-d9a6-ad5e34075a62	1	2019-06-10 16:51:33.55112	\N
c343ec94-d1df-359e-f0e1-d4729afa35a8	1	2019-06-10 16:52:06.436507	\N
c9e0b5ba-bc3f-2b36-06e0-b53473c7f825	1	2019-06-10 16:56:03.095595	\N
acd147d4-b3c4-3682-cc70-4e58e066cee5	1	2019-06-10 16:58:17.356604	\N
6ec414f4-13ee-ab10-7ffa-627cbfb631ec	1	2019-06-10 17:06:15.117413	\N
8538f25a-1171-5345-93b3-54719155589a	1	2019-06-10 17:08:18.759395	\N
739328ec-e298-423a-dd08-dc0de5ae8b58	1	2019-06-10 17:10:16.957787	\N
b022665b-5ebe-d6d7-8ce8-6f2a0836453f	1	2019-06-10 21:02:56.62087	\N
57dbd62f-cc07-caee-f902-66a497bf6f92	1	2019-06-10 21:06:54.330073	\N
e0790cbd-2619-6333-c299-1d04d2bbab46	1	2019-06-10 21:26:23.98471	\N
0aa0694d-c50b-9b4e-ecfc-643ac1571953	1	2019-06-10 21:29:17.256246	\N
845734f8-b832-93ad-3e40-b38667fde78c	1	2019-06-10 21:29:21.176129	\N
29e9547c-cc2b-e85f-bd21-bd0abf4ad29f	1	2019-06-10 21:29:46.842709	\N
c77ac6e9-8c59-5496-dc25-448b365db5fc	1	2019-06-10 21:30:34.819017	\N
34781791-8f7f-3fce-2099-c12100766095	1	2019-06-10 21:31:32.371016	\N
82c481d8-7114-df02-0655-0614c508ed89	1	2019-06-10 21:36:31.614033	\N
7e36fea8-f148-7ef3-b963-7442fdac0cb2	1	2019-06-10 23:47:20.806463	\N
a06a6c8f-ff2f-f866-0545-7e62a4712b9b	1	2019-06-11 08:36:49.004301	\N
9ed28dcc-635e-ced6-74dd-0e4ce2c1488b	1	2019-06-11 08:37:24.869258	\N
93ef0514-12b3-85d9-202d-a1710d0bb2e4	1	2019-06-11 08:37:46.859049	\N
de7e9889-d8c1-8128-9e4e-14aba10cd2a0	1	2019-06-11 08:37:55.952209	\N
467bd622-35ee-e344-231a-759b8f3b40f9	1	2019-06-11 08:38:10.923588	\N
6b28ef8e-7ef5-fa18-7715-44da25c5dae2	1	2019-06-11 08:38:32.702319	\N
487b6aed-cdf2-7b7c-ec80-e2b7bad563b8	1	2019-06-11 09:40:33.269628	\N
20168b7f-9db0-c284-5abb-490aa43b821c	1	2019-06-11 11:04:56.99637	\N
49444230-97ed-7c3c-60f7-4ff09d6614f4	1	2019-06-11 11:06:24.78469	\N
6c2cb532-c8b0-7ff4-6433-e1aed679102b	1	2019-06-11 15:07:14.840012	\N
42b102ef-40ce-4a42-7062-36ec224da526	1	2019-06-13 09:21:39.969258	\N
c3960dee-20bd-bc1c-be35-ad0e262e5cb0	1	2019-06-13 12:05:41.939503	\N
4735b41c-1c83-3573-2290-6a41628ef2a7	1	2019-06-13 12:10:08.192235	\N
a9500ca4-1dc9-8199-d7eb-20db3adae311	1	2019-06-13 12:56:15.217454	\N
8f3da516-14e7-8613-eb3d-b4b0485a439b	1	2019-06-13 12:56:42.134406	\N
4c67375b-c957-88b4-3141-74d8a6a219ee	1	2019-06-13 14:10:38.464972	\N
a232272d-5683-fcd8-3e71-3b5b5e48c76f	1	2019-06-13 15:12:53.471286	2019-06-13 15:38:28.617388
2c0bbd07-3fc8-b955-8ef8-37467abfa839	1	2019-06-13 15:40:25.927288	2019-06-13 15:40:27.366034
3f1e48db-72dd-ab07-54ae-54ada1c3edce	1	2019-06-13 15:40:49.92944	2019-06-13 15:40:51.560151
ddbb1309-e9fc-bc4a-4b3c-ba59fe836fa5	1	2019-06-13 15:41:15.325358	2019-06-13 15:41:17.133642
5933f0fc-19bc-c935-1cc5-4e6b3f274119	1	2019-06-13 15:41:19.786945	2019-06-13 15:41:21.794734
5b903eef-8124-002f-2309-02176888f184	1	2019-06-13 15:41:23.999098	2019-06-13 15:41:51.989344
6c85971e-4e03-eff0-abf6-9d0c81af9c36	1	2019-06-13 15:42:10.481297	2019-06-13 15:42:15.332446
c86a408d-e3b4-fc5d-2701-ed9f0d843eeb	1	2019-06-13 15:42:25.646875	2019-06-13 15:44:27.561461
3e743763-b52a-6b05-646c-f30fd61e55ec	1	2019-06-13 15:44:31.365184	2019-06-13 15:57:31.663233
ac3eecc9-85f7-7c2d-978c-f5095dcfb0a1	1	2019-06-13 15:57:34.275216	2019-06-13 17:07:28.654572
c40a3857-ee47-cf6a-8e3f-ab90a1175ff5	1	2019-06-13 17:30:42.905603	\N
92c4e32b-6aef-eef1-3357-b89776a1b0db	1	2019-06-13 19:15:18.308477	2019-06-13 19:15:18.498234
c40e44e1-365a-8504-4f92-f6bbb41bf435	1	2019-06-13 19:15:20.97154	2019-06-13 19:15:21.194576
e10335e3-5356-5000-5530-17f28f17aafd	1	2019-06-13 19:16:28.420826	2019-06-13 19:16:28.60245
55afa911-fb3b-a6e5-d805-0e72c44d7043	1	2019-06-13 19:21:48.243413	2019-06-13 19:21:51.393423
9a9eba14-c14d-c7de-a603-389ffd1e4f65	1	2019-06-13 19:21:54.887831	2019-06-14 16:34:09.480471
8d713b08-a4d6-9232-adcb-48cdbf8a247e	1	2019-06-14 16:34:24.151562	2019-06-14 16:34:54.92927
9917cafa-36ca-9318-2ff2-5f77454f4043	1	2019-06-14 16:34:58.474177	2019-06-14 16:35:06.391684
b2dc2784-53c7-fe64-ae2f-e58b8c0eeb93	1	2019-06-14 16:35:08.596414	2019-06-14 16:35:11.235923
7bcb4f09-68a7-722f-94e4-25c394eb0b2c	1	2019-06-14 16:35:19.86862	2019-06-14 16:37:14.320667
ede73cf7-764c-3185-8d3f-27fe8aa9da68	1	2019-06-14 16:37:22.861134	\N
ff192fbe-8a03-08ac-c291-7eabae071577	1	2019-06-14 16:37:25.172128	2019-06-14 16:38:02.387779
62b91b52-e014-a97e-8f0f-822ada178307	1	2019-06-14 16:38:10.895932	2019-06-14 16:38:33.032781
f94d2d5d-7c90-734c-e7c9-1fce2a060b13	1	2019-06-14 16:38:39.75601	2019-06-14 16:39:22.988597
06a8305e-fe92-c480-0251-a4d858acc1cb	1	2019-06-14 16:39:29.501974	2019-06-14 16:40:05.292781
c0f44e2d-c2ee-11c0-38e4-2b0355363322	1	2019-06-14 16:40:17.365034	2019-06-14 16:40:41.004555
17bda86e-2843-5fc6-c198-3229c2e0f5bb	1	2019-06-14 16:40:52.365534	2019-06-14 16:43:28.721737
d329dbaf-9013-9169-8376-82b680d0f9a3	1	2019-06-14 16:43:42.70838	2019-06-14 16:45:30.03017
7118a515-b6c0-94a5-78f8-be41398611d4	1	2019-06-14 16:45:35.711071	\N
1a75b7ad-607f-0b82-83dd-432fdb4e8801	1	2019-06-14 16:45:37.862153	\N
5f989481-41b5-d332-3044-c4ae50cc281a	1	2019-06-14 16:45:41.525534	\N
d5ff2b81-7e4e-be17-52cf-943dc63d5f1a	1	2019-06-14 16:45:51.329968	2019-06-14 16:46:44.443412
179639f9-3175-4001-d4f6-6e77bf78acf8	1	2019-06-14 16:46:47.567902	2019-06-14 16:47:16.928596
65c0acd9-6201-a777-2d03-839be3e9bb94	1	2019-06-14 16:47:21.769353	2019-06-14 16:47:46.381201
e2795eda-8f45-4567-aac3-b952577fe736	1	2019-06-14 16:47:49.508063	2019-06-14 16:50:08.503123
95f3e94a-9bfc-e775-427b-b16966492093	1	2019-06-14 16:50:14.000068	2019-06-14 16:50:16.657981
01ffcb9a-211b-718f-1c99-b132a148f7e0	1	2019-06-14 16:50:31.566429	2019-06-14 16:50:47.325674
055b580e-08ea-c0a0-6e02-1f0a04162485	1	2019-06-14 16:50:57.368217	2019-06-14 16:54:15.587712
f800cbd8-30c7-b70a-c4f5-dde175339397	1	2019-06-14 16:54:18.805888	2019-06-14 16:54:22.834277
340abf18-408e-68ee-d61c-72248176be62	1	2019-06-14 16:56:48.088139	2019-06-14 16:57:36.159879
4c6e0fae-0952-a0ac-78e5-1e2a0355797f	1	2019-06-14 16:57:41.627183	2019-06-14 16:57:44.979727
3bc0d70f-8fa8-cd94-c764-99c2f95bcd24	1	2019-06-14 16:57:55.562648	2019-06-14 16:58:10.144096
aa8b6911-c4a2-99c0-011a-76bd8c53a9e8	1	2019-06-14 16:58:16.634048	2019-06-14 16:58:19.968406
4052ac10-0cef-8572-b1ba-2d103778b099	1	2019-06-14 16:58:44.860816	\N
30e34637-b1d6-4f6e-abd7-8a93e27b442c	1	2019-06-17 00:18:44.466126	\N
01c7e366-8efb-6f10-36a8-e7add60cadc0	1	2019-06-17 08:40:13.911263	\N
73c5b6f6-553a-823b-5bd3-7d0bb01f1d5d	1	2019-06-17 09:32:48.070974	\N
476dac43-e09e-8c8e-4263-79cb5279e281	1	2019-06-17 16:09:51.257597	\N
e6647769-e40e-319d-9b61-5a462d928d3a	1	2019-06-17 16:28:21.16043	\N
a654515a-b687-ca1e-9d63-84c448f06279	1	2019-06-17 12:00:05.081032	2019-06-18 10:25:31.20013
8a0a97f3-dbe3-1590-bb4b-363c7ad6802b	1	2019-06-18 10:42:41.785335	2019-06-18 11:07:25.007968
008c689e-1c8c-0669-25cb-1b08c5639822	1	2019-06-17 16:28:07.275776	2019-06-18 14:16:29.883014
956e263a-6bde-3a43-0cec-9dc58f36106a	1	2019-06-18 14:16:39.116773	\N
0236cd70-08f2-18e2-fa94-e972db7ce7e2	1	2019-06-20 09:02:09.331287	\N
95dcd244-9a7e-cc13-6e6c-baa3baabac4a	1	2019-06-20 14:50:09.741389	\N
1d45bd52-836e-97a7-75bd-665715ab4041	1	2019-06-18 11:07:33.917731	2019-06-21 08:27:18.254661
bb57db79-6884-2e7d-01c6-8c9344e1ef5a	1	2019-06-21 13:43:44.110013	\N
aa76c8ca-b38d-9507-32ee-bbb1100464d6	1	2019-06-21 14:48:58.768956	\N
9d0c948f-e0ad-59cd-253b-4f9c4cd9d942	1	2019-06-21 16:40:30.136424	2019-06-21 16:40:41.386601
045b0d36-b33e-cecf-c2d7-89c409b1963b	1	2019-06-21 16:40:47.497386	2019-06-21 17:40:07.902435
c8bac55d-4abf-cad8-1a43-072c3fdbe6db	1	2019-06-21 17:40:42.834677	\N
48cd5d57-9cd4-18bc-bdaa-1ce7d5720e88	1	2019-06-24 14:07:32.386681	\N
b4382515-be3e-f9ec-c353-1de3fefc36b8	1	2019-06-21 08:28:25.85598	2019-06-25 10:28:12.341828
0091d978-1f2f-ad05-5a36-8c9a34d6fb28	1	2019-06-25 10:28:25.463375	\N
835f8594-946f-a8ea-5de8-8207bb4711b3	1	2019-06-27 08:25:29.630022	\N
e54a06b5-25df-3e72-3a52-681635f67747	1	2019-06-28 08:26:46.531823	2019-06-28 08:26:51.831391
b37b84a8-4de0-6485-4148-4a3dce5f7068	1	2019-06-28 08:26:55.950098	\N
be5d7826-abae-6fff-ba73-ef7ad82edc35	1	2019-07-01 11:00:55.127045	\N
2f456745-24e5-082f-0f03-2f44d6cb845f	1	2019-07-03 14:08:15.496403	\N
220c9bf0-6dff-314f-09a7-234714051b75	1	2019-07-12 21:17:30.652708	\N
63759aa8-28fb-8950-c47d-2052ea7bd866	1	2019-07-15 16:31:02.22718	2019-07-15 17:19:00.784413
cf311e1e-756f-1b5c-8176-ff88f790c790	1	2019-07-15 17:19:22.745942	\N
dc82c440-9afa-398b-d2a7-4dfa482d1f4b	1	2019-07-09 10:54:47.33739	2019-07-18 10:29:05.143352
3ad188ac-0b12-99b6-eb67-ec0b3e493e7c	1	2019-12-31 13:57:02.85953	2019-12-31 15:02:49.922037
f1d57937-e857-25fd-5376-3a6b6185b51e	1	2019-12-31 15:03:00.193147	\N
59d70807-32a8-3d66-e6ec-e4fe160fdb01	1	2019-07-18 10:32:46.689931	\N
d9698f90-1e81-0675-4f95-6eb513b161dd	1	2019-07-10 08:30:45.777291	2019-07-18 10:34:29.461711
45e81077-7264-5475-468d-18172c527072	1	2019-06-04 16:16:18.404779	2019-07-18 10:34:58.3489
89fed6a0-821d-03a6-be5b-7e2a2cbe440b	1	2019-07-18 10:19:02.329957	2019-07-18 10:35:01.987605
6e77f8a6-d54f-6bc9-e2e3-31b2300794e8	1	2019-07-23 12:38:44.867305	\N
72edef7c-0a9e-13fb-4669-bae4a90651bb	1	2019-07-23 16:47:01.193808	2019-07-23 16:47:15.404179
61934abd-2ff9-9928-e537-6041101bc54e	1	2019-07-23 16:47:37.433063	\N
015e1a7b-91f8-70d3-2a21-30bb11e83feb	1	2019-07-24 14:26:31.311795	\N
33c46b5e-da11-66e5-5304-712472ab38e4	1	2019-07-29 12:00:04.734491	\N
31bd33cd-8bfc-e662-e92e-994b8fc3c512	1	2019-08-01 17:32:18.867892	\N
87c8979d-3642-e908-86c4-8ed3c005a853	1	2019-08-01 17:48:22.942864	\N
bcbb8247-9403-348a-d536-1ce0c0127538	1	2019-08-07 00:05:42.006475	\N
89a87b0a-4606-2c83-f7c0-c8f32c927d48	1	2019-08-12 14:22:50.574373	2019-08-21 11:03:42.97414
35c0cd9a-fa5a-eb99-e50a-ac48a9abd18e	1	2019-08-21 11:03:49.935808	\N
33b87e10-db1f-ae69-aed6-d1317727b585	1	2019-08-21 21:05:33.250358	\N
ed2189c8-7bf3-13b3-5c31-870d12d7e89a	1	2019-08-21 14:59:35.102476	2019-08-26 08:36:47.64256
dd5f250d-a324-f7c7-090d-bca75d0786de	1	2019-08-26 08:36:54.755629	2019-08-26 08:37:01.228391
5897f6a3-c896-5635-d863-e0bdbc2c7c77	1	2019-08-26 08:37:08.969602	2019-08-26 08:37:16.50096
3dfface5-9cdc-538f-b9bf-49f5e38ed9ef	1	2019-08-26 08:37:36.752527	2019-08-26 08:38:03.288733
fa8ef1e0-c7d8-7192-33fd-f807a039a0ff	1	2019-08-26 08:20:41.351261	2019-08-26 08:23:44.584135
9ab7e362-124c-df13-e26b-651e596c272f	1	2019-08-26 11:59:57.749158	\N
fb6b8eb4-e2e6-761e-d148-185644edca04	1	2019-08-27 14:53:52.97721	\N
3126bde3-8aba-186c-3edd-d62554d7c5fe	1	2019-08-28 11:53:17.212474	\N
7da7e108-0ab7-84cb-a99b-3146c3fa961e	1	2019-08-26 09:43:16.025746	2019-08-30 08:48:15.079047
c66940c9-12b6-53a9-42d5-74c64ae3a694	1	2019-08-30 08:48:27.420276	2019-08-30 08:56:02.866561
a6c92c4e-8159-e756-d72f-845dc8d3df18	1	2019-08-30 08:56:11.524445	2019-08-30 08:56:15.522059
1237d067-21ee-b65d-1a08-5c9d18b9f2f0	1	2019-08-30 08:56:18.332657	\N
93943ab5-8eab-3ad2-0940-39b5c9c22b74	1	2019-08-30 09:34:57.714767	2019-08-30 10:01:44.792858
596ce442-ec4b-7046-acff-da14a6a7c1db	1	2019-08-30 10:02:05.548267	\N
280bb642-a1c3-f28a-f9c7-8e4f0fd905b8	1	2019-08-30 10:08:27.100551	\N
ca59239a-f5f4-93ed-19bd-fb1d6a6f68d3	1	2019-09-02 09:55:32.662853	\N
0f74c9bf-c0c9-c850-4b06-8df45235f5f8	1	2019-09-02 09:55:32.147374	\N
cb0e5035-0694-c145-f68c-0499997df5dc	1	2019-09-05 09:21:22.842419	2019-09-09 08:13:51.240185
d68fe3fd-3344-81c3-b1dd-24c487470772	1	2019-09-09 08:13:58.135004	\N
11162aae-5b20-1f86-fec8-0733deb482d4	1	2019-09-13 10:37:19.441884	\N
e8a1f40b-57a4-9bf1-88fd-5d097f80b034	1	2019-09-17 09:36:16.570707	\N
c5f5da4a-7b45-64d2-016f-5e3361dace7f	1	2019-09-19 10:53:47.865716	2019-09-19 10:53:58.450309
8e875169-dd53-aa94-5d7c-286dfc3d9f72	1	2019-09-19 10:56:14.041676	2019-09-19 10:58:05.006895
8cda08b4-c22e-d0ec-c58c-d3382429d615	1	2019-09-19 10:59:14.036033	\N
562259a6-defa-d1ab-cc85-fb7e9b4746fe	1	2019-09-20 10:20:20.652134	\N
1cc07bf7-6c37-497a-c48b-525ce134fe97	1	2019-09-20 15:41:00.018946	2019-09-20 16:01:17.31521
b253d56a-1384-b2eb-efb4-15000a75c229	1	2019-09-21 15:15:00.426401	\N
7a934c91-c289-bdff-fdb6-cf140273bb6e	1	2019-09-23 08:06:51.486443	2019-09-23 08:07:35.971967
96d8f8a0-9bb1-f8f5-8d9a-6492e40af89d	1	2019-09-23 09:03:30.590345	\N
4961b0f8-d10a-8b6e-4797-54da11d6d03c	1	2019-09-23 14:01:10.401458	\N
ee828a9e-bc98-fcee-1e0b-18684bbfbe75	1	2019-09-24 01:52:09.672259	\N
3beb0bee-f208-949d-2250-fd4d719c031f	1	2019-09-24 08:37:11.765381	2019-09-24 08:37:36.811657
fbb7bcf9-aedc-ef9f-06d7-3bc24134e243	1	2019-09-26 20:27:26.320866	\N
a98f749f-a47a-df84-910a-041019e21489	1	2019-09-27 07:51:13.212939	\N
40574e3d-daf0-d265-a225-ac2e12384dc7	1	2019-10-03 10:39:35.084554	\N
916040e8-b442-de45-863d-98e507b1e9f0	1	2019-10-11 12:49:34.631222	\N
fa1613c4-6174-4279-ff91-e336764a743f	1	2019-10-15 16:38:53.480865	\N
7ea4ccca-9f1d-ba07-cadf-40fde98082ae	1	2019-10-15 17:03:23.413316	2019-10-18 10:22:17.765402
96ce81e2-f7a4-c72e-b19d-54eb591fac62	1	2019-10-16 09:24:40.133645	2019-10-29 16:50:47.31423
b3b57568-9a13-2b7e-d98e-09df01501fbf	1	2019-10-29 16:58:36.156155	\N
d7e6c439-cdf5-400f-f0ed-885ecff02a00	1	2019-11-05 13:17:19.340257	\N
764892c8-5f3c-6b1e-bc0b-73230b384b0d	1	2019-11-05 18:17:31.644647	\N
4df8a072-1d11-eb1b-d02b-081e326fffca	1	2019-11-05 20:24:44.37626	\N
554af023-b22d-ed32-5799-14f5452423f5	1	2019-11-10 21:47:05.918536	\N
e84d8cc7-8f70-41da-5d4e-1fa2f8a2c6a8	1	2019-11-11 14:12:54.680774	\N
8dd41d1f-cadd-acfe-e011-ae2381eef06b	1	2019-11-11 21:34:03.059398	\N
531db3fc-b9da-1645-1ad3-26b9312900fa	1	2019-11-12 20:53:39.639126	\N
c49f02e4-c4ca-94fd-28b8-17bb3d3c19a3	1	2019-11-19 09:49:46.557531	\N
b4a4377a-0111-30bf-8e32-9991f34b38db	1	2019-11-19 15:50:25.301481	\N
8126e0d2-b4da-c85e-fe87-774469a6bdfa	1	2019-11-20 14:55:06.368072	\N
da95c804-5963-38ad-90ef-e334b0c5a536	1	2019-11-22 09:49:55.710768	\N
bfba610b-c799-a95a-f92a-484195167748	1	2019-11-22 10:16:35.060701	\N
a7fadaa4-e205-96f3-5657-56e744f2e676	1	2019-11-25 08:36:21.989873	\N
86353f32-9203-1d8e-b068-98a52b5a4592	1	2019-11-27 15:59:38.598637	\N
d18d78ef-9ecb-4d86-d5b4-4b51795eaec0	1	2019-11-28 13:49:12.534122	\N
badd0198-a333-6df3-6413-cc1144e14782	1	2019-11-19 15:03:56.876475	2019-12-17 09:09:39.398442
f27d7246-1e9c-7e91-fe44-a8a306cf967a	1	2019-11-29 12:58:08.582321	\N
c9fc728d-538c-d507-b2bd-d9fe2e2a4f3b	1	2019-11-27 08:27:11.493686	2019-12-06 08:48:11.690436
1b70e67a-777e-55a0-f90a-07e7785c7340	1	2019-12-06 08:48:15.846881	\N
b5941697-00ab-c5c0-54e0-90847c96f054	1	2019-12-09 09:14:37.706294	\N
7ea0dd30-e0af-bc72-8cc8-1a392077f486	1	2019-12-10 00:38:29.363283	\N
af7c8c0f-be34-114c-7324-23d5137dd277	1	2019-12-10 11:09:39.271524	\N
89ff9c4f-e3df-97b2-deab-5cd4a88af5d8	1	2019-12-11 09:08:49.34331	2019-12-11 11:16:04.187644
038751e8-d831-94a3-e65d-c6fa8b0598c8	1	2019-12-11 11:16:08.798415	2019-12-11 11:17:32.168894
0152b740-e19d-a813-8645-9888ed37e569	1	2019-12-11 11:17:41.999095	\N
c91568ed-21a9-67be-07bf-4eb73f00ff60	1	2019-12-14 13:49:00.590923	\N
92b5440e-1d9d-94a0-9480-f70d71315f8c	1	2019-12-16 08:15:41.59097	\N
85c65a8d-bbda-b24c-b6cf-0ea0211ff780	1	2019-12-16 09:54:12.316379	2019-12-16 11:32:32.869305
79a99010-5f33-148f-59da-a8c7522411f6	1	2019-12-16 11:32:50.042096	2019-12-16 11:42:11.982559
e27b7287-347e-266c-c218-2ac525ed290e	1	2019-12-16 11:42:51.399044	2019-12-16 11:43:52.587359
f20dc8be-dc9d-37cc-9e6d-0c4a6a456152	1	2019-12-16 11:45:13.105619	2019-12-16 11:45:45.443863
3bf5a2c1-73c6-dc7d-4953-aea7289a8c2c	1	2019-12-16 13:13:02.864724	2019-12-16 13:13:52.692896
2f76ce91-34a6-7adc-ec6b-a1fe2b97b854	1	2019-12-17 09:05:25.57283	2019-12-17 09:14:50.928104
4d2113c4-2b40-5857-ecec-63019f45e800	1	2019-12-17 09:26:40.042829	2019-12-17 09:29:58.907167
b7532f90-191d-d8ca-15bc-9b544ab7f2b4	1	2019-12-17 11:17:45.380517	2019-12-17 14:37:12.145479
c36f3d2a-ad62-69d9-ac31-250d58d122ee	1	2019-12-17 15:21:51.11088	2019-12-17 15:28:44.781785
a192089b-8893-d97b-f21d-beef7045c45b	1	2019-12-17 16:04:50.092357	2019-12-17 18:18:52.505955
51b29509-3533-2fe5-5ad6-dc71393a5ab7	1	2019-12-18 09:28:45.352797	2019-12-18 11:44:39.70622
1ce090ab-9785-415a-c831-6e9adb35e4d1	1	2019-12-18 11:45:21.87963	2019-12-18 12:30:07.654686
2cd5ef93-9c96-2840-b12c-0476bbceb068	1	2019-12-18 12:30:43.947147	2019-12-18 12:31:10.404949
0179790d-b717-0159-5982-acac271b06bc	1	2019-12-18 16:53:04.001719	2019-12-18 17:17:30.90699
8eb7562c-a810-a87e-6cd0-4efdda2cb651	1	2019-12-18 18:55:27.251842	2019-12-18 18:58:57.904069
432872b8-a91d-3068-dd67-f8a09daaad5f	1	2019-12-18 18:59:40.533128	2019-12-18 19:00:41.856236
c05a3576-15c5-5b23-9e70-ae67bd62e3a8	1	2019-12-18 19:38:01.240988	2019-12-19 11:20:41.799683
d4b1a97d-6777-d31d-42b9-399885e54c0c	1	2019-12-19 11:22:39.568802	2019-12-23 11:12:54.866709
d9d62c57-ff61-1555-d8f8-27f143f4a610	1	2019-12-23 11:13:45.093178	2019-12-23 11:14:13.036973
04727724-91e7-bc08-1d54-e6987e8b3da6	1	2019-12-23 11:17:05.485436	\N
e5d37a89-7c7c-c49f-14d8-e92abe0dcba2	1	2019-12-24 15:14:21.292695	2019-12-24 15:14:25.35798
5948ca04-f151-7cfb-f7bd-bd4c70ad5c42	1	2019-12-25 10:36:39.958645	2019-12-25 14:13:12.517779
7a203c89-b6c8-07fe-4246-d1fd28a94acc	1	2019-12-26 13:54:58.808757	\N
18ca923a-12ed-65c6-a0bc-17d50874a215	1	2019-12-30 10:15:56.758316	\N
182e773f-f40f-9d9f-c0e5-3c1870d0ed1f	1	2019-12-30 13:39:05.391304	\N
\.


--
-- TOC entry 3040 (class 0 OID 180376)
-- Dependencies: 247
-- Data for Name: spapi; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY spapi (id, methodname, procedurename, created, methodtype, roles) FROM stdin;
2	mainmenu	framework.fn_mainmenu	2019-02-18 11:27:07	1	\N
8	createconfig	framework.fn_createconfig	2019-02-20 18:43:46	1	[0]
7	getactypes	framework.fn_getacttypes	2019-02-20 11:34:20	1	[0]
6	getfunctions	framework.fn_getfunctions	2019-02-20 11:28:12	1	[0]
5	tablecolums	framework.fn_tabcolumns	2019-02-20 11:13:53	1	[0]
4	view	framework.fn_view_byid	2019-02-20 11:02:43	1	[0]
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
25	userorgs	framework.fn_userorg_upd	2019-03-18 09:10:27	2	\N
26	treesbypath	framework.fn_trees_bypath	2019-03-18 14:05:40	1	\N
27	setsended	framework.fn_notif_setsended	2019-03-19 15:34:21.91661	2	\N
15	refreshconfig	framework.fn_refreshconfig	2019-02-25 18:03:41	2	[0]
29	views	framework.fn_allviews_sel	2019-04-04 08:59:51	1	\N
31	apimethods	framework.fn_apimethods	2019-04-25 09:36:33	1	[0]
32	paramtypes	framework.fn_paramtypes	2019-04-25 10:56:08	1	[0]
34	getusersettings	framework.fn_getusersettings	2019-05-31 10:08:08	1	\N
35	saveusersettings	framework.fn_saveusersettings	2019-05-31 10:08:28	2	\N
37	cryptotoken	framework.fn_crypto_token	2019-06-25 08:43:14	1	\N
39	copyview	framework.fn_copyview	2019-07-12 17:34:25	2	[0]
65	menus	framework.fn_menus	2019-08-11 20:10:23	1	\N
78	savestate	framework.fn_savestate	2019-08-17 22:53:29	2	\N
58	getreports_fn	reports.fn_getreports_fn	2019-07-26 16:33:17	2	[0]
59	report	reports.fn_report_getone	2019-07-29 17:23:49	1	\N
3	formparams	framework.fn_formparams	2019-02-20 10:58:19	1	[0]
1	allviews	framework.fn_allviews	2019-02-04 22:54:58	1	[0]
24	userorgss	framework.fn_userorgs	2019-03-18 08:10:12	2	\N
147	mainmenu	framework.fn_mainmenu	2019-02-18 11:27:07	1	\N
148	createconfig	framework.fn_createconfig	2019-02-20 18:43:46	1	[0]
149	getactypes	framework.fn_getacttypes	2019-02-20 11:34:20	1	[0]
150	getfunctions	framework.fn_getfunctions	2019-02-20 11:28:12	1	[0]
151	tablecolums	framework.fn_tabcolumns	2019-02-20 11:13:53	1	[0]
152	view	framework.fn_view_byid	2019-02-20 11:02:43	1	[0]
153	formparams	framework.fn_formparams	2019-02-20 10:58:19	1	[0]
154	view	framework.fn_viewsave	2019-02-21 13:45:47	2	[0]
155	autocomplete	framework.fn_autocomplete	2019-02-21 16:25:42	2	\N
156	getcolumnconfig	framework.get_colcongif	2019-02-21 16:50:33	1	\N
157	gettable	framework.fn_getselect	2019-02-26 12:26:42	1	\N
159	compo	framework.fn_compo	2019-02-28 11:23:58	1	\N
160	compo	framework.fn_compo_save	2019-02-28 11:55:23	2	\N
161	compobypath	framework.fn_compo_bypath	2019-02-28 11:58:34	1	\N
162	deleterow	framework.fn_deleterow	2019-03-05 16:10:43	4	\N
163	notifs	framework.fn_viewnotif_get	2019-03-07 15:10:09	1	\N
164	mainmenusigma	framework.fn_mainmenusigma	2019-03-15 09:44:59	1	\N
166	userorgs	framework.fn_userorg_upd	2019-03-18 09:10:27	2	\N
167	treesbypath	framework.fn_trees_bypath	2019-03-18 14:05:40	1	\N
168	setsended	framework.fn_notif_setsended	2019-03-19 15:34:21.917	2	\N
169	refreshconfig	framework.fn_refreshconfig	2019-02-25 18:03:41	2	[0]
170	views	framework.fn_allviews_sel	2019-04-04 08:59:51	1	\N
171	apimethods	framework.fn_apimethods	2019-04-25 09:36:33	1	[0]
172	paramtypes	framework.fn_paramtypes	2019-04-25 10:56:08	1	[0]
173	getusersettings	framework.fn_getusersettings	2019-06-07 21:54:43	1	\N
174	allviews	framework.fn_allviews	2019-02-04 22:54:58	1	[0]
175	copyview	framework.fn_copyview	2019-07-12 13:33:10	2	[0]
176	saveusersettings	framework.fn_saveusersettings	2019-06-07 21:55:14	2	[]
177	menus	framework.fn_menus	2019-08-11 20:10:23	1	\N
178	allroles	framework.fn_roles_getall	2019-09-22 13:51:55	1	[0]
181	select_api_test	test.fn_select_api	2019-10-14 09:37:37.772	2	[]
182	select	framework.fn_formselect	2019-02-21 16:02:11	2	\N
184	gettest	test.fn_getmethodtest_setcolorblack	2019-10-16 14:27:52.009	1	[]
185	posttest	test.fn_postmethodtest_setcolorblue	2019-10-17 13:48:35.506	2	[0]
186	rel_tabcolumns	framework.fn_tabcolumns_selforconfig_relselect	2019-10-25 15:27:39.62	2	[0]
187	gettestsetcolor	test.fn_gettest_setallcolor_red	2019-10-17 14:13:25.735	1	[0]
188	postmethodtest_setselectedcolor_black	test.fn_postmethodtest_setselectedcolor_black	2019-10-17 16:04:04.623	2	[0]
189	dep_tabcolumns	framework.fn_tabcolumns_selforconfig_depselect	2019-10-25 15:29:47.116	2	[0]
190	col_add_select_condition	framework.fn_col_add_select_condition	2019-10-27 15:05:50.599	2	[0]
191	tabcolumns_for_sc	framework.fn_tabcolumns_for_sc	2019-10-27 15:33:47.872	2	[0]
192	applysettings	framework.fn_config_settings_apply	2019-10-31 18:32:45.631	2	[0]
193	tabcolumns_for_filters	framework.fn_tabcolumns_for_filters	2019-10-28 16:29:47.205	2	[0]
194	addfncol	framework.fn_config_fncol_add	2019-10-31 11:32:29.369	2	[0]
195	config_selectapi	framework.fn_config_selectapi	2019-10-31 12:03:51.44	2	[0]
196	tabcolumns_for_filters_arr	framework.fn_tabcolumns_for_filters_arr	2019-10-28 17:12:40.833	2	[0]
197	getfunctions	framework.fn_getfunctions	2019-10-31 10:19:17.946	2	[0]
198	addcol	framework.fn_config_inscol	2019-10-31 16:20:21.921	2	[0]
199	view_cols_for_sc	framework.fn_view_cols_for_sc	2019-10-27 16:03:03.948	2	[0]
200	view_cols_for_fn	framework.fn_view_cols_for_fn	2019-10-31 10:27:32.71	2	[0]
201	configsettings_selectapi	framework.fn_configsettings_selectapi	2019-10-31 18:25:09.126	2	[0]
202	saverow	framework.fn_savevalue	2019-02-22 11:12:43	2	[]
203	view_cols_for_param	framework.fn_view_cols_for_param	2019-11-04 15:27:09.014	2	[0]
180	gettables	framework.fn_gettables_sel	2019-10-24 16:20:45.226	2	[0]
9	view	framework.fn_viewsave	2019-02-21 13:45:47	2	[0]
179	savestate	framework.fn_savestate	2019-08-17 22:53:29	2	[]
310	dialog_message_send	framework.fn_dialog_message_send	2019-12-06 15:22:25	2	\N
158	savefile	framework.fn_savevalue	2019-02-26 16:36:49	2	\N
237	functions_getall_spapi	framework.fn_functions_getall_spapi	2019-11-25 08:29:48	2	[0]
214	action_add_untitle	framework.fn_action_add_untitle	2019-11-12 09:59:10.772038	2	[0]
97	report_copy	reports.fn_report_copy	2019-11-25 14:50:07	2	[0]
215	filter_add_untitle	framework.fn_filter_add_untitle	2019-11-12 10:27:28.916111	2	[0]
219	action_copy	framework.fn_action_copy	2019-11-12 21:36:08.606294	2	[0]
307	dialog_personal_create	framework.fn_dialog_personal_create	2019-12-06 11:31:12	2	\N
308	dialogs	framework.fn_dialogs_byuser	2019-12-06 14:14:16	1	\N
309	dialog_messages	framework.fn_dialog_message_bydialog	2019-12-06 15:11:01	1	\N
311	dialog_message_edit	framework.fn_dialog_message_edit	2019-12-07 11:36:22	2	\N
312	dialog_delete_message	framework.fn_dialog_message_delete	2019-12-07 11:41:53	4	\N
313	dialog_group_create	framework.fn_dialog_group_create	2019-12-07 11:50:48	2	\N
320	dialog_edit	framework.fn_dialog_edit	2019-12-08 15:42:26	2	\N
321	chats	framework.fn_dialogs_chats_ws	2019-12-08 16:36:48	1	\N
322	dialog_notif_setsended	framework.fn_dialogs_notif_setsended	2019-12-08 16:47:24	1	\N
323	dialog_message_setreaded	framework.fn_dialog_message_setread	2019-12-08 16:53:21	1	\N
324	dialogs_usersearch	framework.fn_dialogs_usersearch	2019-12-09 08:47:08	1	\N
375	chats_messages	framework.fn_dialogs_chatsmessages_ws	2019-12-16 13:37:44	1	\N
411	dialog_addadmin	framework.fn_dialog_addadmin	2019-12-30 10:55:51	2	\N
403	dialog_adduser	framework.fn_dialog_adduser	2019-12-25 14:29:03	2	\N
404	dialog_removeuser	framework.fn_dialog_removeuser	2019-12-25 14:34:21	4	\N
407	dialog_leave	framework.fn_dialog_leave	2019-12-27 15:56:11	2	\N
412	dialog_removeadmin	framework.fn_dialog_removeadmin	2019-12-30 10:56:55	4	\N
183	multi_tabcolumns	framework.fn_tabcolumns_selforconfig_multiselect	2019-10-25 13:25:16.583	2	[0]
\.


--
-- TOC entry 3337 (class 0 OID 0)
-- Dependencies: 248
-- Name: spapi_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('spapi_id_seq', 416, true);


--
-- TOC entry 3042 (class 0 OID 180392)
-- Dependencies: 249
-- Data for Name: trees; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY trees (id, title, url, descr, roles, created, userid, orgid, acts) FROM stdin;
\.


--
-- TOC entry 3338 (class 0 OID 0)
-- Dependencies: 250
-- Name: trees_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('trees_id_seq', 36, true);


--
-- TOC entry 3044 (class 0 OID 180403)
-- Dependencies: 251
-- Data for Name: treesacts; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY treesacts (id, treesid, title, icon, classname, act, created) FROM stdin;
15	\N	arrow-left	\N	\N	/list/patient	2019-07-12 11:47:59.571625
16	\N	Назад	fa fa-arrow-left	\N	/list/pacients	2019-07-12 11:48:27.344665
18	\N	\N	\N	\N	/composition/composluch	2019-07-12 11:53:06.190792
19	\N	Создать талон	fa fa-btn	\N	/getone/f025u_1	2019-07-12 13:49:52.822909
20	\N	Талон	fa fa-btn	\N	/getone/f025u_1	2019-07-12 13:50:58.409063
26	\N	Назад	fa fa-arrow-left	btn	/list/medperson_select	2019-07-22 11:26:28.936809
28	\N	 	  	 	\N	2019-10-03 13:24:52.89483
30	\N	Назад	arrow-left	\N	\N	2019-12-26 17:31:55.991394
\.


--
-- TOC entry 3339 (class 0 OID 0)
-- Dependencies: 252
-- Name: treesacts_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('treesacts_id_seq', 31, true);


--
-- TOC entry 3046 (class 0 OID 180412)
-- Dependencies: 253
-- Data for Name: treesbranches; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY treesbranches (id, treesid, title, parentid, icon, created, treeviewtype, viewid, compoid, orderby, ismain) FROM stdin;
140	3	mir	\N	\N	2019-03-14 15:25:06.317856	1	\N	\N	\N	f
141	3	moloko	\N	\N	2019-03-14 15:38:12.127512	\N	\N	\N	\N	f
171	3	\N	\N	\N	2019-03-19 13:44:07.338454	2	\N	\N	\N	f
174	3	\N	\N	\N	2019-03-21 10:33:26.423495	\N	\N	\N	\N	f
175	3	\N	\N	\N	2019-03-21 10:36:16.219615	1	\N	\N	\N	f
176	3	\N	\N	\N	2019-03-21 10:46:05.086044	\N	\N	\N	\N	f
177	3	\N	\N	\N	2019-03-21 11:37:39.983538	\N	\N	\N	\N	f
178	3	\N	\N	\N	2019-03-21 11:38:11.892424	\N	\N	\N	\N	f
179	3	\N	\N	\N	2019-03-21 11:39:15.871915	\N	\N	\N	\N	f
180	3	\N	\N	\N	2019-03-21 11:41:25.732192	\N	\N	\N	\N	f
12	1	kitchen	\N	\N	2019-03-14 14:39:35.471585	\N	\N	\N	\N	f
17	1	mimimi	12	\N	2019-03-14 14:43:57.464894	\N	\N	\N	\N	f
154	1	\N	\N	\N	2019-03-15 17:48:11.531313	\N	\N	\N	\N	f
155	1	\N	\N	\N	2019-03-15 17:48:47.095654	\N	\N	\N	\N	f
47	1	\N	\N	\N	2019-03-14 15:21:48.490545	\N	\N	\N	\N	f
48	1	\N	\N	\N	2019-03-14 15:21:48.832048	\N	\N	\N	\N	f
49	1	\N	\N	\N	2019-03-14 15:21:49.16636	\N	\N	\N	\N	f
50	1	\N	\N	\N	2019-03-14 15:21:49.50265	\N	\N	\N	\N	f
51	1	\N	\N	\N	2019-03-14 15:21:49.835158	\N	\N	\N	\N	f
52	1	\N	\N	\N	2019-03-14 15:21:50.172196	\N	\N	\N	\N	f
53	1	\N	\N	\N	2019-03-14 15:21:50.521397	\N	\N	\N	\N	f
54	1	\N	\N	\N	2019-03-14 15:21:50.869985	\N	\N	\N	\N	f
55	1	\N	\N	\N	2019-03-14 15:21:51.21982	\N	\N	\N	\N	f
56	1	\N	\N	\N	2019-03-14 15:21:51.58679	\N	\N	\N	\N	f
57	1	\N	\N	\N	2019-03-14 15:21:51.951516	\N	\N	\N	\N	f
58	1	\N	\N	\N	2019-03-14 15:21:52.292322	\N	\N	\N	\N	f
59	1	\N	\N	\N	2019-03-14 15:21:52.628108	\N	\N	\N	\N	f
60	1	\N	\N	\N	2019-03-14 15:21:52.976024	\N	\N	\N	\N	f
61	1	\N	\N	\N	2019-03-14 15:21:53.299329	\N	\N	\N	\N	f
62	1	\N	\N	\N	2019-03-14 15:21:53.765075	\N	\N	\N	\N	f
63	1	\N	\N	\N	2019-03-14 15:21:54.083714	\N	\N	\N	\N	f
64	1	\N	\N	\N	2019-03-14 15:21:54.415278	\N	\N	\N	\N	f
65	1	\N	\N	\N	2019-03-14 15:21:54.790191	\N	\N	\N	\N	f
66	1	\N	\N	\N	2019-03-14 15:21:55.118519	\N	\N	\N	\N	f
67	1	\N	\N	\N	2019-03-14 15:21:55.44864	\N	\N	\N	\N	f
68	1	\N	\N	\N	2019-03-14 15:21:55.816296	\N	\N	\N	\N	f
69	1	\N	\N	\N	2019-03-14 15:21:56.164292	\N	\N	\N	\N	f
70	1	\N	\N	\N	2019-03-14 15:21:56.487285	\N	\N	\N	\N	f
71	1	\N	\N	\N	2019-03-14 15:21:56.844394	\N	\N	\N	\N	f
72	1	\N	\N	\N	2019-03-14 15:21:57.197473	\N	\N	\N	\N	f
73	1	\N	\N	\N	2019-03-14 15:21:57.524213	\N	\N	\N	\N	f
74	1	\N	\N	\N	2019-03-14 15:21:57.861755	\N	\N	\N	\N	f
75	1	\N	\N	\N	2019-03-14 15:21:58.193864	\N	\N	\N	\N	f
76	1	\N	\N	\N	2019-03-14 15:21:58.532294	\N	\N	\N	\N	f
77	1	\N	\N	\N	2019-03-14 15:21:58.999404	\N	\N	\N	\N	f
78	1	\N	\N	\N	2019-03-14 15:21:59.347133	\N	\N	\N	\N	f
79	1	\N	\N	\N	2019-03-14 15:21:59.681529	\N	\N	\N	\N	f
80	1	\N	\N	\N	2019-03-14 15:22:00.053545	\N	\N	\N	\N	f
101	1	\N	\N	\N	2019-03-14 15:22:07.915207	\N	\N	\N	\N	f
103	1	\N	\N	\N	2019-03-14 15:22:08.736681	\N	\N	\N	\N	f
104	1	\N	\N	\N	2019-03-14 15:22:09.099343	\N	\N	\N	\N	f
106	1	\N	\N	\N	2019-03-14 15:22:09.98661	\N	\N	\N	\N	f
10	1	moloko	9	ssdwas	2019-03-14 14:38:14.667592	\N	\N	\N	\N	f
9	1	mama anarhia	\N	dss	2019-03-14 14:33:48.634305	\N	\N	\N	\N	f
\.


--
-- TOC entry 3340 (class 0 OID 0)
-- Dependencies: 254
-- Name: treesbranches_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('treesbranches_id_seq', 347, true);


--
-- TOC entry 3048 (class 0 OID 180422)
-- Dependencies: 255
-- Data for Name: treeviewtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY treeviewtypes (id, typename) FROM stdin;
1	simple view
2	composition view
\.


--
-- TOC entry 3049 (class 0 OID 180425)
-- Dependencies: 256
-- Data for Name: users; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY users (id, fam, im, ot, login, password, isactive, created, roles, roleid, photo, orgs, usersettings, orgid, userid, thumbprint) FROM stdin;
1	admin	admin	admin	admin	78d8045d684abd2eece923758f3cd781489df3a48e1278982466017f	t	2018-12-28 12:57:07.76	[0]	0	[{"thumbnail": "http://localhost:8080/files/9e51fbad-ef0e-4953-b32f-88ca09cfa9ceter.jpg", "original": "http://localhost:8080/files/9e51fbad-ef0e-4953-b32f-88ca09cfa9ceter.jpg", "src": "http://localhost:8080/files/9e51fbad-ef0e-4953-b32f-88ca09cfa9ceter.jpg", "thumbnailWidth": 100, "thumbnailHeight": 100, "uri": "/files/9e51fbad-ef0e-4953-b32f-88ca09cfa9ceter.jpg", "filename": "ter.jpg", "content_type": "image/jpeg", "size": 52509}]	[1]	{"inn": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "acts": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "cars": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "docs": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "logs": {"filters": {}, "colsSize": {"login": 173, "created": 187, "tableid": 109, "typename": 177, "tablename": 94}, "colsOrder": [], "pagination": {"pagesize": 50}}, "test": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "snils": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "spapi": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "trees": {"filters": {"tit": "ывывф", "found": "ыыв"}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "users": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "views": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "compos": {"filters": {}, "colsSize": {"Имя": 163, "Фамилия": 119, "Отчество": 173, "Дата рождения": 115}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mdr308": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "notifs": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "sluchs": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "configs": {"colsSize": {"fn_13241": 170, "column_order_13141": 87}, "colsOrder": [], "pagination": {}}, "diagdoc": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "filters": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "parents": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "reports": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "branches": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "contacts": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "medmarks": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_staff": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "pacients": {"filters": {}, "colsSize": {"Имя": 163, "Фамилия": 119, "Отчество": 173, "Дата рождения": 115}, "colsOrder": [], "pagination": {"pagesize": 15}}, "workinfo": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_depart": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_select": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "polisesoms": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "elnbyperson": {"filters": {}, "colsSize": {"Имя": 163, "Фамилия": 119, "Отчество": 173, "Дата рождения": 115}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_building": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_card": {"filters": {}, "colsSize": {"Должность": 63, "cтатус записи": 68, "Причина увольнения": 49, "Целевая подготовка": 57, "Основание окончания": 57, "Тип занятия должности": 100}, "colsOrder": [], "pagination": {"pagesize": 15}}, "postuplenie": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "menusettings": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_equipment": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "projectmenus": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "reportparams": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "treat_periods": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "view_allsluch": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "stacionarpriem": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "medperson_error": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_house_ground": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "medperson_select": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_mobile_depart": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "select_condition": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "medperson_address": {"filters": {}, "colsSize": {"Должность": 63, "cтатус записи": 68, "Причина увольнения": 49, "Целевая подготовка": 57, "Основание окончания": 57, "Тип занятия должности": 100}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_nomination": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "action's parametrs": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "f090u_list_patient": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "medperson_document": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_depart_reg_room": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "visibles_conditions": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_education_ext": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "act_visible_condition": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_education_cert": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_education_prof": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "depart_medical_workers": {"filters": {"last_name": "Дажы"}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_prof_organization": {"filters": {}, "colsSize": {"Должность": 63, "cтатус записи": 68, "Причина увольнения": 49, "Целевая подготовка": 57, "Основание окончания": 57, "Тип занятия должности": 100}, "colsOrder": [], "pagination": {"pagesize": 15}}, "medperson_education_common": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "mo_territorial_depart_list": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_education_postgraduate": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_education_accreditation": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}, "person_education_qualification": {"filters": {}, "colsSize": {}, "colsOrder": [], "pagination": {"pagesize": 15}}}	1	1	\N
\.


--
-- TOC entry 3341 (class 0 OID 0)
-- Dependencies: 257
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 40, true);


--
-- TOC entry 3051 (class 0 OID 180441)
-- Dependencies: 258
-- Data for Name: views; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY views (id, title, descr, tablename, viewtype, pagination, config, path, created, groupby, filters, acts, roles, classname, orderby, ispagesize, pagecount, foundcount, subscrible, checker, api, copy) FROM stdin;
32	branches form	branches form	framework.treesbranches	form not mutable	f	[{"t": 1, "col": "id", "key": "id_512cb", "join": false, "type": "label", "roles": "[]", "title": "bid", "width": "", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "treesid", "key": "treesid_9766c", "join": false, "type": "label", "roles": "[]", "title": "treesid", "width": "", "depency": null, "visible": false, "relation": null, "classname": "col-md-12", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "title", "key": "title_2598c", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 3, "onetomany": false, "updatable": true, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "parentid", "key": "parentid_953d6", "join": false, "type": "select", "roles": "[]", "title": "parentid", "width": "", "depency": null, "visible": true, "relation": "framework.treesbranches", "classname": "col-md-12", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "select_condition": [{"col": {"label": "treesid", "value": "treesid"}, "value": {"t": 1, "key": "treesid_9766c", "label": "treesid", "value": "treesid"}, "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}, {"col": {"label": "id", "value": "id"}, "value": {"t": 1, "key": "id_512cb", "label": "id", "value": "bid"}, "operation": {"js": "!==", "label": "!=", "value": "<>", "python": "!="}}], "visible_condition": [{"col": {"t": 1, "key": "id_512cb", "label": "id", "value": "bid"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "icon", "key": "icon_aa86a", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "created", "key": "created_f5070", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 15, "col": "treeviewtype", "key": "treeviewtype_5b5be", "join": false, "type": "select", "roles": "[]", "title": "treeviewtype", "width": "", "depency": null, "visible": true, "relation": "framework.treeviewtypes", "classname": "col-md-12", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "typename", "title": "typename", "value": "typename"}], "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 23, "col": "viewid", "key": "viewid_ffae0", "join": false, "type": "select", "roles": "[]", "title": "viewid", "width": "", "depency": null, "visible": true, "relation": "framework.views", "classname": "col-md-12", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}, {"label": "path", "title": "path", "value": "path"}], "visible_condition": [{"col": {"t": 1, "key": "treeviewtype_5b5be", "label": "treeviewtype", "value": "treeviewtype"}, "const": null, "value": "1", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}, {"col": {"t": 1, "key": "id_512cb", "label": "id", "value": "bid"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 14, "col": "compoid", "key": "compoid_50bd6", "join": false, "type": "select", "roles": "[]", "title": "compoid", "width": "", "depency": false, "visible": true, "relation": "framework.compos", "classname": "col-md-12", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "visible_condition": [{"col": {"t": 1, "key": "id_512cb", "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "treeviewtype_5b5be", "label": "treeviewtype", "value": "treeviewtype"}, "const": null, "value": "2", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 10, "col": "orderby", "key": "orderby_0bae7", "join": false, "type": "number", "roles": "[]", "title": "orderby", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 11, "col": "ismain", "key": "ismain_9701e", "join": false, "type": "checkbox", "roles": "[]", "title": "ismain", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	branchesform	2019-03-14 13:46:57.627	[]	[]	[{"act": "/", "type": "Save", "title": "save", "parametrs": [], "isforevery": false}, {"act": "/composition/branches", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "bid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "treesid", "paramtitle": "treesid", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
34	My organization	user org	framework.orgs	form full	f	[{"t": 1, "col": "id", "key": "id_71c9c", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "orgname", "key": "orgname_d3ca6", "join": false, "type": "label", "roles": "[]", "title": "orgname", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	myorg	2019-03-18 09:42:45.156	[]	[]	[]	[0]	\N	f	t	t	t	f	f	{}	f
218	Add Test	Test add form	test.major_table	form full	f	[{"t": 1, "col": "id", "key": "id_8ddb9", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "updatable": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "text", "key": "text_1b65e", "join": false, "type": "text", "roles": "[]", "title": "text title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "updatable": true, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 15, "col": "number", "key": "number_991fb", "join": false, "type": "number", "chckd": false, "roles": "[]", "title": "number title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "data", "key": "data_a366d", "join": false, "type": "date", "roles": "[]", "title": "date title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 29, "col": "datetime", "key": "datetime_2a4ce", "join": false, "type": "datetime", "roles": "[]", "title": "datetime", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 29, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "time", "key": "time_9e903", "join": false, "type": "time", "roles": "[]", "title": "time title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "check", "key": "check_21497", "join": false, "type": "checkbox", "roles": "[]", "title": "check title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "key": "password_ba7eb", "join": false, "type": "password", "roles": "[]", "title": "password title visible check", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "text_1b65e", "label": "text", "value": "text title"}, "const": null, "value": "1", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}]}, {"t": 10, "col": "typehead", "key": "typehead_32a4a", "join": false, "type": "typehead", "label": "typehead || typehead", "roles": "[]", "title": "typehead title", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "test.dictionary_for_select", "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "dname", "title": "dname", "value": "dname"}], "select_condition": [{"col": {"label": "dname", "value": "dname"}, "const": "T", "value": null, "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}, {"col": {"label": "id", "value": "id"}, "const": "3", "value": null, "operation": {"js": "", "label": "not in", "value": "not in", "python": "in"}}]}, {"t": 22, "col": "select", "key": "select_9c133", "join": false, "type": "select", "chckd": false, "roles": "[]", "title": "select title", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "test.dictionary_for_select", "required": false, "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "dname", "title": "dname", "value": "dname"}]}, {"t": 8, "col": "multiselect", "key": "multiselect_71f34", "join": false, "type": "multiselect", "roles": "[]", "title": "multiselect title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "dname", "title": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 28, "col": "multitypehead", "key": "multitypehead_2f343", "join": false, "type": "multitypehead", "roles": "[]", "title": "multitypehead title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 27, "col": "select_api", "key": "select_api_a0d95", "join": false, "type": "select_api", "roles": "[]", "title": "select_api title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 27, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 26, "col": "typehead_api", "key": "typehead_api_1a8a1", "join": false, "type": "typehead_api", "roles": "[]", "title": "typehead_api title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 26, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 20, "col": "multi_select_api", "key": "multi_select_api_990f5", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multi_select_api", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 19, "col": "multitypehead_api", "key": "multitypehead_api_dc5d0", "join": false, "type": "multitypehead_api", "roles": "[]", "title": "multitypehead_api", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 23, "col": "autocomplete", "key": "autocomplete_963d3", "join": false, "type": "autocomplete", "roles": "[]", "title": "autocomplete title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 23, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 16, "col": "link", "key": "link_a992a", "join": false, "type": "link", "chckd": false, "roles": "[]", "title": "link title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "label", "key": "label_c82e8", "join": false, "type": "label", "roles": "[]", "title": "label title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 17, "col": "texteditor", "key": "texteditor_185bd", "join": false, "type": "texteditor", "roles": "[]", "title": "texteditor title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 31, "col": "html", "key": "html_9f66a", "join": false, "type": "innerHtml", "label": "html || html", "roles": "[]", "title": "html title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 30, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 24, "col": "textarea", "key": "textarea_0425d", "join": false, "type": "textarea", "roles": "[]", "title": "textarea title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 24, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 21, "col": "colorpicker", "key": "colorpicker_daa19", "join": false, "type": "colorpicker", "roles": "[]", "title": "colorpicker title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 21, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "color", "key": "color_1fd98", "join": false, "type": "color", "roles": "[]", "title": "color title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 18, "col": "colorrow", "key": "colorrow_27de8", "join": false, "type": "color", "chckd": false, "roles": "[]", "title": "colorrow title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "file", "key": "file_ee82c", "join": false, "type": "file", "roles": "[]", "title": "file title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 25, "col": "files", "key": "files_c1997", "join": false, "type": "files", "roles": "[]", "title": "files title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 30, "col": "files", "key": "files_d18ec", "join": false, "type": "filelist", "label": "files || files", "roles": "[]", "title": "filelist title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "image", "key": "image_b7bd1", "join": false, "type": "image", "roles": "[]", "title": "image title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "images", "key": "images_fda10", "join": false, "type": "images", "roles": "[]", "title": "images title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "gallery", "key": "gallery_39fb0", "join": false, "type": "gallery", "roles": "[]", "title": "gallery title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	test_add	2019-10-17 09:33:25	[]	[]	[{"act": "/list/test", "type": "Link", "title": "go back", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "o", "paramcolumn": {"t": 1, "key": "id_8ddb9", "label": "id", "value": "id"}}], "isforevery": false}, {"act": "/", "type": "Link", "title": "visible check", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "text_1b65e", "label": "text", "value": "text title"}, "const": null, "value": "1", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}]}, {"act": "/api/gettest", "type": "API", "title": "set color red (GET TEST)", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_8ddb9", "label": "id", "value": "id"}}], "actapitype": "GET", "isforevery": false, "actapiconfirm": true, "actapirefresh": true, "act_visible_condition": [{"col": {"t": 1, "key": "id_8ddb9", "label": "id", "value": "id"}, "value": "0", "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
56	log	log	framework.logtable	form full	f	[{"t": 1, "col": "id", "key": "id_7f4b6", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "id", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 10, "col": "userid", "key": "userid_c3ff5", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "userid", "width": "", "depency": false, "visible": false, "relation": "framework.users", "classname": "col-md-12", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "login", "title": "login", "value": "login"}]},{"t": 2, "col": "tablename", "key": "tablename_35983", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "tablename", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "tableid", "key": "tableid_0c4b4", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "tableid", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "opertype", "key": "opertype_19d0d", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "opertype", "width": "", "depency": false, "visible": false, "relation": "framework.opertypes", "classname": "col-md-12", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "title": "typename", "value": "typename"}]},{"t": 10, "col": "login", "key": "login_60bb9", "type": "label", "chckd": true, "input": 0, "roles": [], "table": "framework.users", "title": "login", "tpath": [], "width": "", "output": 0, "related": true, "visible": 1, "relation": null, "classname": "col-md-12", "notaddable": false, "relatecolumn": "userid", "relationcolums": "[]"},{"t": 6, "col": "oldata", "key": "oldata_6bcc6", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "oldata", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 7, "col": "newdata", "key": "newdata_402ca", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "newdata", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 8, "col": "created", "key": "created_9ad7e", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	log	2019-03-19 16:34:03.671	[]	[]	[{"act": "/list/logs", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "back", "ismain": false, "classname": "", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	f	t	t	t	f	f	{}	f
215	Edit Test	Test edit form	test.major_table	form not mutable	f	[{"t": 1, "col": "id", "key": "id_8ddb9", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "text", "key": "text_1b65e", "join": false, "type": "text", "roles": "[]", "title": "text title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 15, "col": "number", "key": "number_991fb", "join": false, "type": "number", "chckd": false, "roles": "[]", "title": "number title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "data", "key": "data_a366d", "join": false, "type": "date", "roles": "[]", "title": "date title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 29, "col": "datetime", "key": "datetime_2a4ce", "join": false, "type": "datetime", "roles": "[]", "title": "datetime", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 29, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "time", "key": "time_9e903", "join": false, "type": "time", "roles": "[]", "title": "time title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "check", "key": "check_21497", "join": false, "type": "checkbox", "roles": "[]", "title": "check title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "key": "password_ba7eb", "join": false, "type": "password", "roles": "[]", "title": "password title visible check", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "text_1b65e", "label": "text", "value": "text title"}, "const": null, "value": "1", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}]}, {"t": 10, "col": "typehead", "key": "typehead_32a4a", "join": false, "type": "typehead", "label": "typehead || typehead", "roles": "[]", "title": "typehead title", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "test.dictionary_for_select", "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "dname", "title": "dname", "value": "dname"}], "select_condition": [{"col": {"label": "dname", "value": "dname"}, "const": "T", "value": null, "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}, {"col": {"label": "id", "value": "id"}, "const": "3", "value": null, "operation": {"js": "", "label": "not in", "value": "not in", "python": "in"}}]}, {"t": 22, "col": "select", "key": "select_9c133", "join": false, "type": "select", "chckd": false, "roles": "[]", "title": "select title", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "test.dictionary_for_select", "required": false, "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "dname", "title": "dname", "value": "dname"}]}, {"t": 8, "col": "multiselect", "key": "multiselect_71f34", "join": false, "type": "multiselect", "roles": "[]", "title": "multiselect title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "dname", "title": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 28, "col": "multitypehead", "key": "multitypehead_2f343", "join": false, "type": "multitypehead", "roles": "[]", "title": "multitypehead title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 27, "col": "select_api", "key": "select_api_a0d95", "join": false, "type": "select_api", "roles": "[]", "title": "select_api title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 27, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 26, "col": "typehead_api", "key": "typehead_api_1a8a1", "join": false, "type": "typehead_api", "roles": "[]", "title": "typehead_api title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 26, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 20, "col": "multi_select_api", "key": "multi_select_api_990f5", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multi_select_api", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 19, "col": "multitypehead_api", "key": "multitypehead_api_dc5d0", "join": false, "type": "multitypehead_api", "roles": "[]", "title": "multitypehead_api", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/select_api_test", "relationcolums": "[]"}, {"t": 23, "col": "autocomplete", "key": "autocomplete_963d3", "join": false, "type": "autocomplete", "roles": "[]", "title": "autocomplete title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 23, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 16, "col": "link", "key": "link_a992a", "join": false, "type": "link", "chckd": false, "roles": "[]", "title": "link title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "label", "key": "label_c82e8", "join": false, "type": "label", "roles": "[]", "title": "label title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 17, "col": "texteditor", "key": "texteditor_185bd", "join": false, "type": "texteditor", "roles": "[]", "title": "texteditor title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 31, "col": "html", "key": "html_9f66a", "join": false, "type": "innerHtml", "label": "html || html", "roles": "[]", "title": "html title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 30, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 24, "col": "textarea", "key": "textarea_0425d", "join": false, "type": "textarea", "roles": "[]", "title": "textarea title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 24, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 21, "col": "colorpicker", "key": "colorpicker_daa19", "join": false, "type": "colorpicker", "roles": "[]", "title": "colorpicker title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 21, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "color", "key": "color_1fd98", "join": false, "type": "color", "roles": "[]", "title": "color title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 18, "col": "colorrow", "key": "colorrow_27de8", "join": false, "type": "color", "chckd": false, "roles": "[]", "title": "colorrow title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "file", "key": "file_ee82c", "join": false, "type": "file", "roles": "[]", "title": "file title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 25, "col": "files", "key": "files_c1997", "join": false, "type": "files", "roles": "[]", "title": "files title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 30, "col": "files", "key": "files_d18ec", "join": false, "type": "filelist", "label": "files || files", "roles": "[]", "title": "filelist title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "image", "key": "image_b7bd1", "join": false, "type": "image", "roles": "[]", "title": "image title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "images", "key": "images_fda10", "join": false, "type": "images", "roles": "[]", "title": "images title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "gallery", "key": "gallery_39fb0", "join": false, "type": "gallery", "roles": "[]", "title": "gallery title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 32, "col": "link", "key": "link_31a7a", "join": false, "type": "link", "label": "link || link", "roles": "[]", "title": "link", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 33, "col": "relate_with_major", "key": "relate_with_major_767d7", "join": false, "type": "array", "label": "relate_with_major || relate_with_major", "roles": "[]", "title": "relate_with_major", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "test.relate_with_major", "required": false, "classname": "", "column_id": 31, "onetomany": true, "defaultval": null, "depencycol": "major_table_id", "relationcolums": [{"label": "id", "value": "id"}, {"label": "somecolumn", "value": "somecolumn"}, {"label": "major_table_id", "value": "major_table_id"}, {"label": "created", "value": "created"}]}]	test_edit	2019-10-13 18:23:51	[]	[]	[{"act": "/", "icon": "pi pi-check", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false}, {"act": "/list/test", "type": "Link", "title": "go back", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "o", "paramcolumn": {"t": 1, "key": "id_8ddb9", "label": "id", "value": "id"}}], "isforevery": false}, {"act": "/", "type": "Link", "title": "visible check", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "text_1b65e", "label": "text", "value": "text title"}, "const": null, "value": "1", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}]}, {"act": "/api/gettest", "type": "API", "title": "set color red (GET TEST)", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_8ddb9", "label": "id", "value": "id"}}], "actapitype": "GET", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/posttest", "type": "API", "title": "set color blue (POST TEST)", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_8ddb9", "label": "id", "value": "id"}}], "actapitype": "POST", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	f	t	t	t	f	f	{}	f
214	Views compositions	Views compositions	framework.compos	table	t	[{"t": 1, "col": "id", "key": "id_4403a", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "title", "key": "title_8020b", "join": 0, "type": "text", "roles": "[]", "title": "title", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "path", "key": "path_67f8c", "join": 0, "type": "text", "roles": "[]", "title": "path", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "config", "key": "config_8368c", "join": 0, "type": "text", "roles": "[]", "title": "config", "width": "", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "created", "key": "created_d5ec8", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	compos	2018-12-11 08:37:44.077	[]	[{"type": "typehead", "roles": [{"label": "developer", "value": 0}], "title": "found", "column": [{"t": 1, "label": "path", "value": "path"}, {"t": 1, "label": "title", "value": "title"}], "classname": null}]	[{"act": "/compo/l?id=0", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": null, "parametrs": [], "isforevery": 0}, {"act": "/compo/l", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": null, "parametrs": [{"paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_4403a", "label": "id", "value": "id"}}], "isforevery": 1}, {"act": "/composition", "icon": "fa fa-link", "type": "Link", "roles": [], "title": ", to compo", "ismain": false, "classname": null, "parametrs": [{"paramtype": "link", "paramconst": null, "paramtitle": "path", "paramcolumn": {"t": 1, "key": "path_67f8c", "label": "path", "value": "path"}}], "paramtype": "link", "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete", "ismain": false, "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_4403a", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": 1}]	[0]	\N	t	t	t	t	f	f	{}	f
220	Test	Test	test.major_table	table	t	[{"t": 1, "col": "id", "key": "id_3a31e", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": [{"act": {"label": ">", "value": ">"}, "bool": {"label": "and", "value": "and"}, "value": "0"}], "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "text", "key": "text_84820", "join": false, "type": "text", "roles": "[]", "title": "text title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "data", "key": "data_9ef12", "join": false, "type": "date", "roles": "[]", "title": "data", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "check", "key": "check_c0adb", "join": false, "type": "checkbox", "roles": "[]", "title": "check", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "time", "key": "time_8c9c9", "join": false, "type": "time", "roles": "[]", "title": "time", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "key": "password_3cd1a", "join": false, "type": "password", "roles": "[]", "title": "password", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "color", "key": "color_70c0b", "join": false, "type": "color", "roles": "[]", "title": "color", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "multiselect", "key": "multiselect_3da94", "join": false, "type": "multiselect", "roles": "[]", "title": "multiselect", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 9, "col": "file", "key": "file_5d459", "join": false, "type": "file", "roles": "[]", "title": "file", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "typehead", "key": "typehead_e6558", "join": false, "type": "typehead", "roles": "[]", "title": "typehead", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "image", "key": "image_a483e", "join": false, "type": "image", "roles": "[]", "title": "image", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "images", "key": "images_4e4d0", "join": false, "type": "images", "roles": "[]", "title": "images", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "gallery", "key": "gallery_1cbc1", "join": false, "type": "gallery", "roles": "[]", "title": "gallery", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "label", "key": "label_b8274", "join": false, "type": "label", "roles": "[]", "title": "label", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 15, "col": "number", "key": "number_5a12a", "join": false, "type": "number", "roles": "[]", "title": "number", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 16, "col": "link", "key": "link_e7018", "join": false, "type": "link", "roles": "[]", "title": "link", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 17, "col": "texteditor", "key": "texteditor_377da", "join": false, "type": "texteditor", "roles": "[]", "title": "texteditor", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 18, "col": "colorrow", "key": "colorrow_b394b", "join": false, "type": "colorrow", "roles": "[]", "title": "color row", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 19, "col": "multitypehead_api", "key": "multitypehead_api_c7189", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multitypehead_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 20, "col": "multi_select_api", "key": "multi_select_api_2c6b3", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multi_select_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 21, "col": "colorpicker", "key": "colorpicker_d4763", "join": false, "type": "colorpicker", "roles": "[]", "title": "colorpicker", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 21, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 23, "col": "autocomplete", "key": "autocomplete_9bde0", "join": false, "type": "autocomplete", "roles": "[]", "title": "autocomplete", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 23, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 24, "col": "textarea", "key": "textarea_b7429", "join": false, "type": "textarea", "roles": "[]", "title": "textarea", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 24, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 25, "col": "files", "key": "files_68ff8", "join": false, "type": "files", "roles": "[]", "title": "files", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 26, "col": "typehead_api", "key": "typehead_api_6730b", "join": false, "type": "typehead_api", "roles": "[]", "title": "typehead_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 26, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 27, "col": "select_api", "key": "select_api_762ba", "join": false, "type": "select_api", "roles": "[]", "title": "select_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 27, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 28, "col": "multitypehead", "key": "multitypehead_0a55e", "join": false, "type": "multitypehead", "roles": "[]", "title": "multitypehead", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 29, "col": "datetime", "key": "datetime_388e5", "join": false, "type": "datetime", "roles": "[]", "title": "datetime", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 29, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 31, "col": "relate_with_major", "key": "relate_with_major_f4f4c", "join": false, "type": "array", "label": "relate_with_major || relate_with_major", "roles": "[]", "title": "relate_with_major", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "test.relate_with_major", "required": false, "classname": "", "column_id": 31, "onetomany": true, "defaultval": null, "depencycol": "major_table_id", "relationcolums": [{"label": "id", "value": "id"}, {"label": "somecolumn", "value": "somecolumn"}, {"label": "major_table_id", "value": "major_table_id"}, {"label": "created", "value": "created"}]}, {"t": 22, "col": "select", "key": "select_b1405", "join": false, "type": "label", "label": "select || select", "roles": "[]", "title": "select", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "test.dictionary_for_select", "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "dname", "title": "dname", "value": "dname"}, {"label": "id", "title": "id_", "value": "id"}]}, {"t": 22, "col": "dname", "key": "dname_c5340", "type": "text", "input": 0, "roles": [], "table": "test.dictionary_for_select", "title": "dname", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": 1, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "select", "relationcolums": "[]"}, {"t": 22, "col": "id", "key": "id_0.16492845318532945", "type": "label", "input": 0, "roles": [], "table": "test.dictionary_for_select", "title": "id_", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": true, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "select", "relationcolums": "[]"}, {"t": null, "fn": {"label": "concat", "value": "concat", "functype": "concat"}, "col": "func test", "type": "text", "input": 0, "roles": [], "table": null, "title": "func test", "tpath": null, "output": 0, "related": true, "visible": true, "relation": null, "fncolumns": [{"t": 1, "key": "text_84820", "label": "text", "value": "text title"}, {"t": 1, "key": "number_5a12a", "label": "number", "value": "number"}], "relatecolumn": "", "relationcolums": "[]"}]	test	2019-09-18 13:31:50	[]	[{"t": 1, "type": "substr", "roles": [], "table": {"t": 2, "col": "text", "join": false, "type": "text", "roles": "[]", "title": "text", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "SUBSTR TEXT", "column": "text", "classname": ""}, {"type": "typehead", "roles": [], "title": "TYPEHEAD TEXT NUMBER COLOR", "column": [{"t": 1, "label": "text", "value": "text"}, {"t": 1, "label": "number", "value": "number"}, {"t": 1, "label": "color", "value": "color"}], "classname": ""}, {"t": 1, "type": "check", "roles": [], "table": {"t": 4, "col": "check", "join": false, "type": "checkbox", "roles": "[]", "title": "check", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "check", "column": "check", "classname": ""}, {"t": 1, "type": "period", "roles": [], "table": {"t": 3, "col": "data", "join": false, "type": "date", "roles": "[]", "title": "data", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "PERIOD", "column": "data", "classname": ""}, {"t": 1, "type": "select", "roles": [], "table": {"t": 22, "col": "select", "join": false, "type": "label", "label": "select || select", "roles": "[]", "title": "select", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "test.dictionary_for_select", "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "dname", "title": "dname", "value": "dname"}]}, "title": "select filter", "column": "select", "classname": ""}, {"t": 1, "type": "multiselect", "roles": [], "table": {"t": 8, "col": "multiselect", "join": false, "type": "multiselect", "roles": "[]", "title": "multiselect", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, "title": "multi", "column": "multiselect", "classname": ""}, {"t": 1, "type": "multijson", "roles": [], "table": {"t": 28, "col": "multitypehead", "join": false, "type": "multitypehead", "roles": "[]", "title": "multitypehead", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, "title": "multi json", "column": "multitypehead", "classname": ""}]	[{"act": "/trees/treetest", "type": "Link", "title": "show tree", "parametrs": [], "isforevery": false}, {"act": "/api/postmethodtest_setselectedcolor_black", "type": "API", "title": "set checke black (POST TEST CHECKED)", "parametrs": [{"paramt": null, "paramconst": "_checked_", "paraminput": "", "paramtitle": "checked", "paramcolumn": null}], "actapitype": "POST", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}, {"act": "/getone/test_add", "icon": "pi pi-plus", "type": "Link", "title": "add with relations", "parametrs": [{"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "number,check", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "55", "paraminput": "", "paramtitle": "number", "paramcolumn": null}, {"paramt": null, "paramconst": "true", "paraminput": "", "paramtitle": "check", "paramcolumn": null}], "isforevery": false}, {"act": "/getone/test_edit", "icon": "fa fa-edit", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": "", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_3a31e", "label": "id", "value": "id"}}], "paramtype": "query", "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/gettest", "icon": "pi pi-star-o", "type": "API", "title": "set red", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_3a31e", "label": "id", "value": "id"}}], "actapitype": "GET", "isforevery": true, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/posttest", "icon": "pi pi-star", "type": "API", "title": "set blue", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_3a31e", "label": "id", "value": "id"}}], "actapitype": "POST", "isforevery": true, "actapiconfirm": true, "actapirefresh": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}, {"act": "/getone/test_add", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": "", "parametrs": [{"paramt": null, "paramconst": "0", "paramtitle": "id", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	t	t	t	t	f	t	{}	f
5463	Calendar test	Calendar test	framework.calendar_test	calendar	f	[]	calendar_test	2019-11-14 11:28:40.509753	[]	[]	[]	[0]	\N	f	t	t	t	f	f	{}	f
226	default value	default value	framework.defaultval	form not mutable	f	[{"t": 1, "col": "id", "key": "id_24be4", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "CN", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24be4", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "configid", "key": "configid_0c694", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "configid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24be4", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "bool", "key": "bool_c1bb5", "join": false, "type": "select", "chckd": true, "roles": "[]", "title": "bool operator", "width": "", "relcol": "bname", "depency": false, "visible": true, "relation": "framework.booloper", "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "bname", "title": "bname", "value": "bname"}], "visible_condition": [{"col": {"t": 1, "key": "id_24be4", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 4, "col": "act", "key": "act_1ae13", "join": false, "type": "select", "chckd": true, "roles": "[]", "title": "action", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "value", "title": "value_", "value": "value"}], "visible_condition": [{"col": {"t": 1, "key": "id_24be4", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "value", "key": "value_25aea", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24be4", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "created", "key": "created_946c2", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24be4", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	default_value	2019-10-27 21:28:41.788	[]	[]	[{"act": "/", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false}, {"act": "/composition/defaultval", "icon": "fa fa-cross", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "relation", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
228	action	view's action	framework.actions	form not mutable	f	[{"t": 1, "col": "id", "key": "id_24289", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "act_id", "width": "", "relcol": null, "depency": false, "orderby": true, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "column_order", "key": "column_order_12d84", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "order by", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "title", "key": "title_2f66f", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "act title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 16, "col": "act_type", "key": "act_type_5c4e4", "join": false, "type": "select", "label": "act_type || act_type", "roles": "[]", "title": "act_type", "width": "", "relcol": "actname", "depency": false, "visible": true, "relation": "framework.acttypes", "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "actname", "title": "actname", "value": "actname"}], "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 4, "col": "viewid", "key": "viewid_377d6", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": true, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "icon", "key": "icon_04596", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "act icon", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "classname", "key": "classname_1a0ce", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "class name", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "act_url", "key": "act_url_29725", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "act url", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "act_type_5c4e4", "label": "act_type", "value": "act_type"}, "const": null, "value": "Save,Delete", "operation": {"js": "", "label": "not in", "value": "not in", "python": "in"}}]}, {"t": 8, "col": "api_method", "key": "api_method_5aea3", "join": false, "type": "select", "chckd": true, "roles": "[]", "title": "api method", "width": "", "relcol": "aname", "depency": false, "visible": true, "relation": "framework.apicallingmethods", "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "aname", "title": "aname", "value": "aname"}], "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "act_type_5c4e4", "label": "act_type", "value": "act_type"}, "const": null, "value": "API", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 9, "col": "api_type", "key": "api_type_494c8", "join": false, "type": "select", "chckd": true, "roles": "[]", "title": "api type", "width": "", "relcol": "val", "depency": false, "visible": true, "relation": "framework.apimethods", "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "val", "title": "val", "value": "val"}], "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "act_type_5c4e4", "label": "act_type", "value": "act_type"}, "const": null, "value": "API", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 10, "col": "refresh_data", "key": "refresh_data_605f9", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "refresh data", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "act_type_5c4e4", "label": "act_type", "value": "act_type"}, "const": null, "value": "API", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 11, "col": "ask_confirm", "key": "ask_confirm_a1e8d", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "ask confirm", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "act_type_5c4e4", "label": "act_type", "value": "act_type"}, "const": null, "value": "API", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 12, "col": "roles", "key": "roles_01ded", "join": false, "type": "multiselect", "chckd": true, "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 13, "col": "forevery", "key": "forevery_ddd3c", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "for every row", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 14, "col": "main_action", "key": "main_action_2a926", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "main_action", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 15, "col": "created", "key": "created_b5a98", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	act	2019-10-29 15:47:40.911	[]	[]	[{"act": "/", "icon": "fa fa-check", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/view", "icon": "fa fa-cross", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "act_id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/act_params", "icon": "pi pi-primary", "type": "LinkTo", "title": "parametrs", "classname": "p-button-warning", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "actionid", "paramcolumn": null}, {"paramt": null, "paramconst": "actionid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "paramid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "act_id", "paramcolumn": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "const": null, "value": null, "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}, {"act": "/composition/act_visible_conditions", "icon": "pi pi-question", "type": "LinkTo", "title": "visible condition", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "actionid", "paramcolumn": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}}, {"paramt": null, "paramconst": "actionid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "act_id", "paramcolumn": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "vs_id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "id_24289", "label": "id", "value": "act_id"}, "const": null, "value": null, "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
230	add function column	add function column in config	framework.config	form not mutable	f	[{"t": 6, "col": "title", "key": "title_c9365", "join": false, "type": "text", "label": "title || title", "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 27, "col": "fn", "key": "fn_89c39", "join": false, "type": "select_api", "label": "fn || function is SELECT", "roles": "[]", "title": "function", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 27, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/getfunctions", "relationcolums": "[]"}, {"t": 28, "col": "fncolumns", "key": "fncolumns_f5959", "join": false, "type": "multiselect_api", "label": "fncolumns || Function input parametrs", "roles": "[]", "title": "columns", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/view_cols_for_fn", "relationcolums": "[]", "multiselecttable": "framework.config"}, {"t": 1, "col": "id", "key": "id_55faa", "join": false, "type": "label", "label": "id || id", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": [{"act": {"label": "=", "value": "="}, "bool": {"label": "and", "value": "and"}, "value": "0"}], "depencycol": null, "relationcolums": "[]"}]	fncol	2019-10-31 08:50:24.041	[]	[]	[{"act": "/api/addfncol", "icon": "pi pi-plus", "type": "API", "title": "add", "classname": "p-button-success", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "title", "paramcolumn": {"t": 1, "key": "title_c9365", "label": "title", "value": "title"}}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "fn", "paramcolumn": {"t": 1, "key": "fn_89c39", "label": "fn", "value": "function"}}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "fncols", "paramcolumn": {"t": 1, "key": "fncolumns_f5959", "label": "fncolumns", "value": "columns"}}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "viewid", "paramcolumn": null}], "actapitype": "POST", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}, {"act": "/composition/view", "icon": "fa fa-refresh", "type": "Link", "title": "refresh", "classname": "p-button-primary", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "a", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
231	visible condition (act)	visible condition (act)	framework.act_visible_condions	table	f	[{"t": 1, "col": "id", "key": "id_65b40", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "val_desc", "key": "val_desc_6e0f4", "join": false, "type": "label", "roles": "[]", "title": "val_desc", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "framework.config", "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "title", "title": "title_", "value": "title"}]}, {"t": 2, "col": "actionid", "key": "actionid_c3a88", "join": false, "type": "label", "label": "actionid || actionid", "roles": "[]", "title": "act_id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.actions", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "title", "key": "title_0.009939721068436658", "join": false, "type": "label", "input": 0, "roles": [], "table": "framework.config", "title": "column title", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": true, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "val_desc", "relationcolums": "[]"}, {"t": 6, "col": "operation", "key": "operation_36434", "join": false, "type": "label", "roles": "[]", "title": "operation", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "value", "key": "value_d4bd2", "join": false, "type": "label", "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "created", "key": "created_e0db0", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	act_visible_condition	2019-10-29 17:47:17.834	[]	[]	[]	[0]	\N	f	t	t	t	f	f	{}	f
219	Test tiles	Test	test.major_table	tiles	t	[{"t": 1, "col": "id", "key": "id_3a31e", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "orderby": true, "visible": false, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "orderbydesc": true, "relationcolums": "[]"}, {"t": 2, "col": "text", "key": "text_84820", "join": false, "type": "text", "roles": "[]", "title": "text title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "data", "key": "data_9ef12", "join": false, "type": "date", "roles": "[]", "title": "data", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "check", "key": "check_c0adb", "join": false, "type": "checkbox", "roles": "[]", "title": "check", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "time", "key": "time_8c9c9", "join": false, "type": "time", "roles": "[]", "title": "time", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "key": "password_3cd1a", "join": false, "type": "password", "roles": "[]", "title": "password", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "color", "key": "color_70c0b", "join": false, "type": "color", "roles": "[]", "title": "color", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "multiselect", "key": "multiselect_3da94", "join": false, "type": "multiselect", "roles": "[]", "title": "multiselect", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 9, "col": "file", "key": "file_5d459", "join": false, "type": "file", "roles": "[]", "title": "file", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "typehead", "key": "typehead_e6558", "join": false, "type": "typehead", "roles": "[]", "title": "typehead", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "image", "key": "image_a483e", "join": false, "type": "image", "roles": "[]", "title": "image", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "images", "key": "images_4e4d0", "join": false, "type": "images", "roles": "[]", "title": "images", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "gallery", "key": "gallery_1cbc1", "join": false, "type": "gallery", "roles": "[]", "title": "gallery", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "label", "key": "label_b8274", "join": false, "type": "label", "roles": "[]", "title": "label", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 15, "col": "number", "key": "number_5a12a", "join": false, "type": "number", "roles": "[]", "title": "number", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 16, "col": "link", "key": "link_e7018", "join": false, "type": "link", "roles": "[]", "title": "link", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 17, "col": "texteditor", "key": "texteditor_377da", "join": false, "type": "texteditor", "roles": "[]", "title": "texteditor", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 18, "col": "colorrow", "key": "colorrow_b394b", "join": false, "type": "colorrow", "roles": "[]", "title": "color row", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 19, "col": "multitypehead_api", "key": "multitypehead_api_c7189", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multitypehead_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 20, "col": "multi_select_api", "key": "multi_select_api_2c6b3", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multi_select_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 21, "col": "colorpicker", "key": "colorpicker_d4763", "join": false, "type": "colorpicker", "roles": "[]", "title": "colorpicker", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 21, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 23, "col": "autocomplete", "key": "autocomplete_9bde0", "join": false, "type": "autocomplete", "roles": "[]", "title": "autocomplete", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 23, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 24, "col": "textarea", "key": "textarea_b7429", "join": false, "type": "textarea", "roles": "[]", "title": "textarea", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 24, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 25, "col": "files", "key": "files_68ff8", "join": false, "type": "files", "roles": "[]", "title": "files", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 26, "col": "typehead_api", "key": "typehead_api_6730b", "join": false, "type": "typehead_api", "roles": "[]", "title": "typehead_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 26, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 27, "col": "select_api", "key": "select_api_762ba", "join": false, "type": "select_api", "roles": "[]", "title": "select_api", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 27, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 28, "col": "multitypehead", "key": "multitypehead_0a55e", "join": false, "type": "multitypehead", "roles": "[]", "title": "multitypehead", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, {"t": 29, "col": "datetime", "key": "datetime_388e5", "join": false, "type": "datetime", "roles": "[]", "title": "datetime", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 29, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 31, "col": "relate_with_major", "key": "relate_with_major_f4f4c", "join": false, "type": "array", "label": "relate_with_major || relate_with_major", "roles": "[]", "title": "relate_with_major", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "test.relate_with_major", "required": false, "classname": "", "column_id": 31, "onetomany": true, "defaultval": null, "depencycol": "major_table_id", "relationcolums": [{"label": "id", "value": "id"}, {"label": "somecolumn", "value": "somecolumn"}, {"label": "major_table_id", "value": "major_table_id"}, {"label": "created", "value": "created"}]}, {"t": 22, "col": "select", "key": "select_b1405", "join": false, "type": "label", "label": "select || select", "roles": "[]", "title": "select", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "test.dictionary_for_select", "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "dname", "title": "dname", "value": "dname"}, {"label": "id", "title": "id_", "value": "id"}]}, {"t": 22, "col": "dname", "key": "dname_c5340", "type": "text", "input": 0, "roles": [], "table": "test.dictionary_for_select", "title": "dname", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": 1, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "select", "relationcolums": "[]"}, {"t": 22, "col": "id", "key": "id_0.16492845318532945", "type": "label", "input": 0, "roles": [], "table": "test.dictionary_for_select", "title": "id_", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": true, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "select", "relationcolums": "[]"}]	testtiles	2019-10-22 08:09:09	[]	[{"t": 1, "type": "substr", "roles": [], "table": {"t": 2, "col": "text", "join": false, "type": "text", "roles": "[]", "title": "text", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "SUBSTR TEXT", "column": "text", "classname": ""}, {"type": "typehead", "roles": [], "title": "TYPEHEAD TEXT NUMBER COLOR", "column": [{"t": 1, "label": "text", "value": "text"}, {"t": 1, "label": "number", "value": "number"}, {"t": 1, "label": "color", "value": "color"}], "classname": ""}, {"t": 1, "type": "check", "roles": [], "table": {"t": 4, "col": "check", "join": false, "type": "checkbox", "roles": "[]", "title": "check", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "check", "column": "check", "classname": ""}, {"t": 1, "type": "period", "roles": [], "table": {"t": 3, "col": "data", "join": false, "type": "date", "roles": "[]", "title": "data", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "PERIOD", "column": "data", "classname": ""}, {"t": 1, "type": "select", "roles": [], "table": {"t": 22, "col": "select", "join": false, "type": "label", "label": "select || select", "roles": "[]", "title": "select", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "test.dictionary_for_select", "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "dname", "title": "dname", "value": "dname"}]}, "title": "select filter", "column": "select", "classname": ""}, {"t": 1, "type": "multiselect", "roles": [], "table": {"t": 8, "col": "multiselect", "join": false, "type": "multiselect", "roles": "[]", "title": "multiselect", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, "title": "multi", "column": "multiselect", "classname": ""}, {"t": 1, "type": "multijson", "roles": [], "table": {"t": 28, "col": "multitypehead", "join": false, "type": "multitypehead", "roles": "[]", "title": "multitypehead", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "dname", "value": "dname"}], "relationcolums": "[]", "multiselecttable": "test.dictionary_for_select"}, "title": "multi json", "column": "multitypehead", "classname": ""}]	[{"act": "/trees/treetest", "type": "Link", "title": "show tree", "parametrs": [], "isforevery": false}, {"act": "/api/postmethodtest_setselectedcolor_black", "type": "API", "title": "set checke black (POST TEST CHECKED)", "parametrs": [{"paramt": null, "paramconst": "_checked_", "paraminput": "", "paramtitle": "checked", "paramcolumn": null}], "actapitype": "POST", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}, {"act": "/getone/test_add", "icon": "pi pi-plus", "type": "Link", "title": "add with relations", "parametrs": [{"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "number,check", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "55", "paraminput": "", "paramtitle": "number", "paramcolumn": null}, {"paramt": null, "paramconst": "true", "paraminput": "", "paramtitle": "check", "paramcolumn": null}], "isforevery": false}, {"act": "/getone/test_edit", "icon": "fa fa-edit", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": "", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_3a31e", "label": "id", "value": "id"}}], "paramtype": "query", "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/gettest", "icon": "pi pi-star-o", "type": "API", "title": "set red", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_3a31e", "label": "id", "value": "id"}}], "actapitype": "GET", "isforevery": true, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/posttest", "icon": "pi pi-star", "type": "API", "title": "set blue", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_3a31e", "label": "id", "value": "id"}}], "actapitype": "POST", "isforevery": true, "actapiconfirm": true, "actapirefresh": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}, {"act": "/getone/test_add", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": "", "parametrs": [{"paramt": null, "paramconst": "0", "paramtitle": "id", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	t	t	t	t	f	t	{}	f
5542	User account	User account	framework.users	form full	f	[]	user_account	2019-12-09 18:09:00	[]	[]	[]	[]	\N	f	t	t	t	f	f	{}	f
232	add column	add column in config	framework.config	form not mutable	f	[{"t": 4, "col": "col", "key": "col_0e29d", "join": false, "type": "select_api", "label": "col || column title", "roles": "[]", "title": "column title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/config_selectapi", "relationcolums": "[]"}, {"t": 1, "col": "id", "key": "id_f9b44", "join": false, "type": "label", "label": "id || id", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": [{"act": {"label": "=", "value": "="}, "bool": {"label": "and", "value": "and"}, "value": "0"}], "depencycol": null, "relationcolums": "[]"}]	colinconf	2019-10-31 11:48:07.894	[]	[]	[{"act": "/api/addcol", "icon": "pi pi-plus", "type": "API", "title": "add", "classname": "p-button-success", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "col", "paramcolumn": {"t": 1, "key": "col_0e29d", "label": "col", "value": "column title"}}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "viewid", "paramcolumn": null}], "actapitype": "POST", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}, {"act": "/composition/view", "icon": "fa fa-refresh", "type": "Link", "title": "refresh", "classname": "p-button-primary", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "i", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
234	MainMenu	Menu list	framework.mainmenu	table	f	[{"t": 1, "col": "id", "key": "id_735c4", "join": 0, "type": "number", "input": 1, "roles": [], "title": "id", "width": "", "output": 1, "depency": null, "visible": 0, "relation": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 2, "col": "title", "key": "title_89c08", "join": 0, "type": "text", "input": 0, "roles": [], "title": "title", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 8, "col": "path", "key": "path_7a002", "join": 0, "type": "text", "input": 0, "roles": [], "title": "path", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 4, "col": "roles", "key": "roles_a4e0d", "join": 0, "type": "text", "input": 0, "roles": [], "title": "roles", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 6, "col": "systemfield", "key": "systemfield_0fd10", "join": 0, "type": "checkbox", "input": 0, "roles": [], "title": "systemfield", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 9, "col": "icon", "key": "icon_96cd7", "join": false, "type": "text", "roles": [], "title": "icon", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 3, "col": "parentid", "key": "parentid_a25dc", "join": 0, "type": "select", "input": 0, "roles": [], "title": "parentid", "width": "", "output": 0, "depency": null, "visible": false, "relation": "framework.mainmenu", "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "title", "title": "title_", "value": "title"}]},{"t": 3, "col": "title", "key": "title_d0cd9", "type": "text", "input": 0, "roles": [], "table": "framework.mainmenu", "title": "parent", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "parentid", "relationcolums": []},{"t": 7, "col": "orderby", "key": "orderby_8b3ef", "join": 0, "type": "number", "input": 0, "roles": [], "title": "orderby", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 5, "col": "created", "key": "created_01666", "join": 0, "type": "date", "input": 0, "roles": [], "title": "created", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 10, "col": "menuid", "key": "menuid_ac20c", "join": false, "type": "number", "label": "menuid || menuid", "roles": "[]", "title": "menuid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.menus", "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	menusettings	2018-11-30 12:50:20	[]	[{"t": 1, "key": "4iwOLNx3K", "type": "multiselect", "roles": [{"label": "developer", "value": 0}], "table": "framework.mainmenu", "title": "parent", "column": "parentid", "classname": null}, {"type": "typehead", "roles": [], "title": "search", "column": [{"t": 1, "label": "title", "value": "title"}, {"t": 1, "label": "path", "value": "path"}], "classname": ""}]	[{"act": "/getone/menuedit", "icon": "fa fa-edit", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": null, "parametrs": [{"paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_735c4", "label": "id", "value": "id"}}, {"paramtitle": "o", "paramcolumn": {"t": 1, "key": "title_89c08", "label": "title", "value": "title"}}], "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete menu", "ismain": false, "classname": "btn", "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_735c4", "label": "id", "value": "id"}}], "isforevery": 1}, {"act": "/getone/menuedit", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add menu", "ismain": false, "classname": null, "parametrs": [{"paramt": null, "paramconst": "0", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "menuid", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paramtitle": "menuid", "paramcolumn": {"t": 1, "key": "menuid_ac20c", "label": "menuid", "value": "menuid"}}], "isforevery": 0}, {"act": "/list/projectmenus", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "back", "ismain": false, "classname": "", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	f	t	t	t	f	f	{}	f
242	filter	filter edit/add	framework.filters	form not mutable	f	[{"t": 1, "col": "id", "key": "id_06102", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "fl_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 12, "col": "column_order", "key": "column_order_ca9cc", "join": false, "type": "number", "label": "column_order || column_order", "roles": "[]", "title": "column_order", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "viewid", "key": "viewid_04c9d", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "title", "key": "title_769d5", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 4, "col": "type", "key": "type_6ac01", "join": false, "type": "select", "chckd": false, "roles": "[]", "title": "type", "width": "", "relcol": "ftname", "depency": false, "visible": true, "relation": "framework.filtertypes", "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "ftname", "title": "ftname", "value": "ftname"}], "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "classname", "key": "classname_fa186", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "classname", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "column", "key": "column_a844c", "join": false, "type": "select_api", "chckd": false, "roles": "[]", "title": "column", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/tabcolumns_for_filters", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "type_6ac01", "label": "type", "value": "type"}, "const": null, "value": "typehead", "operation": {"js": "!==", "label": "!=", "value": "<>", "python": "!="}}]}, {"t": 7, "col": "columns", "key": "columns_3048c", "join": false, "type": "multiselect_api", "chckd": false, "roles": "[]", "title": "columns", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/tabcolumns_for_filters_arr", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "type_6ac01", "label": "type", "value": "type"}, "const": null, "value": "typehead", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"t": 8, "col": "roles", "key": "roles_628d8", "join": false, "type": "multiselect", "chckd": false, "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 9, "col": "t", "key": "t_ed9da", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "t", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 10, "col": "table", "key": "table_49b09", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "table", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 11, "col": "created", "key": "created_9dfd6", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	filter	2019-10-28 15:41:00.635	[]	[]	[{"act": "/", "icon": "pi pi-check", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/view", "icon": "fa fa-cross", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "act_id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_06102", "label": "id", "value": "fl_id"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
244	act visible condition	act visible condition	framework.act_visible_condions	form not mutable	f	[{"t": 1, "col": "id", "key": "id_99ad9", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "vs_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "actionid", "key": "actionid_79ee8", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "actionid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.actions", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "val_desc", "key": "val_desc_241f6", "join": false, "type": "select", "chckd": true, "roles": "[]", "title": "val_desc", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "framework.config", "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "operation", "key": "operation_b171e", "join": false, "type": "select", "chckd": true, "roles": "[]", "title": "operation", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "value", "title": "value_", "value": "value"}], "visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "value", "key": "value_2cf11", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 8, "col": "created", "key": "created_dcab2", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	act_visible	2019-10-29 18:07:07.283	[]	[]	[{"act": "/", "icon": "fa fa-check", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/act_visible_conditions", "icon": "fa fa-cros", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "actionid", "paramtitle": "actionid", "paramcolumn": null}, {"paramt": null, "paramconst": "actionid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "vs_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_99ad9", "label": "id", "value": "vs_id"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
237	VIews	Views administration	framework.views	table	t	[{"t": 1, "col": "id", "key": "id_fc1f2", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "orderbydesc": false, "relationcolums": "[]"}, {"t": 2, "col": "title", "key": "title_76a90", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "orderby": false, "visible": false, "relation": null, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "orderbydesc": false, "relationcolums": "[]"}, {"t": null, "fn": {"label": "framework.fn_view_title_link", "value": "framework.fn_view_title_link", "functype": "user"}, "col": "tit", "key": "tit_9f5cb", "type": "link", "input": 0, "roles": [], "table": null, "title": "view title", "tpath": null, "output": 0, "related": true, "visible": 1, "relation": null, "fncolumns": [{"t": 1, "label": "id", "value": "id"}, {"t": 1, "label": "title", "value": "title"}], "relatecolumn": "", "relationcolums": "[]"}, {"t": 4, "col": "tablename", "key": "tablename_3bb96", "join": false, "type": "label", "roles": "[]", "title": "tablename", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "vtypename", "key": "vtypename_d11aa", "type": "text", "input": 0, "roles": [], "table": "framework.viewtypes", "title": "view type", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": 1, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "viewtype", "relationcolums": "[]"}, {"t": 3, "col": "descr", "key": "descr_fbb10", "join": false, "type": "label", "roles": "[]", "title": "descr", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "path", "key": "path_7ce49", "join": false, "type": "link", "roles": "[]", "title": "path", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "viewtype", "key": "viewtype_96c4f", "join": false, "type": "label", "label": "viewtype || viewtype", "roles": "[]", "title": "viewtype", "width": "", "relcol": "vtypename", "depency": false, "visible": false, "relation": "framework.viewtypes", "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "vtypename", "title": "vtypename", "value": "vtypename"}]}]	views	2019-09-22 11:39:01.726	[]	[{"type": "typehead", "roles": [{"label": "developer", "value": 0}], "title": "found", "column": [{"t": 1, "label": "title", "value": "title"}, {"t": 1, "label": "tablename", "value": "tablename"}, {"t": 1, "label": "path", "value": "path"}], "classname": ""}]	[{"act": "/composition/view", "icon": "fa fa-check", "type": "LinkTo", "title": "view edit", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_fc1f2", "label": "id", "value": "id"}}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "act_id", "paramcolumn": null}], "isforevery": true}, {"act": "/view", "icon": "fa fa-link", "type": "LinkTo", "roles": [{"label": "developer", "value": 0}], "title": "go to link", "ismain": true, "classname": "", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_fc1f2", "label": "id", "value": "id"}}], "paramtype": "link", "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true, "act_visible_condition": [{"col": {"t": 1, "key": "id_fc1f2", "label": "id", "value": "id"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/newview", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "create view", "ismain": false, "classname": "", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/copyview", "icon": "fa fa-copy", "type": "API", "roles": [{"label": "developer", "value": 0}], "title": "copy", "ismain": false, "classname": "", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_fc1f2", "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "POST", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "ismain": false, "classname": "", "parametrs": [], "paramtype": null, "actapitype": "POST", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	t	f	f	f	f	f	{}	f
217	SP API	API methods Storage procedures	framework.spapi	table	t	[{"t": 1, "col": "id", "key": "id_64329", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 6, "col": "methodtype", "key": "methodtype_2e0fc", "join": 0, "type": "select", "roles": "[]", "title": "methodtype", "width": "", "depency": null, "visible": 0, "relation": "framework.methodtypes", "classname": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "methotypename", "value": "methotypename"}]},{"t": 2, "col": "methodname", "key": "methodname_06743", "join": 0, "type": "text", "roles": "[]", "title": "method name", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "procedurename", "key": "procedurename_a1796", "join": 0, "type": "text", "roles": "[]", "title": "procedure name", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 6, "col": "methotypename", "key": "methotypename_4f63d", "type": "text", "input": 0, "roles": [], "table": "framework.methodtypes", "title": "methotypename", "tpath": [], "output": 0, "related": 1, "visible": true, "relation": null, "classname": null, "notaddable": 0, "relatecolumn": "methodtype", "relationcolums": "[]"},{"t": 4, "col": "roles", "key": "roles_391ac", "join": 0, "type": "text", "roles": "[]", "title": "roles", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "created", "key": "created_72941", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	spapi	2018-12-21 14:27:50.79	[]	[{"type": "typehead", "roles": [], "title": "found", "column": [{"t": 1, "label": "methodname", "value": "methodname"}, {"t": 1, "label": "procedurename", "value": "procedure name"}], "classname": "form-control"}]	[{"act": "/getone/spapiform?N=0", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": null, "parametrs": [], "paramtype": null, "isforevery": 0}, {"act": "/getone/spapiform", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "N", "paramcolumn": {"t": 1, "key": "id_64329", "label": "id", "value": "id"}}], "paramtype": "query", "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "ismain": false, "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_64329", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": 1}]	[0]	\N	f	t	t	t	f	f	{}	f
224	visible conditions	visibles conditions	framework.visible_condition	table	f	[{"t": 1, "col": "id", "key": "id_ca616", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "configid", "key": "configid_0e8a3", "join": false, "type": "label", "roles": "[]", "title": "configid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "title", "title": "title", "value": "title"}]}, {"t": 2, "col": "title", "key": "title_0.36528457759417576", "join": false, "type": "label", "input": 0, "roles": [], "table": "framework.config", "title": "title", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": true, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "configid", "relationcolums": "[]"}, {"t": 5, "col": "operation", "key": "operation_e0a2e", "join": false, "type": "label", "label": "operation || operation", "roles": "[]", "title": "operation", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "value", "key": "value_5e039", "join": false, "type": "label", "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "created", "key": "created_470de", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	visibles_conditions	2019-10-27 17:05:47.853	[]	[]	[{"act": "/composition/visible_conditions", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "ismain": true, "parametrs": [{"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "_sub_title", "paramtitle": "_sub_title", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "CN", "paramcolumn": {"t": 1, "key": "id_ca616", "label": "id", "value": "id"}}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": true}, {"act": "/composition/view", "icon": "fa fa-arrow-left", "type": "Link", "title": "go back", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "N", "paramcolumn": null}], "isforevery": false}, {"act": "/", "icon": "pi pi-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}, {"act": "/composition/visible_conditions", "icon": "pi pi-plus", "type": "Link", "title": "add", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "_sub_title", "paramtitle": "_sub_title", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
44	Notifications	Notifications	framework.viewsnotification	table	t	[{"t": 1, "col": "id", "key": "id_d4be3", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "viewid", "key": "viewid_f2004", "join": false, "type": "number", "roles": "[]", "title": "viewid", "width": "", "depency": false, "visible": false, "relation": "framework.views", "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "col", "key": "col_186f8", "join": false, "type": "text", "roles": "[]", "title": "col", "width": "", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "tableid", "key": "tableid_aa778", "join": false, "type": "text", "roles": "[]", "title": "tableid", "width": "", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "notificationtext", "key": "notificationtext_3e718", "join": false, "type": "text", "roles": "[]", "title": "notificationtext", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 6, "col": "foruser", "key": "foruser_91970", "join": false, "type": "number", "roles": "[]", "title": "foruser", "width": "", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": [{"act": {"label": "=", "value": "="}, "bool": {"label": "and", "value": "and"}, "value": "_userid_"}], "depencycol": null, "relationcolums": "[]"},{"t": 7, "col": "issend", "key": "issend_a7456", "join": false, "type": "checkbox", "roles": "[]", "title": "issend", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 8, "col": "isread", "key": "isread_f1224", "join": false, "type": "checkbox", "roles": "[]", "title": "isread", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 9, "col": "created", "key": "created_ebdeb", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 10, "col": "sended", "key": "sended_d9382", "join": false, "type": "date", "roles": "[]", "title": "sended", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 11, "col": "readed", "key": "readed_ee0ca", "join": false, "type": "date", "roles": "[]", "title": "readed", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	notifs	2019-03-19 16:03:31.905	[]	[{"t": 1, "type": "check", "roles": [], "table": null, "title": "sended", "column": "issend", "classname": null}, {"t": 1, "type": "check", "roles": [], "table": null, "title": "readed", "column": "isread", "classname": null}]	[]	[0]	\N	t	t	t	t	f	f	{}	f
211	Project Menu		framework.menus	form full	f	[{"t": 1, "col": "id", "key": "id_99b37", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "menutitle", "key": "menutitle_e554e", "join": false, "type": "text", "roles": "[]", "title": "menu title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "menutype", "key": "menutype_5dde7", "join": false, "type": "select", "label": "menutype || menutype", "roles": "[]", "title": "menu type", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "framework.menutypes", "classname": "col-md-11", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "mtypename", "title": "mtypename", "value": "mtypename"}]},{"t": 4, "col": "ismainmenu", "key": "ismainmenu_bc120", "join": false, "type": "checkbox", "roles": "[]", "title": "is main menu", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	projectmenu	2019-08-11 18:33:52	[]	[]	[{"act": "/list/projectmenus", "icon": "fa fa-", "type": "Link", "roles": [], "title": "OK", "ismain": false, "classname": "btn btn", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	f	t	t	t	f	f	{}	f
225	default values	default values	framework.defaultval	table	f	[{"t": 1, "col": "id", "key": "id_24be4", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "configid", "key": "configid_0c694", "join": false, "type": "label", "roles": "[]", "title": "configid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "bool", "key": "bool_c1bb5", "join": false, "type": "select", "roles": "[]", "title": "bool operator", "width": "", "relcol": "bname", "depency": false, "visible": true, "relation": "framework.booloper", "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "bname", "title": "bname", "value": "bname"}]}, {"t": 4, "col": "act", "key": "act_1ae13", "join": false, "type": "select", "roles": "[]", "title": "action", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "value", "title": "value_", "value": "value"}]}, {"t": 5, "col": "value", "key": "value_25aea", "join": false, "type": "text", "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "created", "key": "created_946c2", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	default_values	2019-10-27 21:23:52.258	[]	[]	[{"act": "/composition/defaultval", "icon": "pi pi-plus", "type": "Link", "title": "add", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "relation", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false}, {"act": "/composition/defaultval", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "ismain": true, "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "relation", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "CN", "paramcolumn": {"t": 1, "key": "id_24be4", "label": "id", "value": "id"}}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": true}, {"act": "/composition/view", "type": "Link", "title": "go back", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "N", "paramcolumn": null}], "isforevery": false}, {"act": "/", "icon": "pi pi-trash", "type": "Delete", "title": "delete", "parametrs": [], "isforevery": true}]	[0]	\N	f	t	t	t	f	f	{}	f
100	Trees Acts	Trees Acts	framework.treesacts	table	f	[{"t": 1, "col": "id", "key": "id_a639b", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": false, "visible": false, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "treesid", "key": "treesid_1d756", "join": false, "type": "number", "roles": "[]", "title": "treesid", "width": "", "depency": false, "visible": false, "relation": "framework.trees", "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "title", "key": "title_1556d", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "icon", "key": "icon_69668", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "classname", "key": "classname_12bbd", "join": false, "type": "text", "roles": "[]", "title": "classname", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 6, "col": "act", "key": "act_3f5aa", "join": false, "type": "text", "roles": "[]", "title": "act", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 7, "col": "created", "key": "created_e51e6", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	treesacts	2019-04-17 10:05:28.002	[]	[]	[{"act": "/composition/treesacts", "icon": "fa fa-edit", "type": "Link", "roles": [], "title": "edit", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_a639b", "label": "id", "value": "id"}}, {"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "key": "treesid_1d756", "label": "treesid", "value": "treesid"}}], "paramtype": null, "actapitype": "GET", "isforevery": true}, {"act": "/composition/treesacts", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": null, "parametrs": [{"paramconst": "treesid", "paramtitle": "relation", "paramcolumn": null}, {"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "key": "treesid_1d756", "label": "treesid", "value": "treesid"}}, {"paramconst": "0", "paramtitle": "bid", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": false}, {"act": "/getone/treesact", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_a639b", "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "GET", "isforevery": true}, {"act": "/list/trees", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "go back", "classname": null, "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false}]	[0]	\N	f	f	f	f	f	f	{}	f
213	profile detail	profile detail	framework.users	form full	f	[{"t": 2, "col": "fam", "key": "fam_1fdd0", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "fam", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 2, "onetomany": 0, "updatable": true, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "im", "key": "im_97e79", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "im", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "ot", "key": "ot_3dc36", "join": 0, "type": "text", "chckd": true, "roles": "[]", "title": "ot", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "login", "key": "login_668a5", "join": 0, "type": "text", "chckd": true, "roles": "[]", "title": "login", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 6, "col": "password", "key": "password_e8a55", "join": 0, "type": "password", "chckd": true, "roles": "[]", "title": "password", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 8, "col": "isactive", "key": "isactive_4fd3c", "join": 0, "type": "checkbox", "chckd": true, "roles": "[]", "title": "isactive", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 9, "col": "created", "key": "created_6eef3", "join": 0, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 9, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 10, "col": "roles", "key": "roles_38fa7", "join": false, "type": "multiselect", "chckd": true, "roles": "[]", "title": "roles", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"},{"t": 12, "col": "orgs", "key": "orgs_a0379", "join": false, "type": "multiselect", "chckd": true, "roles": "[]", "title": "orgs", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "orgname", "value": "orgname"}], "relationcolums": "[]", "multiselecttable": "framework.orgs"},{"t": 1, "col": "id", "key": "id_e5b0b", "join": 0, "type": "number", "chckd": true, "roles": "[]", "title": "id", "width": "", "depency": null, "visible": 0, "relation": null, "classname": "col-md-11", "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 11, "col": "roleid", "key": "roleid_b85e3", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "roleid", "width": "", "depency": null, "visible": false, "relation": null, "classname": "col-md-11", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 12, "col": "photo", "key": "photo_89f6d", "join": false, "type": "image", "chckd": true, "roles": "[]", "title": "photo", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	userone	2018-12-28 13:19:10.513	[]	[]	[{"act": "/list/users", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "назад", "classname": "btn btn-success", "parametrs": [], "paramtype": null, "isforevery": 0}]	[0]	\N	f	t	t	t	f	f	{}	f
212	sp api form	sp api form	framework.spapi	form not mutable	f	[{"t": 1, "col": "id", "key": "id_2f194", "join": 0, "type": "number", "roles": "[]", "title": "N", "width": "", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "procedurename", "key": "procedurename_f7596", "join": 0, "type": "text", "roles": "[]", "title": "procedure name", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "methodname", "key": "methodname_d29f9", "join": 0, "type": "text", "roles": "[]", "title": "method name", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 6, "col": "methodtype", "key": "methodtype_0f8c0", "join": 0, "type": "select", "roles": "[]", "title": "methodtype", "width": "", "depency": null, "visible": true, "relation": "framework.methodtypes", "classname": "col-md-11", "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "methotypename", "value": "methotypename"}]},{"t": 4, "col": "roles", "key": "roles_11b3a", "join": 0, "type": "multiselect", "roles": "[]", "title": "roles", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-11", "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"},{"t": 5, "col": "created", "key": "created_cea86", "join": 0, "type": "label", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": false, "relation": null, "classname": "col-md-11", "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	spapiform	2018-12-21 15:40:13.427	[]	[]	[{"act": "/list/spapi", "icon": "fa  fa-arrow-left", "type": "Link", "roles": [], "title": "back", "classname": "btn btn-outline-secondary", "parametrs": [], "paramtype": "query", "isforevery": 0}]	[0]	\N	f	t	t	t	f	f	{}	f
121	report parametr	report parametr	reports.reportparams	form not mutable	f	[{"t": 1, "col": "id", "key": "2xn8jeYed", "join": false, "type": "number", "roles": [], "title": "paramid", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [], "visible_condition": [{"col": {"t": 1, "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "reportlistid", "key": "Qp8OlThyb", "join": false, "type": "number", "roles": [], "title": "reportlistid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "reports.reportlist", "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [], "visible_condition": [{"col": {"t": 1, "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "ptitle", "key": "31p0rDxM7", "join": false, "type": "text", "roles": [], "title": "Название параметра", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [], "visible_condition": [{"col": {"t": 1, "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "ptype", "key": "kO9CCNXmB", "join": false, "type": "select", "label": "ptype || Тип параметра", "roles": "[]", "title": "Тип параметра", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "reports.paramtypes", "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "typename", "title": "typename", "value": "typename"}], "visible_condition": [{"col": {"t": 1, "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 4, "col": "func_paramtitle", "key": "XJ6L7Bgc1", "join": false, "type": "text", "label": "func_paramtitle || Название параметра в функции", "roles": "[]", "title": "Название параметра в функции", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "paramid"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "created", "key": "a4bNeqQbN", "join": false, "type": "date", "roles": [], "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 8, "col": "apimethod", "key": "ETy6UVo_F", "join": false, "type": "select", "label": "apimethod || apimethod", "roles": "[]", "title": "apimethod", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "framework.spapi", "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "methodname", "title": "methodname", "value": "methodname"}, {"label": "procedurename", "title": "procedurename", "value": "procedurename"}], "visible_condition": [{"col": {"t": 1, "label": "ptype", "value": "Тип параметра"}, "value": "2,3,5", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}, {"col": {"t": 1, "label": "id", "value": "paramid"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 9, "col": "orderby", "join": false, "type": "number", "label": "orderby || orderby", "roles": "[]", "title": "orderby", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	reportparam	2019-06-25 16:11:35	[]	[]	[{"act": "/api/save", "icon": "save", "type": "Save", "roles": [], "title": "Сохранить изменения", "classname": "btn btn-success", "parametrs": [], "paramtype": null, "isforevery": false}, {"act": "/composition/reportone", "icon": "check", "type": "Link", "roles": [], "title": "ok", "classname": "btn btn-outline-primary", "parametrs": [{"key": "BCXVf", "paramt": null, "paramconst": "-1", "paramtitle": "paramid", "paramcolumn": ""}, {"key": "Bv4bl", "paramt": null, "paramconst": "", "paramtitle": "reportlistid", "paramcolumn": {"t": 1, "label": "reportlistid", "value": "reportlistid"}}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[{"key": 0, "label": "developer", "value": 0}, 0]		f	t	t	t	f	f	{}	f
120	Reports parametrs	Reports parametrs	reports.reportparams	table	f	[{"t": 1, "col": "id", "key": "Kn0NKmUSY", "join": false, "type": "number", "roles": [], "title": "param_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 2, "col": "reportlistid", "key": "_fubFUahh", "join": false, "type": "number", "roles": [], "title": "reportlistid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "reports.reportlist", "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 3, "col": "ptitle", "key": "Y53QrH5AS", "join": false, "type": "text", "roles": [], "title": "Название параметра", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 4, "col": "func_paramtitle", "key": "B430_9kWT", "join": false, "type": "text", "roles": [], "title": "Название параметра в функции", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 5, "col": "ptype", "key": "iN1LdDyCY", "join": false, "type": "select", "roles": [], "title": "Тип параметра", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "reports.paramtypes", "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "title": "typename", "value": "typename"}]}, {"t": 5, "col": "typename", "key": "A-sfj5QVm", "type": "text", "input": 0, "roles": [], "table": "reports.paramtypes", "title": "Тип", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "ptype", "relationcolums": "[]"}, {"t": 7, "col": "created", "key": "3524oX6-O", "join": false, "type": "date", "roles": [], "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 8, "col": "completed", "key": "gGy_ho08n", "join": false, "type": "checkbox", "label": "completed || completed", "roles": "[]", "title": "completed", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": null, "fn": {"label": "public.fn_completed_colorblack", "value": "public.fn_completed_colorblack", "functype": "user"}, "col": "color", "key": "7E6EUp7C5", "type": "colorrow", "input": 0, "roles": [], "table": null, "title": "color", "tpath": null, "output": 0, "related": true, "visible": false, "relation": null, "fncolumns": [{"t": 1, "label": "completed", "value": "completed"}], "relatecolumn": "", "relationcolums": "[]"}, {"t": 9, "col": "orderby", "join": false, "type": "label", "label": "orderby || orderby", "roles": "[]", "title": "orderby", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	reportparams	2019-06-25 16:04:11	[]	[]	[{"act": "/composition/reportone", "icon": "plus", "type": "Link", "roles": [], "title": "add", "classname": "", "parametrs": [{"key": "uqR4O", "paramt": null, "paramconst": "0", "paramtitle": "paramid", "paramcolumn": ""}, {"key": "h0Ont", "paramt": null, "paramconst": "reportlistid", "paramtitle": "relation", "paramcolumn": ""}, {"key": "jVgA_", "paramt": null, "paramconst": "", "paramtitle": "reportlistid", "paramcolumn": {"t": 1, "label": "reportlistid", "value": "reportlistid"}}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/composition/reportone", "icon": "edit", "type": "Link", "roles": [], "title": "edit", "classname": "", "parametrs": [{"key": "f6QyW", "paramt": null, "paramconst": "", "paramtitle": "paramid", "paramcolumn": {"t": 1, "label": "id", "value": "param_id"}}, {"key": "M8e9t", "paramt": null, "paramconst": "", "paramtitle": "reportlistid", "paramcolumn": {"t": 1, "label": "reportlistid", "value": "reportlistid"}}], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/composition/reportone", "icon": "delete", "type": "Delete", "roles": [], "title": "del", "classname": "", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[{"key": 0, "label": "developer", "value": 0}, 0]	\N	t	f	f	t	f	f	{}	f
119	Report	reports add/edit	reports.reportlist	form not mutable	f	[{"t": 1, "col": "id", "key": "JOnGSRyKG", "join": false, "type": "number", "chckd": true, "roles": [], "title": "reportlistid", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "col-md-12", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 2, "col": "title", "key": "dlOopwPw0", "join": false, "type": "text", "chckd": true, "roles": [], "title": "Название", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 7, "col": "functitle", "key": "aED8FkNoc", "join": false, "type": "select_api", "chckd": true, "roles": [], "title": "Название функции", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/getreports_fn", "relationcolums": []}, {"t": 4, "col": "path", "key": "_2r2cfWZF", "join": false, "type": "text", "chckd": true, "roles": [], "title": "Путь", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 12, "col": "filename", "key": "huoS5sxK-", "join": false, "type": "text", "label": "filename || filename", "roles": "[]", "title": "Название файла", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "template", "key": "2JgoKkLvf", "join": false, "type": "file", "chckd": true, "roles": [], "title": "Файл шаблона", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 3, "col": "roles", "key": "pOfNaTK_F", "join": false, "type": "multiselect", "chckd": true, "roles": [], "title": "Роли", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": [], "multiselecttable": "framework.roles"}, {"t": 6, "col": "template_path", "key": "9hr4DsPxc", "join": false, "type": "text", "chckd": true, "roles": [], "title": "template_path", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "col-md-12", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 8, "col": "created", "key": "NhxnO78Eh", "join": false, "type": "date", "chckd": true, "roles": [], "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "col-md-12", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 9, "col": "section", "key": "XYWGF5Nqn", "join": false, "type": "autocomplete", "label": "section || Секция", "roles": "[]", "title": "Секция", "width": "150", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	reportone	2019-06-25 15:50:17	[]	[]	[{"act": "/api/save", "icon": "save", "type": "Save", "roles": [], "title": "Сохранить изменения", "classname": "btn-success", "parametrs": [], "paramtype": null, "isforevery": false}, {"act": "/list/reports", "icon": "check", "type": "Link", "roles": [], "title": "готово", "classname": "btn btn-success", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[{"key": 0, "label": "developer", "value": 0}, 0]	\N	f	t	t	t	f	f	{}	f
5469	Calendar actions	Calendar actions	framework.calendar_actions	calendar	f	[]	calendaractions	2019-11-15 08:42:17.617568	[]	[]	[]	[0]	\N	f	t	t	t	f	f	{}	f
150	Project menus	all menu settings	framework.menus	table	f	[{"t": 1, "col": "id", "key": "id_45b9e", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "menutitle", "key": "menutitle_dbef5", "join": false, "type": "text", "roles": "[]", "title": "menu title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "mtypename", "key": "mtypename_c7b5a", "type": "text", "input": 0, "roles": [], "table": "framework.menutypes", "title": "menu type", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": 1, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "menutype", "relationcolums": "[]"},{"t": 4, "col": "ismainmenu", "key": "ismainmenu_6f900", "join": false, "type": "checkbox", "roles": "[]", "title": "is main menu", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "menutype", "key": "menutype_08fc0", "join": false, "type": "number", "label": "menutype || menutype", "roles": "[]", "title": "menutype", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.menutypes", "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "mtypename", "title": "mtypename", "value": "mtypename"}]}]	projectmenus	2019-08-11 18:25:07	[]	[]	[{"act": "/getone/projectmenu", "icon": "fa fa-edit", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": "btn", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_45b9e", "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/list/menusettings", "icon": "fa fa-list", "type": "Link", "roles": [], "title": "menu list", "ismain": false, "classname": "", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "menuid", "paramcolumn": {"t": 1, "key": "id_45b9e", "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/getone/projectmenu", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "ismain": false, "classname": "btn", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/getone/projectmenu", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": "btn", "parametrs": [{"paramt": null, "paramconst": "0", "paramtitle": "id", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	t	f	f	f	f	f	{}	f
216	Logs	logs	framework.logtable	table	t	[{"t": 1, "col": "id", "key": "id_34b32", "join": 0, "type": "number", "roles": [{"label": "developer", "value": 0}], "title": "id", "width": "", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "tablename", "key": "tablename_ebb38", "join": 0, "type": "text", "roles": "[]", "title": "tablename", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "tableid", "key": "tableid_fde82", "join": 0, "type": "text", "roles": "[]", "title": "tableid", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "typename", "key": "typename_5e1dd", "type": "text", "input": 0, "roles": [], "table": "framework.opertypes", "title": "typename", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "opertype", "relationcolums": "[]"},{"t": 10, "col": "userid", "key": "userid_ef191", "join": false, "type": "number", "roles": "[]", "title": "userid", "width": "", "depency": false, "visible": false, "relation": "framework.users", "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "login", "title": "login", "value": "login"}]},{"t": 4, "col": "opertype", "key": "opertype_fd401", "join": 0, "type": "select", "roles": "[]", "title": "opertype", "width": "", "depency": null, "visible": 0, "relation": "framework.opertypes", "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "value": "typename"}]},{"t": 10, "col": "login", "key": "login_a0df0", "type": "text", "input": 0, "roles": [], "table": "framework.users", "title": "login", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": null, "notaddable": false, "relatecolumn": "userid", "relationcolums": "[]"},{"t": 6, "col": "oldata", "key": "oldata_0d446", "join": 0, "type": "text", "roles": "[]", "title": "oldata", "width": "", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 7, "col": "newdata", "key": "newdata_19fbf", "join": 0, "type": "text", "roles": "[]", "title": "newdata", "width": "", "depency": null, "visible": false, "relation": null, "classname": null, "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 8, "col": "created", "key": "created_2e98e", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	logs	2018-12-17 16:10:52.48	[]	[{"t": 1, "type": "substr", "roles": [], "table": null, "title": "table name", "column": "tablename", "classname": null}, {"t": 1, "type": "select", "roles": [], "table": {"t": 4, "col": "opertype", "join": 0, "type": "select", "roles": "[]", "title": "opertype", "width": "", "depency": null, "visible": 0, "relation": "framework.opertypes", "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "value": "typename"}]}, "title": "operation type", "column": "opertype", "classname": null}, {"t": 1, "type": "period", "roles": [], "table": null, "title": "created", "column": "created", "classname": null}, {"t": 1, "type": "substr", "roles": [], "table": {"t": 3, "col": "tableid", "join": 0, "type": "text", "roles": "[]", "title": "tableid", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, "title": "table id", "column": "tableid", "classname": "form-control"}]	[{"act": "/getone/log", "icon": "fa fa-eye", "type": "Link", "roles": [], "title": "look", "ismain": true, "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_34b32", "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "GET", "isforevery": true}]	[0]	\N	t	t	f	t	f	f	{}	f
221	Edit configs column	Edit config col	framework.config	form not mutable	f	[{"t": 26, "col": "column_order", "key": "column_order_c7f83", "join": false, "type": "number", "roles": "[]", "title": "column order", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 26, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 1, "col": "id", "key": "id_e0e06", "join": false, "type": "label", "roles": "[]", "title": "N", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "viewid", "key": "viewid_daea5", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "viewtype", "title": "viewtype", "value": "viewtype"}]}, {"t": 3, "col": "t", "key": "t_3e499", "join": false, "type": "label", "roles": "[]", "title": "t", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "col", "key": "col_e6d58", "join": false, "type": "label", "roles": "[]", "title": "column title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "column_id", "key": "column_id_465e6", "join": false, "type": "label", "roles": "[]", "title": "column_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "title", "key": "title_2c03d", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "type", "key": "type_67120", "join": false, "type": "select", "chckd": true, "label": "type || type", "roles": "[]", "title": "type", "width": "", "relcol": "typename", "depency": false, "visible": true, "relation": "framework.columntypes", "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "typename", "title": "typename", "value": "typename"}], "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 27, "col": "fn", "key": "fn_74402", "join": false, "type": "select_api", "label": "fn || function is SELECT", "roles": "[]", "title": "fn", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 27, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/getfunctions", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "fn_74402", "label": "fn", "value": "fn"}, "value": null, "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}, {"t": 28, "col": "fncolumns", "key": "fncolumns_ab6fc", "join": false, "type": "multiselect_api", "label": "fncolumns || Function input parametrs", "roles": "[]", "title": "fn columns", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 28, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/view_cols_for_fn", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "fncolumns_ab6fc", "label": "fncolumns", "value": "fn columns"}, "const": null, "value": null, "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}, {"t": 8, "col": "roles", "key": "roles_75a89", "join": false, "type": "multiselect", "chckd": true, "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 9, "col": "visible", "key": "visible_523ef", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "visible", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 10, "col": "required", "key": "required_00bf1", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "is required", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 11, "col": "width", "key": "width_ff86c", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "width", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 12, "col": "join", "key": "join_be1e1", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "join", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 13, "col": "classname", "key": "classname_c29c2", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "classname", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 14, "col": "updatable", "key": "updatable_51ca3", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "updatable", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 16, "col": "select_api", "key": "select_api_1f4cb", "join": false, "type": "text", "roles": "[]", "title": "select_api", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "type_67120", "label": "type", "value": "type"}, "value": "_api", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}, {"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 18, "col": "orderby", "key": "orderby_98fc5", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "order by", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 19, "col": "orderbydesc", "key": "orderbydesc_7433a", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "order by desc", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 15, "col": "relation", "key": "relation_db866", "join": false, "type": "label", "roles": "[]", "title": "relation table", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "relation_db866", "label": "relation", "value": "relation table"}, "const": null, "value": "", "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}, {"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 17, "col": "multiselecttable", "key": "multiselecttable_9f5f9", "join": false, "type": "select_api", "roles": "[]", "title": "multiselecttable", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/gettables", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "type_67120", "label": "type", "value": "type"}, "value": "multiselect,multitypehead", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}, {"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 20, "col": "relcol", "key": "relcol_3cf99", "join": false, "type": "label", "roles": "[]", "title": "relcol", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 21, "col": "depency", "key": "depency_76519", "join": false, "type": "label", "roles": "[]", "title": " is depency", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 21, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 24, "col": "multicolums", "key": "multicolums_aac16", "join": false, "type": "multiselect_api", "roles": "[]", "title": "multicolums", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 24, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/multi_tabcolumns", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "type_67120", "label": "type", "value": "type"}, "const": null, "value": "multiselect,multitypehead", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}, {"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 23, "col": "relationcolums", "key": "relationcolums_69b4d", "join": false, "type": "multiselect_api", "roles": "[]", "title": "relationcolums", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 23, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/rel_tabcolumns", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "type_67120", "label": "type", "value": "type"}, "value": "select,typehead,array", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}, {"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 25, "col": "depencycol", "key": "depencycol_7f6a2", "join": false, "type": "label", "roles": "[]", "title": "depencycol", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/dep_tabcolumns", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "depency_76519", "label": "depency", "value": " is depency"}, "const": null, "value": "true", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}, {"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 29, "col": "defaultval", "key": "defaultval_bceff", "join": false, "type": "array", "chckd": true, "roles": "[]", "title": "defaultval", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "framework.defaultval", "required": false, "classname": "", "column_id": 29, "onetomany": true, "defaultval": null, "depencycol": "configid", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 30, "col": "select_condition", "key": "select_condition_7e9fa", "join": false, "type": "array", "chckd": true, "roles": "[]", "title": "select_condition", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "framework.select_condition", "required": false, "classname": "", "column_id": 29, "onetomany": true, "defaultval": null, "depencycol": "configid", "relationcolums": [{"label": "col", "value": "col"}, {"label": "operation", "value": "operation"}, {"label": "const", "value": "const"}, {"label": "val_desc", "value": "val_desc"}], "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 31, "col": "visible_condition", "key": "visible_condition_a7c9f", "join": false, "type": "array", "chckd": true, "roles": "[]", "title": "visible_condition", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "framework.visible_condition", "required": false, "classname": "", "column_id": 29, "onetomany": true, "defaultval": null, "depencycol": "configid", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "viewtype", "key": "viewtype_0.1904830102583417", "join": false, "type": "label", "input": 0, "roles": [], "table": "framework.views", "title": "viewtype", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": false, "relation": "framework.viewtypes", "classname": "", "notaddable": true, "relatecolumn": "viewid", "relationcolums": "[]"}]	config	2019-10-25 11:50:39.116	[]	[]	[{"act": "/", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/defaultval", "icon": "pi pi-key", "type": "Link", "title": "default value", "classname": "p-button-primary", "parametrs": [{"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "configid", "paramcolumn": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "viewid", "paramcolumn": {"t": 1, "key": "viewid_daea5", "label": "viewid", "value": "id"}}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/visible_conditions", "icon": "pi pi-question", "type": "LinkTo", "title": "visible condition", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "configid", "paramcolumn": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}}, {"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "_sub_title", "paramcolumn": {"t": 1, "key": "title_2c03d", "label": "title", "value": "title"}}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "viewid", "paramcolumn": {"t": 1, "key": "viewid_daea5", "label": "viewid", "value": "id"}}], "isforevery": false, "act_visible_condition": [{"col": {"t": 2, "key": "viewtype_0.1904830102583417", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "form", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}]}, {"act": "/composition/select_condition", "icon": "pi pi-question", "type": "LinkTo", "title": "select conditions", "classname": "p-button-warning", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "N", "paramcolumn": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "configid", "paramcolumn": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}}, {"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "table", "paramcolumn": {"t": 1, "key": "relation_db866", "label": "relation", "value": "relation table"}}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "_sub_title", "paramcolumn": {"t": 1, "key": "title_2c03d", "label": "title", "value": "title"}}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "viewid", "paramcolumn": {"t": 1, "key": "viewid_daea5", "label": "viewid", "value": "id"}}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "type_67120", "label": "type", "value": "type"}, "const": null, "value": "select,typehead", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}, {"col": {"t": 2, "key": "viewtype_0.1904830102583417", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "form", "operation": {"js": "indexOf", "label": "like", "value": "like", "python": "find"}}]}, {"act": "/composition/view", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_e0e06", "label": "id", "value": "N"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
222	select condition edit	select condition edit	framework.select_condition	form not mutable	f	[{"t": 1, "col": "id", "key": "id_e7177", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "CN", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "configid", "key": "configid_ac752", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "N", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "col", "key": "col_c07f8", "join": false, "type": "select_api", "chckd": false, "roles": "[]", "title": "col", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/tabcolumns_for_sc", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "operation", "key": "operation_ccf99", "join": false, "type": "select", "chckd": false, "label": "operation || operation", "roles": "[]", "title": "operation", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "value", "title": "value_", "value": "value"}], "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 9, "col": "val_desc", "key": "val_desc_ccaab", "join": false, "type": "select_api", "label": "val_desc || val_desc", "roles": "[]", "title": "val_desc", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/view_cols_for_sc", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "const", "key": "const_6d101", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "const", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "value", "key": "value_f930f", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 8, "col": "created", "key": "created_e5c66", "join": false, "type": "label", "chckd": false, "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	select_condition_edit	2019-10-27 13:25:37.106	[]	[]	[{"act": "/", "icon": "", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/select_condition", "icon": "pi pi-cross", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "table", "paramtitle": "table", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "_sub_title", "paramtitle": "_sub_title", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_e7177", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
223	visible condition	visibles condition	framework.visible_condition	form not mutable	f	[{"t": 1, "col": "id", "key": "id_ca616", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "CN", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "configid", "key": "configid_0e8a3", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "configid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 8, "col": "val_desc", "key": "val_desc_e509e", "join": false, "type": "select_api", "chckd": true, "label": "val_desc || val_desc", "roles": "[]", "title": "val_desc", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "framework.config", "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/view_cols_for_sc", "relationcolums": [{"label": "id", "title": "id_", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "col", "key": "col_c9f97", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "col", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 4, "col": "title", "key": "title_0e56d", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 5, "col": "operation", "key": "operation_e0a2e", "join": false, "type": "select", "chckd": true, "label": "operation || operation", "roles": "[]", "title": "operation", "width": "", "relcol": "value", "depency": false, "visible": true, "relation": "framework.operations", "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "value", "title": "value_", "value": "value"}], "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 6, "col": "value", "key": "value_5e039", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "value", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 7, "col": "created", "key": "created_470de", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	visibles_condition	2019-10-27 20:11:08.191	[]	[]	[{"act": "/", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/visible_conditions", "icon": "pi pi-cross", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "_sub_title", "paramtitle": "_sub_title", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_ca616", "label": "id", "value": "CN"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
227	actions	view's actions	framework.actions	table	f	[{"t": 1, "col": "id", "key": "id_24289", "join": false, "type": "label", "roles": "[]", "title": "a_id", "width": "", "relcol": null, "depency": false, "orderby": true, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "column_order", "key": "column_order_12d84", "join": false, "type": "label", "roles": "[]", "title": "order by", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "title", "key": "title_2f66f", "join": false, "type": "label", "roles": "[]", "title": "act title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 16, "col": "act_type", "key": "act_type_f5f68", "join": false, "type": "label", "label": "act_type || act_type", "roles": "[]", "title": "act_type", "width": "", "relcol": "actname", "depency": false, "visible": true, "relation": "framework.acttypes", "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "viewid", "key": "viewid_377d6", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": true, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "icon", "key": "icon_04596", "join": false, "type": "label", "roles": "[]", "title": "act icon", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "classname", "key": "classname_1a0ce", "join": false, "type": "label", "roles": "[]", "title": "class name", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "act_url", "key": "act_url_29725", "join": false, "type": "label", "roles": "[]", "title": "act url", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "api_method", "key": "api_method_5aea3", "join": false, "type": "label", "roles": "[]", "title": "api method", "width": "", "relcol": "aname", "depency": false, "visible": true, "relation": "framework.apicallingmethods", "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "api_type", "key": "api_type_494c8", "join": false, "type": "label", "roles": "[]", "title": "api type", "width": "", "relcol": "val", "depency": false, "visible": true, "relation": "framework.apimethods", "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "refresh_data", "key": "refresh_data_605f9", "join": false, "type": "label", "roles": "[]", "title": "refresh data", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "ask_confirm", "key": "ask_confirm_a1e8d", "join": false, "type": "label", "roles": "[]", "title": "ask confirm", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "roles", "key": "roles_01ded", "join": false, "type": "label", "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "forevery", "key": "forevery_ddd3c", "join": false, "type": "label", "roles": "[]", "title": "for every row", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "main_action", "key": "main_action_2a926", "join": false, "type": "label", "roles": "[]", "title": "main_action", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 15, "col": "created", "key": "created_b5a98", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	acts	2019-10-29 15:07:19.109	[]	[]	[{"act": "/composition/view", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "act_id", "paramcolumn": {"t": 1, "key": "id_24289", "label": "id", "value": "a_id"}}], "isforevery": true}, {"act": "/", "icon": "pi pi-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}, {"act": "/composition/view", "icon": "pi pi-plus", "type": "Link", "title": "add", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "act_id", "paramcolumn": null}, {"paramt": null, "paramconst": "viewid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
229	parametr	action's parametr	framework.act_parametrs	form not mutable	f	[{"t": 1, "col": "id", "key": "id_7989b", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "paramid", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 2, "col": "actionid", "key": "actionid_06ea1", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "act_id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.actions", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 3, "col": "paramtitle", "key": "paramtitle_5ce20", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 8, "col": "val_desc", "key": "val_desc_912b4", "join": false, "type": "select", "chckd": true, "label": "val_desc || val_desc", "roles": "[]", "title": "val_desc", "width": "", "relcol": "id", "depency": false, "visible": true, "relation": "framework.config", "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "title": "id", "value": "id"}, {"label": "title", "title": "title_", "value": "title"}], "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "paramconst_0ddc7", "label": "paramconst", "value": "const"}, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}, {"col": {"t": 1, "key": "paraminput_6fde9", "label": "paraminput", "value": "input"}, "const": null, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}]}, {"t": 5, "col": "paramconst", "key": "paramconst_0ddc7", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "const", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "paraminput_6fde9", "label": "paraminput", "value": "input"}, "const": null, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}, {"col": {"t": 1, "key": "val_desc_912b4", "label": "val_desc", "value": "val_desc"}, "const": null, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}]}, {"t": 6, "col": "paraminput", "key": "paraminput_6fde9", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "input", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}, {"col": {"t": 1, "key": "paramconst_0ddc7", "label": "paramconst", "value": "const"}, "const": null, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}, {"col": {"t": 1, "key": "val_desc_912b4", "label": "val_desc", "value": "val_desc"}, "const": null, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}]}, {"t": 4, "col": "paramt", "key": "paramt_03cdd", "join": false, "type": "select", "chckd": true, "label": "paramt || paramt", "roles": "[]", "title": "method type", "width": "", "relcol": "val", "depency": false, "visible": true, "relation": "framework.paramtypes", "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "val", "title": "val", "value": "val"}], "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"t": 9, "col": "query_type", "key": "query_type_8c815", "join": false, "type": "select", "chckd": true, "label": "query_type || query_type", "roles": "[]", "title": "query type", "width": "", "relcol": "aqname", "depency": false, "visible": true, "relation": "framework.actparam_querytypes", "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "aqname", "title": "aqname", "value": "aqname"}], "visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	action's parametr	2019-10-29 17:17:54.145	[]	[]	[{"act": "/", "icon": "fa fa-check", "type": "Save", "title": "save", "classname": "p-button-success", "parametrs": [], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}, {"act": "/composition/act_params", "icon": "fa fa-cross", "type": "Link", "title": "close", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "actionid", "paramtitle": "actionid", "paramcolumn": null}, {"paramt": null, "paramconst": "actionid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "id", "paramcolumn": null}], "isforevery": false, "act_visible_condition": [{"col": {"t": 1, "key": "id_7989b", "label": "id", "value": "paramid"}, "const": null, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	[0]	\N	f	t	t	t	f	f	{}	f
26	trees	trees components	framework.trees	table	t	[{"t": 1, "col": "id", "key": "id_4725c", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "title", "key": "title_f9eb1", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "url", "key": "url_1baec", "join": false, "type": "text", "roles": "[]", "title": "url", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": [], "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "descr", "key": "descr_5ba2c", "join": false, "type": "text", "roles": "[]", "title": "descr", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "roles", "key": "roles_027bc", "join": false, "type": "text", "roles": "[]", "title": "roles", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "created", "key": "created_071e8", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": [], "depencycol": null, "relationcolums": "[]"}]	trees	2019-03-14 11:21:06.46	[]	[{"type": "typehead", "roles": [], "title": "found", "column": [{"t": 1, "label": "title", "value": "title"}, {"t": 1, "label": "url", "value": "url"}, {"t": 1, "label": "descr", "value": "descr"}], "classname": null}]	[{"act": "/getone/treeform", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": "btn btn", "parametrs": [{"paramconst": "0", "paramtitle": "id", "paramcolumn": null}], "paramtype": null, "isforevery": false}, {"act": "/getone/treeform", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_4725c", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/composition/branches", "icon": "fa fa-code-fork", "type": "Link", "roles": [], "title": "branches", "classname": null, "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "treesid", "paramcolumn": {"t": 1, "key": "id_4725c", "label": "id", "value": "id"}}, {"paramt": null, "paramconst": "-1", "paraminput": "", "paramtitle": "bid", "paramcolumn": null}], "paramtype": null, "isforevery": true}, {"act": "/composition/treesacts", "icon": "fa fa-asterisk", "type": "Link", "roles": [], "title": "actions", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "key": "id_4725c", "label": "id", "value": "id"}}, {"paramconst": "0", "paramtitle": "bid", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_4725c", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}]	[0]	\N	t	t	t	t	f	f	{}	f
28	tree from	tree from	framework.trees	form not mutable	f	[{"t": 1, "col": "id", "key": "id_70eda", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "id", "width": "", "depency": null, "visible": false, "relation": null, "classname": "col-md-11", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "title", "key": "title_0cc41", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "title", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "url", "key": "url_12622", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "url", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "descr", "key": "descr_06b13", "join": false, "type": "textarea", "chckd": true, "roles": "[]", "title": "descr", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "roles", "key": "roles_8bfcc", "join": false, "type": "multiselect", "chckd": true, "roles": "[]", "title": "roles", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"},{"t": 6, "col": "created", "key": "created_fca84", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "depency": null, "visible": false, "relation": null, "classname": "col-md-11", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	treeform	2019-03-14 11:52:57.162	[]	[]	[{"act": "/", "icon": "", "type": "Save", "roles": [], "title": "save", "ismain": false, "classname": "btn btn-outline-success", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/list/trees", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "back", "classname": "btn", "parametrs": [], "paramtype": null, "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
30	branches	branches	framework.treesbranches	table	f	[{"t": 1, "col": "id", "key": "id_7d0e6", "join": false, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "treesid", "key": "treesid_35a0d", "join": false, "type": "number", "roles": "[]", "title": "treesid", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "title", "key": "title_9a870", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "parentid", "key": "parentid_5194a", "join": false, "type": "number", "roles": "[]", "title": "parentid", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "icon", "key": "icon_c8818", "join": false, "type": "text", "roles": "[]", "title": "icon", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "created", "key": "created_bff2e", "join": false, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "treeviewtype", "key": "treeviewtype_dd1c1", "join": false, "type": "number", "roles": "[]", "title": "treeviewtype", "width": "", "depency": false, "visible": true, "relation": "framework.treeviewtypes", "classname": null, "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "viewid", "key": "viewid_0bba1", "join": false, "type": "number", "roles": "[]", "title": "viewid", "width": "", "depency": false, "visible": true, "relation": "framework.views", "classname": null, "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "compoid", "key": "compoid_0f0ca", "join": false, "type": "number", "roles": "[]", "title": "compoid", "width": "", "depency": false, "visible": false, "relation": "framework.compos", "classname": null, "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "orderby", "key": "orderby_5f587", "join": false, "type": "number", "roles": "[]", "title": "orderby", "width": "", "depency": false, "visible": true, "relation": null, "classname": null, "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	branches	2019-03-14 13:42:05.157	[]	[]	[{"act": "/list/trees", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "back", "classname": "btn ", "parametrs": [], "paramtype": null, "isforevery": false}, {"act": "/composition/branches", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "key": "treesid_35a0d", "label": "treesid", "value": "treesid"}}, {"paramconst": null, "paramtitle": "bid", "paramcolumn": {"t": 1, "key": "id_7d0e6", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "del", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_7d0e6", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": true}, {"act": "/composition/branches", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "classname": null, "parametrs": [{"paramconst": "0", "paramtitle": "bid", "paramcolumn": null}, {"paramconst": "treesid", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "treesid", "paramtitle": "treesid", "paramcolumn": null}], "paramtype": null, "isforevery": false}]	[0]	\N	t	f	f	f	f	f	{}	f
233	Apply to selected	apply settings to selected	framework.config	form not mutable	f	[{"t": 2, "col": "viewid", "key": "viewid_a2080", "join": false, "type": "label", "label": "viewid || viewid", "roles": "[]", "title": "viewid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 1, "col": "id", "key": "id_8d5c8", "join": false, "type": "label", "label": "id || id", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "title", "key": "title_60a32", "join": false, "type": "select_api", "label": "title || title", "roles": "[]", "title": "setting", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/configsettings_selectapi", "relationcolums": "[]"}, {"t": 4, "col": "col", "key": "col_b57e1", "join": false, "type": "select_api", "label": "col || column title", "roles": "[]", "title": "column", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/view_cols_for_fn", "relationcolums": "[]"}]	settingsapply	2019-10-31 18:13:18.689	[]	[]	[{"act": "/api/applysettings", "icon": "fa fa-check", "type": "API", "title": "apply to all", "classname": "p-buton-success", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "viewid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "setting", "paramcolumn": {"t": 1, "key": "title_60a32", "label": "title", "value": "setting"}}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "col", "paramcolumn": {"t": 1, "key": "col_b57e1", "label": "col", "value": "column"}}], "actapitype": "POST", "isforevery": false, "actapiconfirm": true, "actapirefresh": true}, {"act": "/composition/view", "icon": "fa fa-refresh", "type": "Link", "title": "refresh", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}, {"paramt": null, "paramconst": "1", "paraminput": "", "paramtitle": "ttt", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
101	Trees Act	Trees Act	framework.treesacts	form full	f	[{"t": 1, "col": "id", "key": "id_f1f88", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "bid", "width": "30%", "depency": false, "visible": false, "relation": null, "classname": "col-md-11", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 2, "col": "treesid", "key": "treesid_d4c60", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "treesid", "width": "30%", "depency": false, "visible": false, "relation": "framework.trees", "classname": "col-md-11", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 3, "col": "title", "key": "title_ce0aa", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "title", "width": "30%", "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 4, "col": "icon", "key": "icon_a2376", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "icon", "width": "30%", "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 5, "col": "classname", "key": "classname_dfafe", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "classname", "width": "30%", "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 6, "col": "act", "key": "act_78fbc", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "act", "width": "30%", "depency": false, "visible": true, "relation": null, "classname": "col-md-11", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 7, "col": "created", "key": "created_5855a", "join": false, "type": "date", "chckd": true, "roles": "[]", "title": "created", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "label": "id", "value": "bid"}, "value": "-1", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]}]	treesact	2019-04-17 10:09:08.709	[]	[]	[{"act": "/composition/treesacts", "icon": "fa fa-check", "type": "Link", "roles": [], "title": "ok", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "treesid", "paramcolumn": {"t": 1, "key": "treesid_d4c60", "label": "treesid", "value": "treesid"}}, {"paramconst": "-1", "paramtitle": "bid", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
235	Menu Edit	Menu Edit	framework.mainmenu	form full	f	[{"t": 1, "col": "id", "key": "id_b1f05", "join": 0, "type": "label", "chckd": true, "roles": [], "title": "id", "width": "", "depency": null, "visible": false, "relation": null, "classname": "col-md-12", "column_id": 1, "onetomany": 0, "updatable": false, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 2, "col": "title", "key": "title_869f2", "join": 0, "type": "text", "chckd": true, "roles": [], "title": "title", "width": "", "depency": null, "visible": 1, "relation": null, "classname": "col-md-12", "column_id": 2, "onetomany": 0, "updatable": true, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 3, "col": "parentid", "key": "parentid_d6e3d", "join": 0, "type": "select", "chckd": true, "input": 0, "roles": [], "title": "parent", "width": "", "output": 0, "depency": null, "visible": 1, "relation": "framework.mainmenu", "classname": "col-md-12", "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "id", "value": "id"}, {"label": "title", "value": "title"}], "select_condition": [{"col": {"label": "menuid", "value": "menuid"}, "const": null, "value": {"t": 1, "label": "menuid", "value": "menuid"}, "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}], "visible_condition": [{"col": {"t": 1, "label": "id", "value": "id"}, "value": "0", "operation": {"js": ">", "label": ">", "value": ">", "python": ">"}}]},{"t": 4, "col": "roles", "key": "roles_05141", "join": 0, "type": "multiselect", "chckd": true, "input": 0, "roles": [], "title": "roles", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "classname": "col-md-12", "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": [], "multiselecttable": "framework.roles"},{"t": 5, "col": "created", "key": "created_2f597", "join": 0, "type": "label", "chckd": true, "input": 0, "roles": [], "title": "created", "width": "", "output": 0, "depency": null, "visible": false, "relation": null, "classname": "col-md-12", "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 6, "col": "systemfield", "key": "systemfield_56127", "join": 0, "type": "checkbox", "chckd": true, "input": 0, "roles": [], "title": "system field", "width": "", "output": 0, "depency": null, "visible": 0, "relation": null, "classname": "col-md-12", "column_id": 6, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 7, "col": "orderby", "key": "orderby_703f8", "join": 0, "type": "number", "chckd": true, "input": 0, "roles": [], "title": "order by", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "classname": "col-md-12", "column_id": 7, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 8, "col": "path", "key": "path_0a221", "join": 0, "type": "text", "chckd": true, "input": 0, "roles": [], "title": "path", "width": "", "output": 0, "depency": null, "visible": 1, "relation": null, "classname": "col-md-12", "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 10, "col": "test", "key": "test_dda44", "join": false, "type": "array", "chckd": true, "roles": [], "title": "test", "width": "", "depency": true, "visible": false, "relation": "framework.test", "classname": "col-md-12", "column_id": 10, "onetomany": true, "defaultval": null, "depencycol": "relat", "relationcolums": []},{"t": 9, "col": "icon", "key": "icon_eb99f", "join": false, "type": "text", "chckd": true, "roles": [], "title": "icon", "width": "", "depency": null, "visible": true, "relation": null, "classname": "col-md-12", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []},{"t": 11, "col": "menuid", "key": "menuid_d4276", "join": false, "type": "number", "chckd": true, "label": "menuid || menuid", "roles": "[]", "title": "menuid", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.menus", "classname": "col-md-12", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	menuedit	2018-11-30 14:23:09	[]	[]	[{"act": "/list/menusettings", "icon": "fa fa-arrow-left", "type": "Link", "roles": [], "title": "back", "classname": "btn", "parametrs": [{"paramt": null, "paramconst": "", "paramtitle": "menuid", "paramcolumn": {"t": 1, "key": "menuid_d4276", "label": "menuid", "value": "menuid"}}], "isforevery": 0}]	[0]	\N	f	t	t	t	f	f	{}	f
236	users	users list	framework.users	table	f	[{"t": 1, "col": "id", "key": "id_ed49e", "join": 0, "type": "number", "roles": "[]", "title": "id", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 1, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 2, "col": "fam", "key": "fam_42544", "join": 0, "type": "text", "roles": "[]", "title": "fam", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 2, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 3, "col": "im", "key": "im_89205", "join": 0, "type": "text", "roles": "[]", "title": "im", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 3, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 4, "col": "ot", "key": "ot_89652", "join": 0, "type": "text", "roles": "[]", "title": "ot", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 4, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 11, "col": "photo", "key": "photo_87018", "join": false, "type": "image", "roles": "[]", "title": "photo", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 5, "col": "login", "key": "login_98129", "join": 0, "type": "text", "roles": "[]", "title": "login", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 5, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 9, "col": "roles", "key": "roles_8ad47", "join": false, "type": "multiselect", "roles": "[]", "title": "roles", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"},{"t": 12, "col": "orgs", "key": "orgs_48bbe", "join": false, "type": "multiselect", "roles": "[]", "title": "orgs", "width": "", "depency": null, "visible": true, "relation": null, "classname": null, "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "orgname", "value": "orgname"}], "relationcolums": "[]", "multiselecttable": "framework.orgs"},{"t": 8, "col": "isactive", "key": "isactive_5bf30", "join": 0, "type": "checkbox", "roles": "[]", "title": "isactive", "width": "", "depency": null, "visible": 0, "relation": null, "classname": null, "column_id": 8, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"},{"t": 9, "col": "created", "key": "created_ec664", "join": 0, "type": "date", "roles": "[]", "title": "created", "width": "", "depency": null, "visible": 1, "relation": null, "classname": null, "column_id": 9, "onetomany": 0, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	users	2018-12-28 13:10:45.637	[]	[{"t": 1, "type": "check", "roles": [], "table": null, "title": "isactive", "column": "isactive", "classname": null}, {"t": 1, "type": "substr", "roles": [], "table": null, "title": "login", "column": "login", "classname": "form-control"}, {"t": 1, "type": "multijson", "roles": [], "table": null, "title": "roles", "column": "roles", "classname": null}]	[{"act": "/getone/userone", "icon": "fa fa-pencil", "type": "Link", "roles": [], "title": "edit user", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_ed49e", "label": "id", "value": "id"}}], "paramtype": "query", "isforevery": 1}, {"act": "/schema/deleterow", "icon": "fa fa-trash", "type": "Delete", "roles": [], "title": "delete", "classname": null, "parametrs": [{"paramconst": null, "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id_ed49e", "label": "id", "value": "id"}}], "paramtype": null, "isforevery": 1}, {"act": "/getone/userone", "icon": "fa fa-plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": "", "parametrs": [{"paramt": null, "paramconst": "0", "paramtitle": "id", "paramcolumn": null}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}]	[0]	\N	f	t	t	t	f	f	{}	f
238	View Main Info	this is for admins views main information.	framework.views	form not mutable	f	[{"t": 1, "col": "id", "key": "id_4e813", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "tablename", "key": "tablename_75be5", "join": false, "type": "select_api", "roles": "[]", "title": "table name", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/gettables", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_4e813", "label": "id", "value": "id"}, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}]}, {"t": 21, "col": "tablename", "key": "tablename_5238b", "join": false, "type": "label", "label": "tablename || tablename", "roles": "[]", "title": "tablename", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_4e813", "label": "id", "value": "id"}, "const": null, "value": null, "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}, {"t": 2, "col": "title", "key": "title_efe1b", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "descr", "key": "descr_9d5d9", "join": false, "type": "textarea", "roles": "[]", "title": "descr", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "path", "key": "path_98923", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "path", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "viewtype", "key": "viewtype_421ce", "join": false, "type": "select", "roles": "[]", "title": "viewtype", "width": "", "relcol": "vtypename", "depency": false, "visible": true, "relation": "framework.viewtypes", "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "vtypename", "title": "vtypename", "value": "vtypename"}]}, {"t": 13, "col": "roles", "key": "roles_ebaac", "join": false, "type": "multiselect", "chckd": false, "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 14, "col": "classname", "key": "classname_859e2", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "classname", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "pagination", "key": "pagination_d6ad4", "join": false, "type": "checkbox", "roles": "[]", "title": "pagination", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 15, "col": "orderby", "key": "orderby_d2011", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "orderby", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 16, "col": "ispagesize", "key": "ispagesize_ea575", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "ispagesize", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 17, "col": "pagecount", "key": "pagecount_be57f", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "pagecount", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 18, "col": "foundcount", "key": "foundcount_4bd77", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "foundcount", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 19, "col": "subscrible", "key": "subscrible_d08b5", "join": false, "type": "checkbox", "chckd": false, "roles": "[]", "title": "subscrible", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": []}, {"t": 20, "col": "checker", "key": "checker_6add0", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "checker", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}]	view	2019-10-24 16:07:07.223	[]	[]	[{"act": "/", "icon": "fa fa-check", "type": "Save", "title": "save main info", "classname": "p-button-success", "parametrs": [], "isforevery": false}, {"act": "/list/views", "icon": "fa fa-arrow-left", "type": "Link", "title": "back to list", "parametrs": [], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
239	Columns config	View's column's configuration	framework.config	table	f	[{"t": 26, "col": "column_order", "key": "column_order_8fa6b", "join": false, "type": "label", "roles": "[]", "title": "column order", "width": "", "relcol": null, "depency": false, "orderby": true, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 26, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 1, "col": "id", "key": "id_af424", "join": false, "type": "label", "roles": "[]", "title": "key", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "viewid", "key": "viewid_93377", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "t", "key": "t_d8775", "join": false, "type": "label", "roles": "[]", "title": "t", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "col", "key": "col_0aabc", "join": false, "type": "label", "roles": "[]", "title": "column title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "column_id", "key": "column_id_02c19", "join": false, "type": "label", "roles": "[]", "title": "column_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "title", "key": "title_d3062", "join": false, "type": "label", "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "type", "key": "type_1a65e", "join": false, "type": "label", "roles": "[]", "title": "type", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "roles", "key": "roles_cfce1", "join": false, "type": "label", "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "visible", "key": "visible_b3377", "join": false, "type": "label", "roles": "[]", "title": "visible", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "required", "key": "required_174be", "join": false, "type": "label", "roles": "[]", "title": "is required", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "width", "key": "width_4cdc6", "join": false, "type": "label", "roles": "[]", "title": "width", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "join", "key": "join_db8e8", "join": false, "type": "label", "roles": "[]", "title": "join", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "classname", "key": "classname_8671b", "join": false, "type": "label", "roles": "[]", "title": "classname", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "updatable", "key": "updatable_f2028", "join": false, "type": "label", "roles": "[]", "title": "updatable", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 18, "col": "orderby", "key": "orderby_84229", "join": false, "type": "checkbox", "roles": "[]", "title": "orderby", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 19, "col": "orderbydesc", "key": "orderbydesc_4b59b", "join": false, "type": "checkbox", "roles": "[]", "title": "orderby desc", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": null, "fn": {"label": "framework.fn_config_relation", "value": "framework.fn_config_relation", "functype": "user"}, "col": "relation", "key": "relation_relation", "type": "text", "input": 0, "roles": [], "table": null, "title": "relation", "tpath": null, "output": 0, "related": true, "visible": true, "relation": null, "fncolumns": [{"t": 1, "key": "id_af424", "label": "id", "value": "#"}], "relatecolumn": "", "relationcolums": "[]"}, {"t": null, "fn": {"label": "framework.fn_config_relationcolumns", "value": "framework.fn_config_relationcolumns", "functype": "user"}, "col": "relationcolums", "key": "relationcolums_relationcolums_1", "type": "text", "input": 0, "roles": [], "table": null, "title": "relationcolums_1", "tpath": null, "output": 0, "related": true, "visible": true, "relation": null, "fncolumns": [{"t": 1, "key": "id_af424", "label": "id", "value": "#"}], "relatecolumn": "", "relationcolums": "[]"}, {"t": 28, "col": "select_condition", "key": "select_condition_f0b20", "join": false, "type": "array", "roles": "[]", "title": "select_condition", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "framework.select_condition", "required": false, "classname": "", "column_id": 27, "onetomany": true, "defaultval": null, "depencycol": "configid", "relationcolums": "[]"}, {"t": 29, "col": "visible_condition", "key": "visible_condition_9cdff", "join": false, "type": "array", "roles": "[]", "title": "visible_condition", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "framework.visible_condition", "required": false, "classname": "", "column_id": 27, "onetomany": true, "defaultval": null, "depencycol": "configid", "relationcolums": "[]"}, {"t": 20, "col": "relcol", "key": "relcol_bb41e", "join": false, "type": "label", "roles": "[]", "title": "relcol", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 21, "col": "depency", "key": "depency_3bf4a", "join": false, "type": "label", "roles": "[]", "title": "depency", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 21, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 22, "col": "created", "key": "created_1b940", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 22, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 25, "col": "depencycol", "key": "depencycol_44a89", "join": false, "type": "label", "roles": "[]", "title": "depencycol", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 25, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 27, "col": "defaultval", "key": "defaultval_273b1", "join": false, "type": "array", "roles": "[]", "title": "defaultval", "width": "", "relcol": null, "depency": true, "visible": true, "relation": "framework.defaultval", "required": false, "classname": "", "column_id": 27, "onetomany": true, "defaultval": null, "depencycol": "configid", "relationcolums": "[]"}]	configs	2019-10-24 16:33:24.168	[]	[{"type": "typehead", "roles": [], "title": "seach", "column": [{"t": 1, "key": "col_0aabc", "label": "col", "value": "column title"}, {"t": 1, "key": "title_d3062", "label": "title", "value": "title"}]}]	[{"act": "/composition/view", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "N", "paramcolumn": {"t": 1, "key": "id_af424", "label": "id", "value": "key"}}, {"paramt": null, "paramconst": "", "paraminput": "fl_id", "paramtitle": "fl_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}], "isforevery": true}, {"act": "/", "icon": "pi pi-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}]	[0]	\N	f	f	f	f	f	t	{}	f
240	select condition	select condition	framework.select_condition	table	f	[{"t": 1, "col": "id", "key": "id_e7177", "join": false, "type": "label", "roles": "[]", "title": "cni", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "configid", "key": "configid_ac752", "join": false, "type": "label", "roles": "[]", "title": "N", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "viewid", "title": "viewid", "value": "viewid"}]}, {"t": 3, "col": "col", "key": "col_c07f8", "join": false, "type": "label", "roles": "[]", "title": "col", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "operation", "key": "operation_367de", "join": false, "type": "label", "roles": "[]", "title": "operation", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "val_desc", "key": "val_desc_04300", "join": false, "type": "label", "label": "val_desc || val_desc", "roles": "[]", "title": "val_desc", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "title", "title": "title", "value": "title"}]}, {"t": 6, "col": "const", "key": "const_6d101", "join": false, "type": "label", "roles": "[]", "title": "const", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "value", "key": "value_f930f", "join": false, "type": "label", "roles": "[]", "title": "val", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "created", "key": "created_e5c66", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "title", "key": "title_0.9293152534345108", "join": false, "type": "label", "input": 0, "roles": [], "table": "framework.config", "title": "value", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": true, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "val_desc", "relationcolums": "[]"}, {"t": 2, "col": "viewid", "key": "viewid_0.4255203251949675", "join": false, "type": "label", "input": 0, "roles": [], "table": "framework.config", "title": "viewid", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": false, "relation": "framework.views", "classname": "", "notaddable": true, "relatecolumn": "configid", "relationcolums": "[]"}]	select_condition	2019-10-27 13:20:11.361	[]	[]	[{"act": "/composition/view", "icon": "arrow-left", "type": "Link", "title": "go back", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "id", "paramcolumn": null}], "isforevery": false}, {"act": "/composition/select_condition", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "CN", "paramcolumn": {"t": 1, "key": "id_e7177", "label": "id", "value": "cni"}}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "table", "paramtitle": "table", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "_sub_title", "paramtitle": "_sub_title", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": true}, {"act": "/", "icon": "pi pi-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}, {"act": "/composition/select_condition", "icon": "pi pi-plus", "type": "Link", "title": "add", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "CN", "paramcolumn": null}, {"paramt": null, "paramconst": "configid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "configid", "paramtitle": "configid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "table", "paramtitle": "table", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "_sub_title", "paramtitle": "_sub_title", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "viewid", "paramtitle": "viewid", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
241	filters	filters	framework.filters	table	f	[{"t": 1, "col": "id", "key": "id_06102", "join": false, "type": "label", "roles": "[]", "title": "f_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "viewid", "key": "viewid_04c9d", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.views", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "column_order", "key": "column_order_e7443", "join": false, "type": "label", "label": "column_order || column_order", "roles": "[]", "title": "column_order", "width": "", "relcol": null, "depency": false, "orderby": true, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "title", "key": "title_769d5", "join": false, "type": "label", "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "type", "key": "type_6ac01", "join": false, "type": "label", "roles": "[]", "title": "type", "width": "", "relcol": "ftname", "depency": false, "visible": true, "relation": "framework.filtertypes", "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "classname", "key": "classname_fa186", "join": false, "type": "label", "roles": "[]", "title": "classname", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "column", "key": "column_a844c", "join": false, "type": "label", "roles": "[]", "title": "column", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "columns", "key": "columns_3048c", "join": false, "type": "label", "roles": "[]", "title": "columns", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "roles", "key": "roles_628d8", "join": false, "type": "label", "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "t", "key": "t_ed9da", "join": false, "type": "label", "roles": "[]", "title": "t", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "table", "key": "table_49b09", "join": false, "type": "label", "roles": "[]", "title": "table", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 11, "col": "created", "key": "created_9dfd6", "join": false, "type": "label", "roles": "[]", "title": "created", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	filters	2019-10-28 15:19:09.292	[]	[]	[{"act": "/composition/view", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "ismain": true, "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "fl_id", "paramcolumn": {"t": 1, "key": "id_06102", "label": "id", "value": "f_id"}}], "isforevery": true}, {"act": "/", "icon": "pi pi-trash", "type": "Delete", "title": "delete", "classname": "p-button-danger", "parametrs": [], "isforevery": true}, {"act": "/composition/view", "icon": "pi pi-plus", "type": "Link", "title": "add", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "id", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "N", "paramtitle": "N", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "act_id", "paramtitle": "act_id", "paramcolumn": null}, {"paramt": null, "paramconst": "viewid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "id", "paramtitle": "viewid", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "fl_id", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
245	Create view	this is for admins views add	framework.views	form not mutable	f	[{"t": 1, "col": "id", "key": "id_4e813", "join": false, "type": "label", "roles": "[]", "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "tablename", "key": "tablename_75be5", "join": false, "type": "select_api", "roles": "[]", "title": "table name", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "select_api": "/api/gettables", "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_4e813", "label": "id", "value": "id"}, "value": null, "operation": {"js": "===null", "label": "is null", "value": "is null", "python": "is None"}}]}, {"t": 21, "col": "tablename", "key": "tablename_5238b", "join": false, "type": "label", "label": "tablename || tablename", "roles": "[]", "title": "tablename", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "id_4e813", "label": "id", "value": "id"}, "const": null, "value": null, "operation": {"js": "!==null", "label": "is not null", "value": "is not null", "python": "is not None"}}]}, {"t": 2, "col": "title", "key": "title_efe1b", "join": false, "type": "text", "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "descr", "key": "descr_9d5d9", "join": false, "type": "textarea", "roles": "[]", "title": "descr", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "path", "key": "path_98923", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "path", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "viewtype", "key": "viewtype_421ce", "join": false, "type": "select", "roles": "[]", "title": "viewtype", "width": "", "relcol": "vtypename", "depency": false, "visible": true, "relation": "framework.viewtypes", "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "vtypename", "title": "vtypename", "value": "vtypename"}]}, {"t": 13, "col": "roles", "key": "roles_ebaac", "join": false, "type": "multiselect", "chckd": false, "roles": "[]", "title": "roles", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "multicolums": [{"label": "id", "value": "id"}, {"label": "rolename", "value": "rolename"}], "relationcolums": "[]", "multiselecttable": "framework.roles"}, {"t": 14, "col": "classname", "key": "classname_859e2", "join": false, "type": "text", "chckd": false, "roles": "[]", "title": "classname", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "pagination", "key": "pagination_d6ad4", "join": false, "type": "checkbox", "roles": "[]", "title": "pagination", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 15, "col": "orderby", "key": "orderby_d2011", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "orderby", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 16, "col": "ispagesize", "key": "ispagesize_ea575", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "ispagesize", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 17, "col": "pagecount", "key": "pagecount_be57f", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "pagecount", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 17, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 18, "col": "foundcount", "key": "foundcount_4bd77", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "foundcount", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 18, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}, {"t": 19, "col": "subscrible", "key": "subscrible_d08b5", "join": false, "type": "checkbox", "chckd": false, "roles": "[]", "title": "subscrible", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 19, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": []}, {"t": 20, "col": "checker", "key": "checker_6add0", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "checker", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 20, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]", "visible_condition": [{"col": {"t": 1, "key": "viewtype_421ce", "label": "viewtype", "value": "viewtype"}, "const": null, "value": "tiles,table", "operation": {"js": "", "label": "in", "value": "in", "python": "in"}}]}]	viewadd	2019-11-04 21:30:34.377	[]	[]	[{"act": "/", "icon": "fa fa-check", "type": "Save", "title": "save main info", "classname": "p-button-success", "parametrs": [], "isforevery": false}, {"act": "/list/views", "icon": "fa fa-arrow-left", "type": "Link", "title": "back to list", "parametrs": [], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
243	parametrs	ACTIONS PARAMETERS	framework.act_parametrs	table	f	[{"t": 1, "col": "id", "key": "id_7989b", "join": false, "type": "label", "roles": "[]", "title": "p_id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "required": false, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "actionid", "key": "actionid_06ea1", "join": false, "type": "label", "roles": "[]", "title": "act_id", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.actions", "required": true, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "paramtitle", "key": "paramtitle_5ce20", "join": false, "type": "label", "roles": "[]", "title": "title", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "title", "key": "title_0.25783669260001485", "join": false, "type": "label", "input": 0, "roles": [], "table": "framework.config", "title": "column", "tpath": [], "output": 0, "relcol": null, "related": true, "visible": true, "relation": null, "classname": "", "notaddable": false, "relatecolumn": "val_desc", "relationcolums": "[]"}, {"t": 5, "col": "paramconst", "key": "paramconst_0ddc7", "join": false, "type": "label", "roles": "[]", "title": "const", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "paraminput", "key": "paraminput_6fde9", "join": false, "type": "label", "roles": "[]", "title": "input", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "paramt", "key": "paramt_66c60", "join": false, "type": "label", "roles": "[]", "title": "method type", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "required": false, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "val_desc", "key": "val_desc_912b4", "join": false, "type": "label", "label": "val_desc || val_desc", "roles": "[]", "title": "val_desc", "width": "", "relcol": "id", "depency": false, "visible": false, "relation": "framework.config", "required": false, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": [{"label": "title", "title": "title_", "value": "title"}]}, {"t": 9, "col": "query_type", "key": "query_type_8c815", "join": false, "type": "label", "label": "query_type || query_type", "roles": "[]", "title": "query type", "width": "", "relcol": "aqname", "depency": false, "visible": true, "relation": "framework.actparam_querytypes", "required": false, "classname": "", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	parametrs	2019-10-29 16:33:55.778	[]	[]	[{"act": "/composition/act_params", "icon": "pi pi-pencil", "type": "Link", "title": "edit", "ismain": true, "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "actionid", "paramtitle": "actionid", "paramcolumn": null}, {"paramt": null, "paramconst": "", "paraminput": "", "paramtitle": "paramid", "paramcolumn": {"t": 1, "key": "id_7989b", "label": "id", "value": "p_id"}}, {"paramt": null, "paramconst": "actionid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}], "isforevery": true}, {"act": "/", "type": "Delete", "title": "delete", "parametrs": [], "isforevery": true}, {"act": "/composition/act_params", "icon": "pi pi-plus", "type": "Link", "title": "add", "parametrs": [{"paramt": null, "paramconst": "", "paraminput": "actionid", "paramtitle": "actionid", "paramcolumn": null}, {"paramt": null, "paramconst": "actionid", "paraminput": "", "paramtitle": "relation", "paramcolumn": null}, {"paramt": null, "paramconst": "0", "paraminput": "", "paramtitle": "paramid", "paramcolumn": null}], "isforevery": false}]	[0]	\N	f	t	t	t	f	f	{}	f
55	account	account	framework.users	form full	f	[{"t": 1, "col": "id", "key": "id_29869", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "id", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11 form-group row", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 2, "col": "fam", "key": "fam_4c0c1", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "fam", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 3, "col": "im", "key": "im_7cba0", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "im", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 4, "col": "ot", "key": "ot_c76fa", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "ot", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "login", "key": "login_d1b0a", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "login", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 6, "col": "password", "key": "password_ba841", "join": false, "type": "password", "chckd": true, "roles": "[]", "title": "password", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 7, "col": "isactive", "key": "isactive_aff55", "join": false, "type": "checkbox", "chckd": true, "roles": "[]", "title": "isactive", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11 form-group row", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 8, "col": "created", "key": "created_262dc", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "created", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 9, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 9, "col": "roles", "key": "roles_edfa4", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "roles", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11 form-group row", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "roleid", "key": "roleid_40f86", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "roleid", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11 form-group row", "column_id": 12, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 12, "col": "orgs", "key": "orgs_054a9", "join": false, "type": "label", "chckd": true, "roles": "[]", "title": "orgs", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11 form-group row", "column_id": 15, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 13, "col": "usersettings", "key": "usersettings_2d728", "join": false, "type": "text", "chckd": true, "roles": "[]", "title": "usersettings", "width": "", "depency": false, "visible": false, "relation": null, "classname": "col-md-11 form-group row", "column_id": 16, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 14, "col": "orgid", "key": "orgid_922b4", "join": false, "type": "number", "chckd": true, "roles": "[]", "title": "orgid", "width": "", "depency": false, "visible": false, "relation": "framework.orgs", "classname": "col-md-11 form-group row", "column_id": 17, "onetomany": false, "defaultval": [{"act": {"label": "=", "value": "="}, "bool": {"label": "and", "value": "and"}, "value": "_orgid_"}], "depencycol": null, "relationcolums": [{"label": "orgname", "title": "orgname", "value": "orgname"}]}, {"t": 14, "col": "orgname", "key": "orgname_d1896", "type": "label", "chckd": true, "input": 0, "roles": [], "table": "framework.orgs", "title": "orgname", "tpath": [], "output": 0, "related": true, "visible": 1, "relation": null, "classname": "col-md-11 form-group row", "notaddable": false, "relatecolumn": "orgid", "relationcolums": "[]"}, {"t": 11, "col": "photo", "key": "photo_6dda5", "join": false, "type": "image", "chckd": true, "roles": "[]", "title": "photo", "width": "", "depency": false, "visible": true, "relation": null, "classname": "col-md-11 form-group row", "column_id": 14, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}]	account	2019-03-19 16:09:24.897	[]	[]	[]	[]	card	f	t	t	t	f	f	{}	f
118	Reports	Reports costructor	reports.reportlist	table	t	[{"t": 1, "col": "id", "key": "gf4pwDf35", "join": false, "type": "number", "roles": [], "title": "id", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 1, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 2, "col": "title", "key": "2FhXSNypi", "join": false, "type": "text", "roles": [], "title": "Название", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 2, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 3, "col": "roles", "key": "1Op1x6gc6", "join": false, "type": "text", "roles": [], "title": "Роли", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 3, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 4, "col": "path", "key": "IcOGsAEL6", "join": false, "type": "text", "roles": [], "title": "Путь", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 4, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 12, "col": "filename", "key": "bAqWoQtS_", "join": false, "type": "text", "label": "filename || filename", "roles": "[]", "title": "Название файла", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 13, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 5, "col": "template", "key": "hmIin2FKF", "join": false, "type": "text", "roles": [], "title": "Файл шаблона", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 5, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 6, "col": "template_path", "key": "VSco1YPgh", "join": false, "type": "text", "roles": [], "title": "template_path", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 6, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 7, "col": "functitle", "key": "theqOaP2M", "join": false, "type": "text", "roles": [], "title": "Название функции", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 7, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 8, "col": "created", "key": "qwpk2Hn_j", "join": false, "type": "date", "roles": [], "title": "Дата создания", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 8, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": []}, {"t": 9, "col": "section", "key": "sB8gOSDgs", "join": false, "type": "text", "label": "section || Секция", "roles": "[]", "title": "Секция", "width": "", "relcol": null, "depency": false, "visible": true, "relation": null, "classname": "", "column_id": 10, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": 10, "col": "completed", "key": "A5Tp_A3Jt", "join": false, "type": "checkbox", "label": "completed || completed", "roles": "[]", "title": "completed", "width": "", "relcol": null, "depency": false, "visible": false, "relation": null, "classname": "", "column_id": 11, "onetomany": false, "defaultval": null, "depencycol": null, "relationcolums": "[]"}, {"t": null, "fn": {"label": "public.fn_completed_colorblack", "value": "public.fn_completed_colorblack", "functype": "user"}, "col": "color", "key": "H1EOWysMs", "type": "colorrow", "input": 0, "roles": [], "table": null, "title": "color", "tpath": null, "output": 0, "related": true, "visible": false, "relation": null, "fncolumns": [{"t": 1, "label": "completed", "value": "completed"}], "relatecolumn": "", "relationcolums": "[]"}]	reports	2019-06-25 15:43:54	[]	[{"key": "BfOrx7w_8", "type": "typehead", "roles": [], "title": "Найти", "column": [{"t": 1, "label": "title", "value": "Название"}, {"t": 1, "label": "functitle", "value": "Название функции"}, {"t": 1, "label": "path", "value": "Путь"}], "classname": ""}]	[{"act": "/getone/reportone", "icon": "plus", "type": "Link", "roles": [], "title": "add", "ismain": false, "classname": "", "parametrs": [{"key": "Lm-Mg", "paramt": null, "paramconst": "0", "paramtitle": "reportlistid", "paramcolumn": ""}], "paramtype": null, "actapitype": "GET", "isforevery": false, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/composition/reportone", "icon": "edit", "type": "Link", "roles": [], "title": "edit", "ismain": true, "classname": "", "parametrs": [{"key": "1uJb0", "paramt": null, "paramconst": "-1", "paramtitle": "paramid", "paramcolumn": ""}, {"key": "i6aqf", "paramt": null, "paramconst": "", "paramtitle": "reportlistid", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/report", "icon": "link", "type": "Link", "roles": [], "title": "перейти к отчёту", "ismain": false, "classname": "", "parametrs": [{"key": "_OBpY", "paramt": null, "paramconst": "", "paramtitle": "id", "paramcolumn": {"t": 1, "label": "id", "value": "id"}}], "paramtype": "link", "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true, "act_visible_condition": [{"col": {"t": 1, "label": "completed", "value": "completed"}, "key": "mZuBY", "value": "true", "operation": {"js": "===", "label": "=", "value": "=", "python": "=="}}]}, {"act": "/", "icon": "delete", "type": "Delete", "roles": [], "title": "del", "ismain": false, "classname": "", "parametrs": [], "paramtype": null, "actapitype": "GET", "isforevery": true, "actapimethod": null, "actapiconfirm": true, "actapirefresh": true}, {"act": "/api/report_copy", "icon": "copy", "type": "API", "roles": [{"key": 0, "label": "developer", "value": 0}], "title": "Копировать отчёт", "ismain": false, "classname": "", "parametrs": [{"key": "Dw5y7", "paramtitle": "id", "paramcolumn": {"t": 1, "key": "id", "label": "id", "value": "id"}}], "actapitype": "POST", "isforevery": true, "actapiconfirm": true, "actapirefresh": true}]	[{"key": 0, "label": "developer", "value": 0}, 0]	\N	t	t	t	t	f	f	{}	f
\.


--
-- TOC entry 3342 (class 0 OID 0)
-- Dependencies: 259
-- Name: views_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('views_id_seq', 5803, true);


--
-- TOC entry 3053 (class 0 OID 180465)
-- Dependencies: 260
-- Data for Name: viewsnotification; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY viewsnotification (id, viewid, col, tableid, notificationtext, foruser, issend, isread, created, sended, readed, doublemess) FROM stdin;
\.


--
-- TOC entry 3343 (class 0 OID 0)
-- Dependencies: 261
-- Name: viewsnotification_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('viewsnotification_id_seq', 3392, true);


--
-- TOC entry 3055 (class 0 OID 180477)
-- Dependencies: 262
-- Data for Name: viewtypes; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY viewtypes (id, vtypename, viewlink) FROM stdin;
1	table	/list/
2	tiles	\N
3	form full	/getone/
4	form not mutable	\N
5	calendar	\N
\.


--
-- TOC entry 3056 (class 0 OID 180483)
-- Dependencies: 263
-- Data for Name: visible_condition; Type: TABLE DATA; Schema: framework; Owner: postgres
--

COPY visible_condition (id, configid, val_desc, col, title, operation, value, created) FROM stdin;
2945	19416	13020	id	\N	>	-1	2019-12-25 11:04:47.818399
2948	19379	13020	id	\N	>	-1	2019-12-25 11:04:47.818399
2947	19381	19416	id	\N	>	-1	2019-12-25 11:04:47.818399
2949	19378	13020	id	\N	>	-1	2019-12-25 11:04:47.818399
2950	19377	13020	id	\N	>	-1	2019-12-25 11:04:47.818399
2951	19376	13020	id	\N	>	-1	2019-12-25 11:04:47.818399
2952	19374	19366	\N	\N	>	-1	2019-12-25 11:35:55.313162
2953	19423	19416	\N	\N	>	-1	2019-12-25 11:36:29.845076
2946	19381	19379	ptype	\N	in	2,3,5	2019-12-25 11:04:47.818399
2115	12915	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2116	12917	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2117	12918	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2118	12919	12919	fn	\N	is not null	\N	2019-11-05 10:00:17.290746
2120	12921	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2121	12922	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2122	12923	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2123	12924	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2124	12925	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2125	12926	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2126	12927	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2128	12928	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2129	12929	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2130	12930	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2131	12931	12931	relation	\N	is not null		2019-11-05 10:00:17.290746
2132	12931	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2134	12932	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2136	12935	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2139	12937	12934	depency	\N	=	true	2019-11-05 10:00:17.290746
2140	12937	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2141	12938	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2142	12939	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2143	12940	12766	id	\N	>	-1	2019-11-05 10:00:17.290746
2144	12942	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2145	12943	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2146	12944	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2147	12945	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2148	12946	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2149	12947	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2150	12948	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2151	12949	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2152	12950	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2153	12951	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2154	12952	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2155	12953	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2156	12954	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2157	12955	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2158	12956	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2159	12957	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2160	12973	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2161	12974	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2162	12975	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2163	12976	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2164	12977	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2165	12978	12942	id	\N	>	-1	2019-11-05 10:00:17.290746
2166	12995	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2133	12932	12918	type	\N	in	multiselect,multitypehead	2019-11-05 10:00:17.290746
2167	12996	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2168	12997	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2169	12998	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2170	12999	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2171	13000	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2172	13001	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2173	13002	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2174	13002	12982	act_type	\N	not in	Save,Delete	2019-11-05 10:00:17.290746
2179	13005	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2181	13006	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2183	13007	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2184	13008	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2185	13009	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2186	13010	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2201	13067	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2202	13068	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2203	13069	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2205	13071	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2206	13072	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2207	13073	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2208	13074	13063	treeviewtype	\N	=	1	2019-11-05 10:00:17.290746
2209	13074	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2212	13076	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2213	13077	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2214	13078	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2215	13079	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2216	13080	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2217	13081	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2218	13082	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2219	13083	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2220	13084	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2226	13136	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2227	13137	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2228	13138	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2230	13189	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2231	13190	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2232	13191	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2233	13192	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2234	13193	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2235	13194	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2138	12936	12912	id	\N	>	-1	2019-11-05 10:00:17.290746
2225	13135	13131	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2229	13140	13131	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2119	12920	12919	fncolumns	\N	is not null	\N	2019-11-05 10:00:17.290746
2127	12928	12918	type	\N	like	_api	2019-11-05 10:00:17.290746
2176	13003	12998	act_type	\N	=	API	2019-11-05 10:00:17.290746
2182	13006	12998	act_type	\N	=	API	2019-11-05 10:00:17.290746
2175	13003	12995	id	\N	>	-1	2019-11-05 10:00:17.290746
2240	13197	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2241	13198	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2242	13199	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2243	13200	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2244	13210	13210	id	\N	>	-1	2019-11-05 10:00:17.290746
2245	13211	13210	id	\N	>	-1	2019-11-05 10:00:17.290746
2246	13212	13210	id	\N	>	-1	2019-11-05 10:00:17.290746
2247	13213	13210	id	\N	>	-1	2019-11-05 10:00:17.290746
2248	13214	13210	id	\N	>	-1	2019-11-05 10:00:17.290746
2249	13215	13210	id	\N	>	-1	2019-11-05 10:00:17.290746
2252	13225	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2253	13226	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2254	13227	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2255	13228	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2256	13229	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2257	13231	12941	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2258	12936	12931	\N	\N	is not null	\N	2019-11-05 13:53:11.161315
2224	13134	13131	viewtype	\N	in	tiles,table	2019-11-05 10:00:17.290746
2238	13196	13189	id	\N	>	-1	2019-11-05 10:00:17.290746
2239	13196	13193	type	\N	=	typehead	2019-11-05 10:00:17.290746
2277	13023	13020	\N	\N	>	-1	2019-11-07 14:55:02.689272
2286	13576	12919	\N	\N	is not null	\N	2019-11-07 15:38:21.141338
2288	13577	13189	\N	\N	>	-1	2019-11-07 16:05:17.783866
2314	12911	12912	\N	\N	>	-1	2019-11-08 08:17:29.243144
2316	13644	12998	\N	\N	=	API	2019-11-08 11:14:07.295998
2135	12935	12918	type	\N	in	multiselect,multitypehead	2019-11-05 10:00:17.290746
2211	13075	13073	treeviewtype	\N	=	2	2019-11-05 10:00:17.290746
2204	13070	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
2210	13075	13067	id	\N	>	-1	2019-11-05 10:00:17.290746
\.


--
-- TOC entry 3344 (class 0 OID 0)
-- Dependencies: 264
-- Name: visible_condition_id_seq; Type: SEQUENCE SET; Schema: framework; Owner: postgres
--

SELECT pg_catalog.setval('visible_condition_id_seq', 3012, true);


SET search_path = reports, pg_catalog;

--
-- TOC entry 3058 (class 0 OID 180499)
-- Dependencies: 265
-- Data for Name: paramtypes; Type: TABLE DATA; Schema: reports; Owner: postgres
--

COPY paramtypes (id, typename) FROM stdin;
1	date
2	select
3	typehead
4	checkbox
5	multiselect
6	text
7	number
\.


--
-- TOC entry 3059 (class 0 OID 180502)
-- Dependencies: 266
-- Data for Name: reportlist; Type: TABLE DATA; Schema: reports; Owner: postgres
--

COPY reportlist (id, title, roles, path, template, template_path, functitle, created, section, completed, filename) FROM stdin;
\.


--
-- TOC entry 3345 (class 0 OID 0)
-- Dependencies: 267
-- Name: reportlist_id_seq; Type: SEQUENCE SET; Schema: reports; Owner: postgres
--

SELECT pg_catalog.setval('reportlist_id_seq', 13, true);


--
-- TOC entry 3061 (class 0 OID 180513)
-- Dependencies: 268
-- Data for Name: reportparams; Type: TABLE DATA; Schema: reports; Owner: postgres
--

COPY reportparams (id, reportlistid, ptitle, func_paramtitle, ptype, created, apimethod, completed, orderby) FROM stdin;
2	\N	test	test	7	2019-08-16 15:56:41.530712	\N	f	1
3	\N	test	test	6	2019-08-16 16:00:05.511128	\N	f	1
18	\N	id	id	7	2019-11-22 16:56:05.632311	\N	f	1
27	\N	\N	\N	\N	2019-12-25 13:32:34.679113	\N	f	1
35	\N	\N	\N	\N	2019-12-26 17:15:54.270695	\N	f	1
37	\N	\N	\N	\N	2019-12-30 12:37:46.211876	\N	f	1
\.


--
-- TOC entry 3346 (class 0 OID 0)
-- Dependencies: 269
-- Name: reportparams_id_seq; Type: SEQUENCE SET; Schema: reports; Owner: postgres
--

SELECT pg_catalog.setval('reportparams_id_seq', 39, true);


SET search_path = test, pg_catalog;

--
-- TOC entry 3066 (class 0 OID 194799)
-- Dependencies: 273
-- Data for Name: dictionary_for_select; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY dictionary_for_select (id, dname, onemoreraltionid) FROM stdin;
1	FIrst	\N
2	Second	\N
3	Third	\N
4	Fourth	\N
5	Fifth	\N
\.


--
-- TOC entry 3347 (class 0 OID 0)
-- Dependencies: 272
-- Name: dictionary_for_select_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('dictionary_for_select_id_seq', 5, true);


--
-- TOC entry 3068 (class 0 OID 194859)
-- Dependencies: 275
-- Data for Name: major_table; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY major_table (id, text, data, "check", "time", password, color, multiselect, file, typehead, image, images, gallery, label, number, link, texteditor, colorrow, multitypehead_api, multi_select_api, colorpicker, "select", autocomplete, textarea, files, typehead_api, select_api, multitypehead, datetime, html) FROM stdin;
\.


--
-- TOC entry 3348 (class 0 OID 0)
-- Dependencies: 274
-- Name: major_table_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('major_table_id_seq', 1, false);


--
-- TOC entry 3064 (class 0 OID 194791)
-- Dependencies: 271
-- Data for Name: onemorerelation; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY onemorerelation (id, oname) FROM stdin;
1	one
2	two
\.


--
-- TOC entry 3349 (class 0 OID 0)
-- Dependencies: 270
-- Name: onemorerelation_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('onemorerelation_id_seq', 2, true);


--
-- TOC entry 3070 (class 0 OID 194881)
-- Dependencies: 277
-- Data for Name: relate_with_major; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY relate_with_major (id, somecolumn, major_table_id, created) FROM stdin;
\.


--
-- TOC entry 3350 (class 0 OID 0)
-- Dependencies: 276
-- Name: relate_with_major_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('relate_with_major_id_seq', 1, false);


SET search_path = framework, pg_catalog;

--
-- TOC entry 2652 (class 2606 OID 194309)
-- Name: act_parametrs_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_parametrs
    ADD CONSTRAINT act_parametrs_pkey PRIMARY KEY (id);


--
-- TOC entry 2655 (class 2606 OID 194311)
-- Name: act_visible_condions_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_visible_condions
    ADD CONSTRAINT act_visible_condions_pkey PRIMARY KEY (id);


--
-- TOC entry 2658 (class 2606 OID 194313)
-- Name: actions_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actions
    ADD CONSTRAINT actions_pkey PRIMARY KEY (id);


--
-- TOC entry 2661 (class 2606 OID 194315)
-- Name: actparam_querytypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actparam_querytypes
    ADD CONSTRAINT actparam_querytypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2664 (class 2606 OID 194317)
-- Name: acttypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY acttypes
    ADD CONSTRAINT acttypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2667 (class 2606 OID 194319)
-- Name: apicallingmethods_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY apicallingmethods
    ADD CONSTRAINT apicallingmethods_pkey PRIMARY KEY (id);


--
-- TOC entry 2669 (class 2606 OID 194321)
-- Name: apimethods_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY apimethods
    ADD CONSTRAINT apimethods_pkey PRIMARY KEY (id);


--
-- TOC entry 2673 (class 2606 OID 194323)
-- Name: booloper_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY booloper
    ADD CONSTRAINT booloper_pkey PRIMARY KEY (id);


--
-- TOC entry 2675 (class 2606 OID 194325)
-- Name: calendar_actions_id_key; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY calendar_actions
    ADD CONSTRAINT calendar_actions_id_key UNIQUE (id);


--
-- TOC entry 2677 (class 2606 OID 194327)
-- Name: calendar_test_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY calendar_test
    ADD CONSTRAINT calendar_test_pkey PRIMARY KEY (id);


--
-- TOC entry 2679 (class 2606 OID 194329)
-- Name: columntypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY columntypes
    ADD CONSTRAINT columntypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2682 (class 2606 OID 194331)
-- Name: compos_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY compos
    ADD CONSTRAINT compos_pkey PRIMARY KEY (id);


--
-- TOC entry 2686 (class 2606 OID 194333)
-- Name: config_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- TOC entry 2688 (class 2606 OID 194335)
-- Name: configsettings_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY configsettings
    ADD CONSTRAINT configsettings_pkey PRIMARY KEY (id);


--
-- TOC entry 2691 (class 2606 OID 194337)
-- Name: defaultval_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY defaultval
    ADD CONSTRAINT defaultval_pkey PRIMARY KEY (id);


--
-- TOC entry 2693 (class 2606 OID 194339)
-- Name: dialog_messages_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_messages
    ADD CONSTRAINT dialog_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 2695 (class 2606 OID 194341)
-- Name: dialog_notifications_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_notifications
    ADD CONSTRAINT dialog_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 2697 (class 2606 OID 194343)
-- Name: dialog_statuses_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_statuses
    ADD CONSTRAINT dialog_statuses_pkey PRIMARY KEY (id);


--
-- TOC entry 2699 (class 2606 OID 194345)
-- Name: dialog_types_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_types
    ADD CONSTRAINT dialog_types_pkey PRIMARY KEY (id);


--
-- TOC entry 2701 (class 2606 OID 194347)
-- Name: dialogs_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialogs
    ADD CONSTRAINT dialogs_pkey PRIMARY KEY (id);


--
-- TOC entry 2705 (class 2606 OID 194349)
-- Name: filters_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_pkey PRIMARY KEY (id);


--
-- TOC entry 2708 (class 2606 OID 194351)
-- Name: filtertypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filtertypes
    ADD CONSTRAINT filtertypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2710 (class 2606 OID 194353)
-- Name: functions_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY functions
    ADD CONSTRAINT functions_pkey PRIMARY KEY (id);


--
-- TOC entry 2712 (class 2606 OID 194355)
-- Name: logtable_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY logtable
    ADD CONSTRAINT logtable_pkey PRIMARY KEY (id);


--
-- TOC entry 2714 (class 2606 OID 194357)
-- Name: mainmenu_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY mainmenu
    ADD CONSTRAINT mainmenu_pkey PRIMARY KEY (id);


--
-- TOC entry 2716 (class 2606 OID 194359)
-- Name: mainsettings_isactiv_key; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY mainsettings
    ADD CONSTRAINT mainsettings_isactiv_key UNIQUE (isactiv);


--
-- TOC entry 2718 (class 2606 OID 194361)
-- Name: menus_manus_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY menus
    ADD CONSTRAINT menus_manus_pkey PRIMARY KEY (id);


--
-- TOC entry 2720 (class 2606 OID 194363)
-- Name: menus_menutype_key; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY menus
    ADD CONSTRAINT menus_menutype_key UNIQUE (menutype);


--
-- TOC entry 2722 (class 2606 OID 194365)
-- Name: menutypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY menutypes
    ADD CONSTRAINT menutypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2725 (class 2606 OID 194367)
-- Name: methodtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY methodtypes
    ADD CONSTRAINT methodtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2727 (class 2606 OID 194369)
-- Name: operations_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY operations
    ADD CONSTRAINT operations_pkey PRIMARY KEY (id);


--
-- TOC entry 2730 (class 2606 OID 194371)
-- Name: opertypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY opertypes
    ADD CONSTRAINT opertypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2732 (class 2606 OID 194375)
-- Name: orgs_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 2734 (class 2606 OID 194379)
-- Name: paramtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY paramtypes
    ADD CONSTRAINT paramtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2736 (class 2606 OID 194383)
-- Name: roles_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 2739 (class 2606 OID 194385)
-- Name: select_condition_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY select_condition
    ADD CONSTRAINT select_condition_pkey PRIMARY KEY (id);


--
-- TOC entry 2742 (class 2606 OID 194387)
-- Name: spapi_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY spapi
    ADD CONSTRAINT spapi_pkey PRIMARY KEY (id);


--
-- TOC entry 2744 (class 2606 OID 194391)
-- Name: trees_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY trees
    ADD CONSTRAINT trees_pkey PRIMARY KEY (id);


--
-- TOC entry 2746 (class 2606 OID 194393)
-- Name: treesacts_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesacts
    ADD CONSTRAINT treesacts_pkey PRIMARY KEY (id);


--
-- TOC entry 2748 (class 2606 OID 194395)
-- Name: treesbranches_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT treesbranches_pkey PRIMARY KEY (id);


--
-- TOC entry 2750 (class 2606 OID 194397)
-- Name: treeviewtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treeviewtypes
    ADD CONSTRAINT treeviewtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2753 (class 2606 OID 194399)
-- Name: users_thumbprint_key; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_thumbprint_key UNIQUE (thumbprint);


--
-- TOC entry 2755 (class 2606 OID 194401)
-- Name: views_path_key; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY views
    ADD CONSTRAINT views_path_key UNIQUE (path);


--
-- TOC entry 2757 (class 2606 OID 194403)
-- Name: views_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY views
    ADD CONSTRAINT views_pkey PRIMARY KEY (id);


--
-- TOC entry 2759 (class 2606 OID 194405)
-- Name: viewsnotification_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewsnotification
    ADD CONSTRAINT viewsnotification_pkey PRIMARY KEY (id);


--
-- TOC entry 2761 (class 2606 OID 194407)
-- Name: viewtypes_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewtypes
    ADD CONSTRAINT viewtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2763 (class 2606 OID 194409)
-- Name: visible_condition_pkey; Type: CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY visible_condition
    ADD CONSTRAINT visible_condition_pkey PRIMARY KEY (id);


SET search_path = reports, pg_catalog;

--
-- TOC entry 2765 (class 2606 OID 194413)
-- Name: paramtypes_pkey; Type: CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY paramtypes
    ADD CONSTRAINT paramtypes_pkey PRIMARY KEY (id);


--
-- TOC entry 2767 (class 2606 OID 194415)
-- Name: reportlist_path_key; Type: CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportlist
    ADD CONSTRAINT reportlist_path_key UNIQUE (path);


--
-- TOC entry 2769 (class 2606 OID 194417)
-- Name: reportlist_pkey; Type: CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportlist
    ADD CONSTRAINT reportlist_pkey PRIMARY KEY (id);


--
-- TOC entry 2771 (class 2606 OID 194419)
-- Name: reportparams_pkey; Type: CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportparams
    ADD CONSTRAINT reportparams_pkey PRIMARY KEY (id);


SET search_path = test, pg_catalog;

--
-- TOC entry 2775 (class 2606 OID 194804)
-- Name: dictionary_for_select_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY dictionary_for_select
    ADD CONSTRAINT dictionary_for_select_pkey PRIMARY KEY (id);


--
-- TOC entry 2777 (class 2606 OID 194867)
-- Name: major_table_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY major_table
    ADD CONSTRAINT major_table_pkey PRIMARY KEY (id);


--
-- TOC entry 2773 (class 2606 OID 194796)
-- Name: onemorerelation_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY onemorerelation
    ADD CONSTRAINT onemorerelation_pkey PRIMARY KEY (id);


--
-- TOC entry 2779 (class 2606 OID 194887)
-- Name: relate_with_major_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY relate_with_major
    ADD CONSTRAINT relate_with_major_pkey PRIMARY KEY (id);


SET search_path = framework, pg_catalog;

--
-- TOC entry 2650 (class 1259 OID 194420)
-- Name: act_parametrs_idx; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX act_parametrs_idx ON act_parametrs USING btree (actionid);


--
-- TOC entry 2653 (class 1259 OID 194421)
-- Name: act_visible_condions_idx; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX act_visible_condions_idx ON act_visible_condions USING btree (actionid);


--
-- TOC entry 2656 (class 1259 OID 194422)
-- Name: actions_idx; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX actions_idx ON actions USING btree (viewid);


--
-- TOC entry 2659 (class 1259 OID 194423)
-- Name: actparam_querytypes_aqname_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX actparam_querytypes_aqname_key ON actparam_querytypes USING btree (aqname);


--
-- TOC entry 2662 (class 1259 OID 194424)
-- Name: acttypes_actname_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX acttypes_actname_key ON acttypes USING btree (actname);


--
-- TOC entry 2665 (class 1259 OID 194425)
-- Name: apicallingmethods_aname_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX apicallingmethods_aname_key ON apicallingmethods USING btree (aname);


--
-- TOC entry 2670 (class 1259 OID 194426)
-- Name: apimethods_val_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX apimethods_val_key ON apimethods USING btree (val);


--
-- TOC entry 2671 (class 1259 OID 194427)
-- Name: booloper_bname_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX booloper_bname_key ON booloper USING btree (bname);


--
-- TOC entry 2680 (class 1259 OID 194428)
-- Name: columntypes_typename_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX columntypes_typename_key ON columntypes USING btree (typename);


--
-- TOC entry 2683 (class 1259 OID 194429)
-- Name: config_idx_uniq_title; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX config_idx_uniq_title ON config USING btree (viewid, title);


--
-- TOC entry 2684 (class 1259 OID 194430)
-- Name: config_idx_view; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX config_idx_view ON config USING btree (viewid);


--
-- TOC entry 2689 (class 1259 OID 194431)
-- Name: defaultval_idxconfd; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX defaultval_idxconfd ON defaultval USING btree (configid);


--
-- TOC entry 2702 (class 1259 OID 194432)
-- Name: filters_idx; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX filters_idx ON filters USING btree (title, viewid);


--
-- TOC entry 2703 (class 1259 OID 194433)
-- Name: filters_idx1; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX filters_idx1 ON filters USING btree (viewid);


--
-- TOC entry 2706 (class 1259 OID 194434)
-- Name: filtertypes_ftname_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX filtertypes_ftname_key ON filtertypes USING btree (ftname);


--
-- TOC entry 2723 (class 1259 OID 194435)
-- Name: methodtypes_methotypename_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX methodtypes_methotypename_key ON methodtypes USING btree (methotypename);


--
-- TOC entry 2728 (class 1259 OID 194436)
-- Name: operations_value_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX operations_value_key ON operations USING btree (value);


--
-- TOC entry 2737 (class 1259 OID 194437)
-- Name: select_condition_idx_sc; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX select_condition_idx_sc ON select_condition USING btree (configid);


--
-- TOC entry 2740 (class 1259 OID 194438)
-- Name: spapi_idx; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE INDEX spapi_idx ON spapi USING btree (methodname, methodtype);


--
-- TOC entry 2751 (class 1259 OID 194439)
-- Name: users_id_key; Type: INDEX; Schema: framework; Owner: postgres
--

CREATE UNIQUE INDEX users_id_key ON users USING btree (id);


--
-- TOC entry 2835 (class 2620 OID 194445)
-- Name: actions_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER actions_tr BEFORE INSERT OR UPDATE ON actions FOR EACH ROW EXECUTE PROCEDURE tr_actions_tr();


--
-- TOC entry 2836 (class 2620 OID 194446)
-- Name: actions_tr_del; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER actions_tr_del BEFORE DELETE ON actions FOR EACH ROW EXECUTE PROCEDURE tr_actions_tr_del();


--
-- TOC entry 2837 (class 2620 OID 194447)
-- Name: calendar_actions_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER calendar_actions_tr BEFORE INSERT OR UPDATE ON calendar_actions FOR EACH ROW EXECUTE PROCEDURE tr_calendar_actions_tr();

ALTER TABLE calendar_actions DISABLE TRIGGER calendar_actions_tr;


--
-- TOC entry 2838 (class 2620 OID 194448)
-- Name: config_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER config_tr BEFORE UPDATE ON config FOR EACH ROW EXECUTE PROCEDURE tr_config_tr();


--
-- TOC entry 3351 (class 0 OID 0)
-- Dependencies: 2838
-- Name: TRIGGER config_tr ON config; Type: COMMENT; Schema: framework; Owner: postgres
--

COMMENT ON TRIGGER config_tr ON config IS 'config checks';


--
-- TOC entry 2839 (class 2620 OID 194449)
-- Name: config_tr_del; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER config_tr_del BEFORE DELETE ON config FOR EACH ROW EXECUTE PROCEDURE tr_config_tr_del();


--
-- TOC entry 2840 (class 2620 OID 194450)
-- Name: config_tr_ins; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER config_tr_ins BEFORE INSERT ON config FOR EACH ROW EXECUTE PROCEDURE tr_config_tr_ins();


--
-- TOC entry 2841 (class 2620 OID 194451)
-- Name: dialog_messages_tr_ins; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER dialog_messages_tr_ins BEFORE INSERT ON dialog_messages FOR EACH ROW EXECUTE PROCEDURE tr_dialog_messages_tr_ins();


--
-- TOC entry 2842 (class 2620 OID 194452)
-- Name: dialogs_tr_edit; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER dialogs_tr_edit BEFORE UPDATE ON dialogs FOR EACH ROW EXECUTE PROCEDURE tr_dialogs_tr_edit();


--
-- TOC entry 2843 (class 2620 OID 194453)
-- Name: dialogs_tr_ins; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER dialogs_tr_ins BEFORE INSERT ON dialogs FOR EACH ROW EXECUTE PROCEDURE tr_dialogs_tr_ins();


--
-- TOC entry 2844 (class 2620 OID 194454)
-- Name: dialogs_tr_ins_after; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER dialogs_tr_ins_after AFTER INSERT ON dialogs FOR EACH ROW EXECUTE PROCEDURE tr_dialogs_tr_ins_after();


--
-- TOC entry 2845 (class 2620 OID 194455)
-- Name: filters_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER filters_tr BEFORE INSERT OR UPDATE ON filters FOR EACH ROW EXECUTE PROCEDURE tr_filters_tr();


--
-- TOC entry 2846 (class 2620 OID 194456)
-- Name: menus_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER menus_tr BEFORE INSERT OR UPDATE OF menutype, ismainmenu ON menus FOR EACH ROW EXECUTE PROCEDURE tr_menu_tr();


--
-- TOC entry 2847 (class 2620 OID 194457)
-- Name: menus_tr_del; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER menus_tr_del BEFORE DELETE ON menus FOR EACH ROW EXECUTE PROCEDURE tr_menus_tr_del();


--
-- TOC entry 2848 (class 2620 OID 194459)
-- Name: select_condition_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER select_condition_tr BEFORE INSERT OR UPDATE ON select_condition FOR EACH ROW EXECUTE PROCEDURE tr_select_condition_tr();

ALTER TABLE select_condition DISABLE TRIGGER select_condition_tr;


--
-- TOC entry 2849 (class 2620 OID 194460)
-- Name: spapi_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER spapi_tr BEFORE INSERT OR UPDATE ON spapi FOR EACH ROW EXECUTE PROCEDURE tr_spapi_tr();


--
-- TOC entry 2850 (class 2620 OID 194461)
-- Name: trees_add_org; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER trees_add_org AFTER INSERT OR UPDATE OF userid ON trees FOR EACH ROW EXECUTE PROCEDURE tr_trees_add_org();


--
-- TOC entry 2851 (class 2620 OID 194462)
-- Name: trees_tr_del; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER trees_tr_del BEFORE DELETE ON trees FOR EACH ROW EXECUTE PROCEDURE tr_trees_tr_del();


--
-- TOC entry 2852 (class 2620 OID 194463)
-- Name: treesbranches_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER treesbranches_tr BEFORE INSERT OR UPDATE OF viewid, compoid, ismain ON treesbranches FOR EACH ROW EXECUTE PROCEDURE tr_treesbranch_check();


--
-- TOC entry 2853 (class 2620 OID 194464)
-- Name: users_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER users_tr BEFORE UPDATE OF password, roles, orgs, userid ON users FOR EACH ROW EXECUTE PROCEDURE tr_user_check();


--
-- TOC entry 2854 (class 2620 OID 194465)
-- Name: views_tr_check; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER views_tr_check BEFORE INSERT OR UPDATE ON views FOR EACH ROW EXECUTE PROCEDURE tr_view_tr_check();


--
-- TOC entry 2855 (class 2620 OID 194466)
-- Name: views_tr_del; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER views_tr_del BEFORE DELETE ON views FOR EACH ROW EXECUTE PROCEDURE tr_views_tr_del();


--
-- TOC entry 2856 (class 2620 OID 194467)
-- Name: views_tr_ins_after; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER views_tr_ins_after AFTER INSERT ON views FOR EACH ROW EXECUTE PROCEDURE tr_views_tr_ins_after();


--
-- TOC entry 2857 (class 2620 OID 194468)
-- Name: viewsnotification_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER viewsnotification_tr AFTER UPDATE OF issend ON viewsnotification FOR EACH ROW EXECUTE PROCEDURE tr_viewsnotification_del_doubles();


--
-- TOC entry 2858 (class 2620 OID 194469)
-- Name: visible_condition_tr; Type: TRIGGER; Schema: framework; Owner: postgres
--

CREATE TRIGGER visible_condition_tr BEFORE INSERT OR UPDATE ON visible_condition FOR EACH ROW EXECUTE PROCEDURE tr_visible_condition_tr();

ALTER TABLE visible_condition DISABLE TRIGGER visible_condition_tr;


SET search_path = reports, pg_catalog;

--
-- TOC entry 2859 (class 2620 OID 194470)
-- Name: reportlist_tr; Type: TRIGGER; Schema: reports; Owner: postgres
--

CREATE TRIGGER reportlist_tr BEFORE UPDATE OF title, path, template, functitle, section ON reportlist FOR EACH ROW EXECUTE PROCEDURE tr_reportlist_tr();


--
-- TOC entry 2861 (class 2620 OID 194772)
-- Name: reportlist_tr_del; Type: TRIGGER; Schema: reports; Owner: postgres
--

CREATE TRIGGER reportlist_tr_del BEFORE DELETE ON reportlist FOR EACH ROW EXECUTE PROCEDURE tr_reportlist_tr_del();


--
-- TOC entry 2860 (class 2620 OID 194471)
-- Name: reportlist_tr_ins; Type: TRIGGER; Schema: reports; Owner: postgres
--

CREATE TRIGGER reportlist_tr_ins BEFORE INSERT ON reportlist FOR EACH ROW EXECUTE PROCEDURE tr_reportlist_tr_ins();


--
-- TOC entry 2862 (class 2620 OID 194472)
-- Name: reportparams_tr; Type: TRIGGER; Schema: reports; Owner: postgres
--

CREATE TRIGGER reportparams_tr BEFORE INSERT OR UPDATE ON reportparams FOR EACH ROW EXECUTE PROCEDURE tr_reportparams_tr();


SET search_path = test, pg_catalog;

--
-- TOC entry 2863 (class 2620 OID 194878)
-- Name: major_table_tr; Type: TRIGGER; Schema: test; Owner: postgres
--

CREATE TRIGGER major_table_tr BEFORE INSERT OR UPDATE ON major_table FOR EACH ROW EXECUTE PROCEDURE tr_major_table_tr();


SET search_path = framework, pg_catalog;

--
-- TOC entry 2780 (class 2606 OID 194473)
-- Name: act_parametrs_fk_action; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_parametrs
    ADD CONSTRAINT act_parametrs_fk_action FOREIGN KEY (actionid) REFERENCES actions(id);


--
-- TOC entry 2781 (class 2606 OID 194478)
-- Name: act_parametrs_fk_confg; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_parametrs
    ADD CONSTRAINT act_parametrs_fk_confg FOREIGN KEY (val_desc) REFERENCES config(id);


--
-- TOC entry 2782 (class 2606 OID 194483)
-- Name: act_parametrs_fk_qt; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_parametrs
    ADD CONSTRAINT act_parametrs_fk_qt FOREIGN KEY (query_type) REFERENCES actparam_querytypes(aqname);


--
-- TOC entry 2783 (class 2606 OID 194488)
-- Name: act_visible_condions_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_visible_condions
    ADD CONSTRAINT act_visible_condions_fk FOREIGN KEY (val_desc) REFERENCES config(id);


--
-- TOC entry 2784 (class 2606 OID 194493)
-- Name: act_visible_condions_fk1; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_visible_condions
    ADD CONSTRAINT act_visible_condions_fk1 FOREIGN KEY (operation) REFERENCES operations(value);


--
-- TOC entry 2785 (class 2606 OID 194498)
-- Name: act_visible_condions_fk_act; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY act_visible_condions
    ADD CONSTRAINT act_visible_condions_fk_act FOREIGN KEY (actionid) REFERENCES actions(id);


--
-- TOC entry 2786 (class 2606 OID 194503)
-- Name: actions_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actions
    ADD CONSTRAINT actions_fk FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2787 (class 2606 OID 194508)
-- Name: actions_fk_actype; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actions
    ADD CONSTRAINT actions_fk_actype FOREIGN KEY (act_type) REFERENCES acttypes(actname);


--
-- TOC entry 2788 (class 2606 OID 194513)
-- Name: actions_fk_apicalinme; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actions
    ADD CONSTRAINT actions_fk_apicalinme FOREIGN KEY (api_method) REFERENCES apicallingmethods(aname);


--
-- TOC entry 2789 (class 2606 OID 194518)
-- Name: actions_fk_apimeth; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY actions
    ADD CONSTRAINT actions_fk_apimeth FOREIGN KEY (api_type) REFERENCES methodtypes(methotypename);


--
-- TOC entry 2819 (class 2606 OID 194523)
-- Name: compos_fk1; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT compos_fk1 FOREIGN KEY (compoid) REFERENCES compos(id);


--
-- TOC entry 2790 (class 2606 OID 194528)
-- Name: config_fk_ct; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_fk_ct FOREIGN KEY (type) REFERENCES columntypes(typename);


--
-- TOC entry 2791 (class 2606 OID 194533)
-- Name: config_fk_view; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_fk_view FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2792 (class 2606 OID 194538)
-- Name: defaultval_fk_ao; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY defaultval
    ADD CONSTRAINT defaultval_fk_ao FOREIGN KEY (act) REFERENCES operations(value);


--
-- TOC entry 2793 (class 2606 OID 194543)
-- Name: defaultval_fk_bo; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY defaultval
    ADD CONSTRAINT defaultval_fk_bo FOREIGN KEY (bool) REFERENCES booloper(bname);


--
-- TOC entry 2794 (class 2606 OID 194548)
-- Name: defaultval_fk_config; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY defaultval
    ADD CONSTRAINT defaultval_fk_config FOREIGN KEY (configid) REFERENCES config(id);


--
-- TOC entry 2795 (class 2606 OID 194553)
-- Name: dialog_messages_forward; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_messages
    ADD CONSTRAINT dialog_messages_forward FOREIGN KEY (forwarded_from) REFERENCES dialog_messages(id);


--
-- TOC entry 2796 (class 2606 OID 194558)
-- Name: dialog_messages_reply; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_messages
    ADD CONSTRAINT dialog_messages_reply FOREIGN KEY (reply_to) REFERENCES dialog_messages(id);


--
-- TOC entry 2797 (class 2606 OID 194563)
-- Name: dialog_messages_user; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_messages
    ADD CONSTRAINT dialog_messages_user FOREIGN KEY (userid) REFERENCES users(id);


--
-- TOC entry 2798 (class 2606 OID 194568)
-- Name: dialog_notifications_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_notifications
    ADD CONSTRAINT dialog_notifications_fk FOREIGN KEY (sender_userid) REFERENCES users(id);


--
-- TOC entry 2799 (class 2606 OID 194573)
-- Name: dialog_notifications_fk1; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_notifications
    ADD CONSTRAINT dialog_notifications_fk1 FOREIGN KEY (userid) REFERENCES users(id);


--
-- TOC entry 2800 (class 2606 OID 194578)
-- Name: dialog_notifications_fk_dialog; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialog_notifications
    ADD CONSTRAINT dialog_notifications_fk_dialog FOREIGN KEY (dialog_id) REFERENCES dialogs(id);


--
-- TOC entry 2801 (class 2606 OID 194583)
-- Name: dialogs_fk_dt; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialogs
    ADD CONSTRAINT dialogs_fk_dt FOREIGN KEY (dtype) REFERENCES dialog_types(id);


--
-- TOC entry 2802 (class 2606 OID 194588)
-- Name: dialogs_fk_st; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialogs
    ADD CONSTRAINT dialogs_fk_st FOREIGN KEY (status) REFERENCES dialog_statuses(id);


--
-- TOC entry 2803 (class 2606 OID 194593)
-- Name: dialogs_fk_userid; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY dialogs
    ADD CONSTRAINT dialogs_fk_userid FOREIGN KEY (userid) REFERENCES users(id);


--
-- TOC entry 2804 (class 2606 OID 194598)
-- Name: filters_fk_c; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_fk_c FOREIGN KEY (val_desc) REFERENCES config(id);


--
-- TOC entry 2805 (class 2606 OID 194603)
-- Name: filters_fk_ft; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_fk_ft FOREIGN KEY (type) REFERENCES filtertypes(ftname);


--
-- TOC entry 2806 (class 2606 OID 194608)
-- Name: filters_fk_vi; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_fk_vi FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2807 (class 2606 OID 194613)
-- Name: logtype_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY logtable
    ADD CONSTRAINT logtype_fk FOREIGN KEY (opertype) REFERENCES opertypes(id);


--
-- TOC entry 2809 (class 2606 OID 194618)
-- Name: mainmenu_fk_menu; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY mainmenu
    ADD CONSTRAINT mainmenu_fk_menu FOREIGN KEY (menuid) REFERENCES menus(id);


--
-- TOC entry 2810 (class 2606 OID 194628)
-- Name: menus_fk_mt; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY menus
    ADD CONSTRAINT menus_fk_mt FOREIGN KEY (menutype) REFERENCES menutypes(id);


--
-- TOC entry 2823 (class 2606 OID 194633)
-- Name: org_f; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT org_f FOREIGN KEY (orgid) REFERENCES orgs(id);


--
-- TOC entry 2811 (class 2606 OID 194638)
-- Name: orgs_fk_prnt; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_fk_prnt FOREIGN KEY (parentid) REFERENCES orgs(id);


--
-- TOC entry 2812 (class 2606 OID 194643)
-- Name: orgs_fk_uid; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_fk_uid FOREIGN KEY (userid) REFERENCES users(id);


--
-- TOC entry 2813 (class 2606 OID 194653)
-- Name: select_condition_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY select_condition
    ADD CONSTRAINT select_condition_fk FOREIGN KEY (operation) REFERENCES operations(value);


--
-- TOC entry 2814 (class 2606 OID 194658)
-- Name: select_condition_fk_config; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY select_condition
    ADD CONSTRAINT select_condition_fk_config FOREIGN KEY (configid) REFERENCES config(id);


--
-- TOC entry 2815 (class 2606 OID 194663)
-- Name: select_condition_fk_valconf; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY select_condition
    ADD CONSTRAINT select_condition_fk_valconf FOREIGN KEY (val_desc) REFERENCES config(id);


--
-- TOC entry 2817 (class 2606 OID 194668)
-- Name: spapi_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY spapi
    ADD CONSTRAINT spapi_fk FOREIGN KEY (methodtype) REFERENCES methodtypes(id);


--
-- TOC entry 2818 (class 2606 OID 194673)
-- Name: treesacts_fk_tr; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesacts
    ADD CONSTRAINT treesacts_fk_tr FOREIGN KEY (treesid) REFERENCES trees(id);


--
-- TOC entry 2820 (class 2606 OID 194678)
-- Name: treesbranches_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT treesbranches_fk FOREIGN KEY (parentid) REFERENCES treesbranches(id);


--
-- TOC entry 2821 (class 2606 OID 194683)
-- Name: treeview; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT treeview FOREIGN KEY (treeviewtype) REFERENCES treeviewtypes(id);


--
-- TOC entry 2816 (class 2606 OID 194688)
-- Name: us_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY sess
    ADD CONSTRAINT us_fk FOREIGN KEY (userid) REFERENCES users(id) ON DELETE CASCADE;


--
-- TOC entry 2808 (class 2606 OID 194693)
-- Name: userid_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY logtable
    ADD CONSTRAINT userid_fk FOREIGN KEY (userid) REFERENCES users(id);


--
-- TOC entry 2824 (class 2606 OID 194698)
-- Name: viewid_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY viewsnotification
    ADD CONSTRAINT viewid_fk FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2822 (class 2606 OID 194703)
-- Name: viewid_fk; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY treesbranches
    ADD CONSTRAINT viewid_fk FOREIGN KEY (viewid) REFERENCES views(id);


--
-- TOC entry 2825 (class 2606 OID 194708)
-- Name: visible_condition_fk_config; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY visible_condition
    ADD CONSTRAINT visible_condition_fk_config FOREIGN KEY (configid) REFERENCES config(id);


--
-- TOC entry 2826 (class 2606 OID 194713)
-- Name: visible_condition_fk_oper; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY visible_condition
    ADD CONSTRAINT visible_condition_fk_oper FOREIGN KEY (operation) REFERENCES operations(value);


--
-- TOC entry 2827 (class 2606 OID 194718)
-- Name: visible_condition_fk_v; Type: FK CONSTRAINT; Schema: framework; Owner: postgres
--

ALTER TABLE ONLY visible_condition
    ADD CONSTRAINT visible_condition_fk_v FOREIGN KEY (val_desc) REFERENCES config(id);


SET search_path = reports, pg_catalog;

--
-- TOC entry 2828 (class 2606 OID 194723)
-- Name: paramtype_fk; Type: FK CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportparams
    ADD CONSTRAINT paramtype_fk FOREIGN KEY (ptype) REFERENCES paramtypes(id);


--
-- TOC entry 2829 (class 2606 OID 194728)
-- Name: reportlist_fk; Type: FK CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportparams
    ADD CONSTRAINT reportlist_fk FOREIGN KEY (reportlistid) REFERENCES reportlist(id);


--
-- TOC entry 2830 (class 2606 OID 194733)
-- Name: reportparams_fk_api; Type: FK CONSTRAINT; Schema: reports; Owner: postgres
--

ALTER TABLE ONLY reportparams
    ADD CONSTRAINT reportparams_fk_api FOREIGN KEY (apimethod) REFERENCES framework.spapi(id);


SET search_path = test, pg_catalog;

--
-- TOC entry 2831 (class 2606 OID 194805)
-- Name: dictionary_for_select_fk_or; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY dictionary_for_select
    ADD CONSTRAINT dictionary_for_select_fk_or FOREIGN KEY (onemoreraltionid) REFERENCES onemorerelation(id);


--
-- TOC entry 2832 (class 2606 OID 194868)
-- Name: major_table_seldic; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY major_table
    ADD CONSTRAINT major_table_seldic FOREIGN KEY ("select") REFERENCES dictionary_for_select(id);


--
-- TOC entry 2833 (class 2606 OID 194873)
-- Name: major_table_th; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY major_table
    ADD CONSTRAINT major_table_th FOREIGN KEY (typehead) REFERENCES dictionary_for_select(id);


--
-- TOC entry 2834 (class 2606 OID 194888)
-- Name: relate_with_major_tab_id; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY relate_with_major
    ADD CONSTRAINT relate_with_major_tab_id FOREIGN KEY (major_table_id) REFERENCES major_table(id);


--
-- TOC entry 3077 (class 0 OID 0)
-- Dependencies: 10
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2019-12-31 15:10:17

--
-- PostgreSQL database dump complete
--


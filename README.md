# Current Version
Jelata Framework v. 0.0.6

# Getting Started
Jelata Framework is a tool combining a framework and development environment that you can use in your browser. 
The Jelata Framework is designed to simplify the development task with ready-made components that already have a bundle with data in the database.  
To start using you will need:  
                        <ul>
							<li>python 3 (recommended to use python versions older than 3.4)</li>
							<li>PostgreSQL DBMS (PostgreSQL version 9.5 is recommended)</li>
							<li>node js </li>
						</ul>
						<p>For python, you must install the following libraries:</p>
                        <ul>
							<li>tornado v. 4.5.3</li>
							<li>momoko</li>
							<li>xlsx2html</li>
						</ul>
						
<pre>pip install -Iv tornado==4.5.3 
pip install momoko
pip install xlsx2html
</pre>

<p>For start report service go to the path ./reports and install all modules and start node server (or use pm2 deamon).</p>
<pre>npm i
node index.js
</pre>

Next, you need to create the project database by running the script from the framework.sql file (If you already have a database to which you want to connect, you need to create all the objects from the framework.sql script in your database).
Base name can be renamed.
The last step is to check the settings for connecting to the database server in the settings.json file, if everything is correct, then start the server:

<pre>
python3 run_server.py
</pre>
After starting the server, in the browser, go to http://127.0.0.1:8080 and in the user menu click on the login item

<p><b>login:</b> admin</p>
<p><b>password:</b> 123</p>
<p>PS Be sure to change the administrator password before release.</p>
<p>For see template components	follow the link  http://127.0.0.1:8080/list/test</p>

You can write your own front-end for framework using <a href="https://github.com/YaSargis/jelata-framework-ant-frontend">main frontent project</a>				

## Authors

* **Kazaryan Sargis**

<h2><strong class="ql-size-huge">Jelata Framework</strong></h2><p><br></p><p><strong>In order to get started, make sure that:</strong></p><ul><li>all project files are in a folder called&nbsp;<strong>jelataframework</strong>&nbsp;.</li><li>all settings, including those for connecting to the database, are correctly specified in the&nbsp;<strong>settings.json</strong>&nbsp;file</li><li>your database contains all the data and objects from the&nbsp;<strong>framework.sql</strong>&nbsp;file</li></ul><p><br></p><p><strong>To start the server, type the command&nbsp;<em>python3 run_server.py</em></strong>&nbsp;on Linux systems and&nbsp;<strong><em>python run_server.py</em></strong>&nbsp;on winsows systems (if python 3 is version).</p><p>To start the print server, you need to have node js&gt; 6 v, install all the dependencies for the project in the reports folder, to do this, type&nbsp;<strong><em>npm i</em></strong></p><h3><br></h3><h3><strong class="ql-size-large">Main Settings</strong></h3><p>The main project settings can be accessed through&nbsp;<span style="background-color: rgb(0, 21, 41); color: rgb(255, 255, 255);">Project Settings-&gt; Global Project Settings -&gt; Global Settings</span>&nbsp;or the pop-up path / getone / mainsettings.&nbsp;All settings in are stored in the settings.json file and are duplicated in the database in the framework.mainsettings table.&nbsp;Basic properties:</p><ul><li><em><u>db connection string</u></em>&nbsp;- DB<em><u>&nbsp;connection string</u></em></li><li><em><u>project server port</u></em>&nbsp;- port on which the web server is running</li><li><em><u>main domain</u></em>&nbsp;- project domain in production</li><li><em><u>primary authorization</u></em>&nbsp;- sign of authorization, does the project require mandatory authorization to work</li><li><em><u>redirect401</u></em>&nbsp;- redirects along this path in case of 401 error status</li><li><em><u>home page</u></em>&nbsp;- project home page</li><li><em><u>login_url</u></em>&nbsp;- login page</li><li><em><u>reports_url</u></em>&nbsp;- report service server</li><li><em><u>ischat</u></em>&nbsp;- show the chat icon in the lower right corner</li></ul><p><br></p><h3><strong class="ql-size-large">Views</strong></h3><p><strong><em>﻿</em>View -</strong>&nbsp;these are the main components (configurations for rendering and data connection) used in the project.&nbsp;They are in the framework.views table and also in the auxiliary tables: framework.config (framework.defaultval, framework.select_condition, framework.visible_condition), framework.actions (framework.act_parametrs, framework.act_visible_condions), framework.filters.&nbsp;Heap data is collected using the&nbsp;<strong>framework</strong>&nbsp;function&nbsp;<strong>. "Fn_view_getByPath" (_path varchar, _viewtype varchar, out outjson json)</strong>&nbsp;and processed using the&nbsp;<em>/libs/admin.py</em>&nbsp;and&nbsp;<em>/libs/sql_migration.py files</em>&nbsp;.&nbsp;We recommend creating and editing them from the admin panel, which is located in the menu item&nbsp;<span style="background-color: rgb(0, 21, 41); color: rgb(255, 255, 255);">Project Settings-&gt; Components -&gt; Views</span>&nbsp;, or along the path / list / views.</p><p>The main properties of the view include:&nbsp;<strong><em>table</em></strong>&nbsp;- the main table,&nbsp;<strong><em>path</em></strong>&nbsp;- the path,&nbsp;<strong><em>title</em></strong>&nbsp;- the name,&nbsp;<strong><em>roles</em></strong>&nbsp;- the roles of users with viewing rights (the roles are in the table&nbsp;<em>framework.roles</em>&nbsp;),&nbsp;<strong><em>classname</em></strong>&nbsp;- the name of the CSS class that can be applied to the entire component ,&nbsp;<strong><em>viewtype</em></strong>&nbsp;- type of component (view)&nbsp;<strong>,&nbsp;<em>subscrible</em></strong>&nbsp;- opens a web-socket through which you can send messages and update the view (table&nbsp;<em>framework.viewsnotification</em>&nbsp;).&nbsp;And for table types (tiles, table)&nbsp;<strong><em>pagination</em></strong>&nbsp;- includes paging.</p><p><br></p><p>Using the&nbsp;<strong><em>showsql</em></strong>&nbsp;button,&nbsp;<strong><em>you</em></strong>&nbsp;can get the SQL script that turned out according to your config.</p><p><br></p><p>Currently 4 types of components are working:</p><ul><li>table - table</li><li>tiles - tile list</li><li>form full - the form instantly saves data (saves data after entering)</li><li>form not mutable - form without instant saving</li></ul><p><br></p><p><strong>A link is attached to each type in the system, by which you can go to this view.</strong></p><p><strong>For type&nbsp;<em>table</em></strong>&nbsp;-&nbsp;<em>/ list / &lt;path&gt;</em></p><p><strong>For <em>form full</em></strong>&nbsp;и&nbsp;<strong><em>form not mutable&nbsp;</em></strong><em>- /getone/&lt;path&gt;</em></p><p><strong>For type&nbsp;<em>tiles</em></strong>&nbsp;-&nbsp;<em>/ tiles / &lt;path&gt;</em></p><p><br></p><p><strong>A very important point is the&nbsp;transfer of parameters</strong>&nbsp;in the address bar to the specified view, because&nbsp;These parameters are filters for view.</p><p>For example, we have a view accessible on the path / list / myview with the field myfieldid, if you pass in the path / list / myview? Myfieldid = 13, then we get records that have myfieldid = 13, but myfieldid is not the name of the field in the table, and the "title" parameter in config-e view (see the description of config).&nbsp;For a view of type form full and form not mutable, you must pass a parameter that narrows the returned lines to 1, most often this is an explicit id indication, for example, / getone / myform? Id = 1</p><p>To create an entry in the form, you must specify a non-existent id, most often it is id = 0 (/ getone / myform? Id = 0).</p><p><br></p><p><strong><em>relation parameter:</em></strong></p><p><strong>the relation parameter is needed to transfer the names of the fields of the tables that need to be written to the table when creating the record, except for explicitly passed ones, their values ​​should also be indicated in the address bar in the parameters with the table field name and value.&nbsp;For example, we add to the table mytable, which is indicated as the main one in view myview, such as form full, for this we went along the path&nbsp;</strong><em><u>/ getone / myview? Id = 0,</u></em>&nbsp;and since&nbsp;it is form full, then after the first change of the input a request is sent to save the data and a record is created, but for example, the logic table requires another not null field - nnull_field, and in order to fill it in, we pass its name to the relation parameter -&nbsp;<em>relation = nnull_field,</em>&nbsp;and the parameter nnull_field with the value&nbsp;<em>nnull_field = 1</em>as a result, for full-fledged work, we get the path&nbsp;<em><u>/ getone / myview? id = 0 &amp; relation = nnull_field &amp; nnull_field = 1</u></em>&nbsp;.&nbsp;If you need to pass several parameters, we list them separated by commas, for example:&nbsp;<em><u>/ getone / myview? Id = 0 &amp; relation = field1, field2 &amp; field1 = 1 &amp; field2 = teststring</u></em></p><p><br></p><p><strong><em>userid:</em></strong></p><p><strong>If there is a&nbsp;<em>userid</em></strong>&nbsp;field in the table&nbsp;, then when the row is changed by standard means (form full and action of the Save and Delete type), the current user will be recorded.</p><p><br></p><p>Each type of view component has its own settings -&nbsp;<strong>config,</strong>&nbsp;depending on the type.</p><p><br></p><h4><strong><em>Description of config fields:</em></strong></h4><ul><li><em><u>column_order</u></em>&nbsp;- field display order</li><li><em><u>fn</u></em>&nbsp;is a function, for the type of column function, this is also a field whose value is returned by the given plpgsql function, also depends on the parameter fncolumns - parameters passed to the function, for example SELECT id, fn1 (id) FROM mytable, where fn1 is the value fn.&nbsp;It is most often used for simple functions, such as displaying color, counting something, or when foreign key relationships are not specified, which does not allow building further joins, or when the database has ambiguous and complex relationships between tables.&nbsp;May inhibit work, check the speed of the function.</li><li><em><u>fncolumns</u></em>&nbsp;- parameters passed to the function</li><li><em><u>col</u></em>&nbsp;- field name in the table</li><li><em><u>title</u></em>&nbsp;- the name of the field in the component, also by the value of this field you can filter data using the input parameters in the address bar, for example / list / myview? field title = test title</li><li><em><u>type</u></em>&nbsp;- the type of the field, the behavior of the field depends on it, its display and communication with the data, for a more detailed description of each type, see column types below</li><li><em><u>visible</u></em>&nbsp;- flag to display the field, if true then the user sees it on the component, if false then the user does not see it, but the data is returned and can be manipulated</li><li><em><u>required</u></em>&nbsp;- is it mandatory to specify a filter for this field, serves as a defense against user attempts to change the value of a given filter and see all records, use if necessary</li><li><em><u>orderby</u></em>&nbsp;- sort by this field</li><li><em><u>orderbydesc</u></em>&nbsp;- rotate sorting, works only if orderby is selected</li><li><em><u>updatable</u></em>&nbsp;- used for view of type form full, updates data after each save, also used to update the entire composition (read below)</li><li><em><u>classname</u></em>&nbsp;- application of css styles, css class name</li><li><em><u>editable</u></em>&nbsp;- used for the table type - a modifiable cell in a table, makes it possible to change data inside a table cell</li><li><em><u>join</u></em>&nbsp;- if there is a relationship with another table, it uses JOIN instead of LEFT JOIN; the connection with another table is determined by the relation field and the presence of a foreign key in the table.</li><li><em><u>width</u></em>&nbsp;- width, you can use 100px, 70%, or markup from 1-24, 24 is the whole line, by default 12 is half</li><li><em><u>roles</u></em>&nbsp;- roles to which the field is accessible</li><li><em><u>relation</u></em>&nbsp;- the table with which the field is associated with the help of foreign key.&nbsp;In the case of types select_api, typehead_api, multiselect_api, multitypehead_api - the path to the API method (read more in the description of types), in the case of types multiselect, multitypehead - a table where I will take the values ​​(read more in the description of types).</li><li><em><u>relationcolums</u></em>&nbsp;- fields that can be pulled from the relation table (LEFT JOIN) are also used as fields for values ​​of select, typehead, etc.&nbsp;It is also possible to build join-s based on relationships from extended fields, the only condition must be specified foreign key</li><li><em><u>select_condition</u></em>&nbsp;- conditions for type fields selct, typehead for a list of values ​​from the table specified in relation</li><li><em><u>visible_condition</u></em>&nbsp;- field display conditions</li><li><em><u>defaultval</u></em>&nbsp;- the value that the filter goes into the query sql condition, for example WHERE field1 = 1</li></ul><h4><br></h4><h4><strong><em>Types of config-a fields:</em></strong></h4><ul><li><em><u>label</u></em>&nbsp;- type for displaying the value - html component label</li><li><em><u>text</u></em>&nbsp;- html input with type text</li><li><em><u>number</u></em>&nbsp;- html input c типом number</li><li><em><u>phone</u></em>&nbsp;- html input with mask for phone</li><li><em><u>password</u></em>&nbsp;- html input of type password.&nbsp;If this type is selected for the field, then the value written to the database is encrypted in md5.&nbsp;The value is not returned to the form, input will always be empty.</li><li><em><u>textarea</u></em>&nbsp;- html component of textarea</li><li><em><u>texteditor</u></em>&nbsp;- text editor, saves formatted text as html</li><li><em><u>autocomplete</u></em>&nbsp;- autocomplete, searches for data on the entire table by the entered passage, returns a list of the entered text and the data found (only form)</li><li><em><u>certificate</u></em>&nbsp;- the choice of a certificate of available digital signatures may not work, because&nbsp;requires an extension in the browser and script to work with the extension (form only)</li><li><em><u>checkbox</u></em>&nbsp;- for boolean types - html input of type checkbox</li><li><em><u>codeEditor</u></em>&nbsp;- code editor (based on ace editor) (form only)</li><li><em><u>color</u></em>&nbsp;- display color</li><li><em><u>colorpicker</u></em>&nbsp;- color<em><u>&nbsp;picker</u></em>&nbsp;, writes hash code (form only)</li><li><em><u>colorrow</u></em>&nbsp;- paints the text of the row in the table in the specified color (only table)</li><li><em><u>date</u></em>&nbsp;- select date</li><li><em><u>datetime</u></em>&nbsp;- select date and time</li><li><em><u>time</u></em>&nbsp;-<em><u>&nbsp;time</u></em>&nbsp;selection</li><li><br></li><li><em><u>files</u></em>&nbsp;- same as file, only for multiple downloads</li><li><em><u>filelist</u></em>&nbsp;- only for showing files downloaded using file or files</li><li><em><u>image</u></em>&nbsp;- download image type file</li><li><em><u>images</u></em>&nbsp;- same as images, only for bulk upload</li><li><em><u>gallery</u></em>&nbsp;- only for showing files uploaded with image or images</li><li>innerHtml - embeds html (it’s dangerous to use it without checking incoming data for embedded scripts)</li><li><em><u>link</u></em>&nbsp;- link, can display just a link, for example http://github.com, if you return it with text.&nbsp;Or you can return a json object like {title: 'mylink', link: 'mypath', target: '_ blank'}</li><li><em><u>multidate</u></em>&nbsp;- multiple date selection, save to array ["2018-01-01", "2018-01-02"] (form only)</li><li><em><u>select</u></em>&nbsp;- html component select - a drop-down list, used only if the relation field contains a table from foreign key fields, and the relationcolums indicate fields that will serve as values ​​for the list, if one field is selected, it will be written and displayed if selected two fields, for example ["id", "title"], then the id will be written as a value to the database, and the title will be displayed for selection, if 3 or more fields are selected, the first will be written, and all the rest will be concatenated for display.&nbsp;You can also apply a condition to list output by specifying it in select_condition.&nbsp;It is important that the select type returns only 300 records from the table; if there are more records, we recommend using the typehead type.</li><li><em><u>typehead</u></em>&nbsp;- the html component of select - with the search, works on the same principle as the type select, but requires a search string that the user enters, the search occurs throughout the table specified in relation, by the fields specified in relationcolums.</li><li><em><u>multiselect</u></em>&nbsp;- works according to the principle of type select, but does not require a foreign key, the table can be specified independently in the admin admin panel.&nbsp;Multiple choice.&nbsp;It saves an array of selected values ​​in the JSON database, for example [15,155,14], so the field in the table should be of type json.</li><li><em><u>multitypehead</u></em>&nbsp;- works on the principle of multiselect type, only with search</li><li><em><u>select_api</u></em>- works according to the principle of type select, but instead of the table link in relation, the path to the API method is specified (for example, / api / gettables), which returns data for the list.&nbsp;The API method must be POST, it must return an object with an outjson key which contains an array of objects of the form {label: "val1", value: "1"}, where value is written to the database, and label is displayed to the user.&nbsp;Those.&nbsp;the method response should look like this: {outjson: [{label: "val1", value: "1"}, {"label": "val2", value: "2"}, ...]}.&nbsp;The object {config: [...], data: {...}, inputs: {...}} will go into the body of the method, where config is the config view, data is all the current data on the form, inputs - these are the current address bar parameters, they can be used to manipulate data in your API method.&nbsp;Important,</li><li><em><u>typehead_api</u></em>&nbsp;- the same as type select, but optionally subtr leaves the parameter - search query</li><li><em><u>multiselect_api</u></em>&nbsp;- works according to the principles of multiselect and select_api, multiple selection, receives data from the API method, saves an array of selected data in the database table.&nbsp;It also takes the parameter val - in which the current value, return the list by val to initialize the form with the filled value.</li><li><em><u>multitypehead_api</u></em>&nbsp;- works according to the principles of multitypehead and typehead_api, multiple choice, receives data from the API method, sends the substr parameter to search, saves an array of selected data to the database table.&nbsp;It also takes the parameter val - in which the current value, return the list by val to initialize the form with the filled value.</li><li><em><u>rate</u></em>&nbsp;- stars for ratings, we recommend using with type numeric, because&nbsp;ratings can be 4.5, 2.5, etc.</li><li><em><u>tags</u></em>&nbsp;- tags, saves an array from the entered lines, adds to the array on onnter, store in the database in a json type field</li><li><em><u>array</u></em>&nbsp;is a table that has a one-to-many relationship with the main one, you can display it in the form of a table, but with the names of the fields, as indicated in the database.&nbsp;It is not recommended to use without urgent need.&nbsp;Configurable in relationcolums.</li></ul><p><br></p><h4><strong>Filters:</strong></h4><p>For view types - table and tiles, it is possible to add filters.</p><p>Filters have several basic properties.&nbsp;Title is the name to display the filter, col or columns are the fields by which data should be filtered, type is the type, position is the location, order is the order.</p><p>Filters are divided into two categories, the first is the position on the page -&nbsp;<strong><em><u>position</u></em></strong>&nbsp;, the second is the type of filter.</p><p>By location, two options are currently available:&nbsp;<em>Up</em>&nbsp;- on top of the form and&nbsp;<em>Right</em>&nbsp;- on the right, in the pop-up window.</p><p><br></p><p>By type:</p><ul><li><em><u>period</u></em>&nbsp;- specified for a field of type date, filters data by two specified dates of the period, mydatefield&gt; = filterdate1 and mydatefield &lt;= filterdate2</li><li><em><u>date_between</u></em>&nbsp;- specified for a field of type date, filters data according to the principle mydatefield&gt; = filterdate and mydatefield &lt;= filterdate</li><li><em><u>check</u></em>&nbsp;- used for a field with data type boolean, checkbox - with true / false / null values</li><li><em><u>substr</u></em>&nbsp;- search for a substring in a string.&nbsp;(lower (myfield) like lower (concat ('%', _ substr, '%')))</li><li><em><u>typehead</u></em>&nbsp;- search across several fields; you can also search by specifying the search values ​​by a space, in the case when 3 or more fields are specified.&nbsp;It is well suited for searching by first name last name, but may not work for a single field in which there are values ​​with problems.</li><li><em><u>select</u></em>&nbsp;- select the filter value from the drop-down list, for fields with foreign key, for the filter to work on the field, a table must be specified in relation and two fields must be specified in relationcolums - value and field for display, for example ["id", "title" ]</li><li><em><u>multiselect</u></em>&nbsp;- the same as select, only multiple selection, i.e.&nbsp;the filter will not be t1.myselectfield = val, but t1.myselectfield in (select value from json_array_elements (val))</li><li><em><u>multijson</u></em>&nbsp;- the intersection of two arrays, one field value, the second is the selected array in the filter</li></ul><p><br></p><h4><strong>Actions:</strong></h4><p><br></p><p><strong>The main functionality for controlling the view is action.&nbsp;Tables framework.actions.&nbsp;Basic properties:</strong></p><ul><li><em>title</em>&nbsp;- the name of the button or action</li><li><em>type</em>&nbsp;- type of action (see types of actions)</li><li><em>isforevery</em>&nbsp;- for each row, used for table and tiles</li><li><em>ismain</em>&nbsp;- triggered by double-clicking on a row, used for table and tiles</li><li><em>act</em>&nbsp;- way</li><li><em>classname</em>&nbsp;- CSS class</li><li><em>icon</em>&nbsp;- icon, antd icon v3. *</li><li><em>actapitype</em>&nbsp;- type of API method, in case the type is API, GET, POST, PUT, DELETE</li><li><em>actapirefresh</em>&nbsp;- refresh the form after performing an action of type API</li><li><em>parametrs</em>&nbsp;- parameters, read more description of parameters</li><li><em>act_visible_condition</em>&nbsp;- visibility conditions</li></ul><p><br></p><p><strong>Types of actions:</strong></p><ul><li><em>Link</em>&nbsp;- click on the link (without reloading the page)</li><li><em>LinkTo</em>&nbsp;- opens in a new page</li><li><em>API</em>&nbsp;- call the API of the method, if the method returns message - it will be shown as a notification, if _redirect - then redirect to the specified path</li><li><em>Delete</em>&nbsp;- delete the record, used only in the view of the table and tiles type, isforevery must be true, i.e.&nbsp;only works for a row in a table</li><li><em>Save</em>&nbsp;- save data in form not mutable</li><li><em>Save &amp; Redirect</em>&nbsp;- saving data in the form not mutable and redirecting to the path specified in the act</li><li><em>OnLoad</em>&nbsp;is an API method that is executed before the component is loaded, so you can, for example, download or update data before loading</li><li><em>Expand</em>&nbsp;- the drop-down component of the table row, used only in the view of the table type - in act the path to the getone or list component is specified, for example / list / myview or / getone / myview, parameters are also transferred to parametrs</li><li><em>Modal</em>&nbsp;- a modal window, opens the specified in the act view in the modal window, passing parameters, after closing the window updates the view, the path to the component should be getone or list, for example / list / myview or / getone / myview, parameters are also sent to parametrs</li></ul><p><br></p><p><strong>Description of parameters:</strong></p><p><strong>Parameters in actions have several basic properties and rules.&nbsp;title is the name of the parameter, then you should choose where to get the value for the parameter, it is possible to take val_desc from the component data, specify a constant - const, or take input from the address bar.&nbsp;If&nbsp;</strong><em>isforevery</em>&nbsp;false is used in the table or tiles, and val_desc is specified, then the value is taken from the first record of the table, but it may not appear, so be careful using a similar construction.&nbsp;For the onLoad action type, only the Input value can be used.</p><p><br></p><p>Service parameters:</p><p>_sub_title - If you pass the _sub_title parameter, then in view, in addition to the main title, there will be a subheading with the parameter value:</p><p>?id=1&amp;_sub_title=My SubTitle</p><p>relation - The relation parameter is described above.</p><p><br></p><p>Global Options:</p><p>_checked_ - if you pass the constant _checked_ in the parameter value - you can pass an array of identifiers selected in the table, for this, the main properties of the view must specify checker: true, only for type table</p><p>_userid_ - if you pass the constant _userid_ in the parameter value, you can pass the identifier of the current user, it can also be passed to config in defaulval, select_condition</p><p>_orgid_ - if you pass the constant _orgid_ in the parameter value, you can pass the identifier of the current organization, the current user, it can also be passed to config in defaulval, select_condition</p><p>_orgs_ - if you pass the constant _orgs_ in the parameter value, you can pass the identifiers of all organizations, the current user, in the JSON array, you can also pass them to config in defaulval, select_condition</p><p><br></p><h3><strong class="ql-size-large">Composition</strong></h3><p><br></p><p><strong>Compositions - this is a component in which you can combine several views into one, available on the path / composition / &lt;mycompopath&gt;.</strong></p><p><strong>Composition properties:&nbsp;<em>title</em></strong>&nbsp;- composition name - title,&nbsp;<strong><em>path</em></strong>&nbsp;- composition path along this path the component will be available,&nbsp;<strong><em>viscond_function</em></strong>&nbsp;- a function that returns a json array of view identifiers to be displayed, accepts all address line parameters - inputs and path of the composition, example functions&nbsp;<span style="color: rgb(196, 26, 22);">framework.fn_views_compo_visible</span>&nbsp;.&nbsp;And the view list to display is&nbsp;<strong><em>config</em></strong>&nbsp;.&nbsp;Config, in turn, contains view display properties,&nbsp;<strong><em>rownum</em></strong>&nbsp;- order,&nbsp;<strong><em>width</em></strong>&nbsp;- width from 1 to 24, by default always 24 - full screen.&nbsp;those.&nbsp;100%&nbsp;<strong><em>path</em></strong>- the object where id, path, viewtype is contained - view identifier, path and view type.&nbsp;The parameters passed are the same that should come in the view.&nbsp;those.&nbsp;if you combined the view table and getone of the same table and sent id = 0, then it will apply to both views.</p><p>Compositions update data if there is at least one updatable in view in config.</p><p>The database is stored in the table framework.compos.</p><p><br></p><h3><strong class="ql-size-large">Trees</strong></h3><p><br></p><p><strong>Tree - this is a tree-like menu where you can specify items and view or composition corresponding to the item, you can also specify parent records, for each item you need to specify a name and icon.&nbsp;Trees are available along the path / trees / &lt;mytreepath&gt;, where &lt;mytreepath&gt; is the path of the tree.&nbsp;It is also possible to specify the main item that will open when the tree is initialized.&nbsp;You can get to the desired item in the tree by entering # &lt;item ID&gt; in the address bar, for example: / trees / &lt;mytreepath&gt;? Oid = 12 # 15, where # 15 is the item ID.&nbsp;Parameters in tree, as well as in composition, are passed end-to-end in view.</strong></p><p><br></p><p><br></p><h3><strong class="ql-size-large">SPAPI</strong></h3><p>SpApi are API methods that are stored in the framework.spapi table and are executed on the principle of direct execution of the specified function, i.e.&nbsp;Each method has its own plpgsql.&nbsp;The function must have an input parameter injson of JSON type, to which the body and request parameters will be passed.&nbsp;The function can return any data type; the message and _redirect return service parameters are described in the API action type.&nbsp;API methods have the following properties:</p><ul><li>method name - the name of the method API, the method is available at / api / &lt;method name&gt;</li><li>function - plpgsql function</li><li>methotype - type of API method, get, post, put, delete</li><li>roles - roles of users for whom the method is available, if nothing is selected, the method will be available to everyone, not even authorized users</li></ul><p>The method is available at / api / &lt;mymethodname&gt;</p><p><br></p><h3><strong class="ql-size-large">Menu</strong></h3><p>The table - framework.menus - stores data about the menus that are added to the project and their location, i.e.&nbsp;Left Menu - left menu, Header Menu - top menu, etc. .. Table - framework.mainmenu - stores the list of menus.&nbsp;In order to add / edit the menu, go to the menu item&nbsp;<span style="background-color: rgb(0, 21, 41); color: rgb(255, 255, 255);">Project Settings-&gt; Auxiliary settings -&gt; Menu Settings</span>&nbsp;.</p><p>Properties:</p><ul><li>title - the name of the menu item</li><li>parent - parent record</li><li>roles - roles to which the menu item is available</li><li>order by - item order</li><li>path - path</li><li>icon - item icon</li><li>no session - show the menu item only if the user is not authorized</li><li>ws messagetype - indicate the type of notification from the framework.notification table, adds a counter</li><li>is title - show the name of the item</li></ul><p><br></p><h3><strong class="ql-size-large">Notifications</strong></h3><p>Notifications can be sent to the project by adding entries to the framework.notification table.&nbsp;Basic properties:</p><ul><li>message - message</li><li>messagetype - notification type, indicated in the menu, for the default 'notifs' counter</li><li>for_userid - identifier of the user for whom the notification</li><li>sended_sessions - sessions received notifications</li><li>isread - read</li><li>sessid - session for which notification, if for_userid is not specified</li></ul><h3><br></h3><h3><strong class="ql-size-large">User CSS</strong></h3><ul><li class="ql-indent-1">user.css is a file connected to the index.html of the project.&nbsp;You can write new CSS classes in this file by going to the menu item&nbsp;<span style="background-color: rgb(0, 21, 41); color: rgb(255, 255, 255);">Project Settings-&gt; Global Project Settings -&gt; User Css</span>&nbsp;.</li></ul>



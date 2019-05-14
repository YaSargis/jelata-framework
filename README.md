# Current Version
Jelata Framework v. 0.0.3

# Getting Started
Jelata Framework is a tool combining a framework and development environment that you can use in your browser. 
The Jelata Framework is designed to simplify the development task with ready-made components that already have a bundle with data in the database.  
To start using you will need:  
                        <ul>
							<li>python 3 (recommended to use python versions older than 3.4)</li>
							<li>PostgreSQL DBMS (PostgreSQL version 9.5 is recommended)</li>
						</ul>
						<p>For python, you must install the following libraries:</p>
                        <ul>
							<li>tornado v. 4.5.3</li>
							<li>momoko</li>
						</ul>
<pre>pip install -Iv tornado==4.5.3 
pip install momoko
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
More detail instructions you can get after starting the server followink link http://127.0.0.1:8080/jdocumentation	

You can write your own front-end for framework using <a href="https://github.com/YaSargis/jelata-framework-main-frontend">main frontent project</a>				

## Authors

* **Kazaryan Sargis**

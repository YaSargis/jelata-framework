from json import load
df = open('settings.json')
settingsFile = load(df)
df.close()
dsn = settingsFile.get('dsn')# database connection string
port = settingsFile.get('port')#2323
reports_url = settingsFile.get('reports_url')#2323
poolsize = 7
path = 'jelatafraework'

#U can use userorgs by default value in configurator like this <userorgs>
developerRole = settingsFile.get('developerRole') or 0 # role of developer in system
#auth_path = settingsFile.get('redirect401') 
maindomain = settingsFile.get('maindomain')  #main domain for static file path
primaryAuthorization = settingsFile.get('primaryAuthorization') or '1' #main domain for static file path
template = settingsFile.get('template') or 'ant'  
                                      
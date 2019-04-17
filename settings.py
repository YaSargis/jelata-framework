from json import load
df = open('settings.json')
settingsFile = load(df)
df.close()
dsn = settingsFile.get("dsn")# database connection string
port = settingsFile.get("port")#2323
poolsize = 30
path = 'jelatafraework'

#U can use userorgs by default value in configurator like this <userorgs>
developerRole = settingsFile.get("developerRole")  # role of developer in system
#auth_path = settingsFile.get("redirect401") 
maindomain = settingsFile.get("maindomain")  #main domain for static file path
primaryAuthorization = settingsFile.get("primaryAuthorization")  #main domain for static file path
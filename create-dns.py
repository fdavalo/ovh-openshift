# -*- encoding: utf-8 -*-
'''
First, install the latest release of Python wrapper: $ pip install ovh
'''
import json
import ovh
import sys
import os

# Instanciate an OVH Client.
# You can generate new credentials with full access to your account on
# the token creation page
client = ovh.Client(
    endpoint='ovh-eu',               # Endpoint of API OVH Europe (List of available endpoints)
    application_key=os.environ['OVH_APPLICATION_KEY'],    # Application Key
    application_secret=os.environ['OVH_APPLICATION_SECRET'], # Application Secret
    consumer_key=os.environ['OVH_CONSUMER_KEY'],       # Consumer Key
)

domain = sys.argv[1]
name = sys.argv[2]
ip = sys.argv[3]

result = client.post('/domain/zone/'+domain+'/record', 
    fieldType='A', # Resource record Name (type: zone.NamedResolutionFieldTypeEnum)
    subDomain=name, # Resource record subdomain (type: string)
    target=ip, # Resource record target (type: string)
    ttl=60, # Resource record ttl (type: long)
)

# Pretty print
print(json.dumps(result, indent=4))

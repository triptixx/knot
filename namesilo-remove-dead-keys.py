#!/usr/bin/python3

import os, sys, re
import requests
import subprocess
import xmltodict

endpoint = os.environ['ENDPOINT'] if 'ENDPOINT' in os.environ else sys.exit('no endpoint in environnement system')
apikey   = os.environ['APIKEY'] if 'APIKEY' in os.environ else sys.exit('no apikey in environnement system')
apiversion = 1
apitype    = 'xml'
apidict    = {'version': apiversion, 'type': apitype, 'key': apikey}

def urlget(operation, reqparams={}):
    try:
        params = dict(apidict, **reqparams)
        response = requests.get(
                f'{endpoint}{operation}',
                params=params
            )
        return response
    except:
        sys.exit(f'Unexpected error: {sys.exc_info()[0]}')

def xmltostr(strdata):
    if isinstance(strdata, dict):
        return strdata['#text']
    elif isinstance(strdata, str):
        return strdata
    elif isinstance(strdata, list):
        for item in strdata:
            xmltostr(item)

def subproc(cmd, checkcmd=True):
    resultcmd = subprocess.run(cmd, shell=True, check=checkcmd, capture_output=True, text=True).stdout.strip('\n')
    return resultcmd

print(f'Connecting to NameSilo API endpoint {endpoint}\n  Found API version: v{apiversion}')

lstdomains     = urlget('listDomains')
lstdomains     = xmltodict.parse(lstdomains.text, force_list={'domain'})
lstdomainlocal = subproc("/knot/sbin/knotc conf-read zone.domain | awk '{print $NF}'")

try:
    for domain in lstdomains['namesilo']['reply']['domains']['domain']:
        domain = xmltostr(domain)

        found_domain = 0
        for domainlocal in lstdomainlocal.split('\n'):
            domainlocal = re.sub(r'\.$', '', domainlocal)
            if domain == domainlocal:
                found_domain += 1
            
        if found_domain != 0:
            print(f'Domain {domain} located in NameSilo account')

            lstdskey = urlget('dnsSecListRecords', {'domain': domain})
            lstdskey = xmltodict.parse(lstdskey.text, force_list={'ds_record'})
            lstdskeylocal = subproc(f"/knot/sbin/keymgr {domain} ds | awk '$5 == \"4\"'")

            try:
                for dskey in lstdskey['namesilo']['reply']['ds_record']:
                    found_key = 0
                    if len(lstdskeylocal):
                        for dskeylocal in lstdskeylocal.split('\n'):
                            dskeylocal = dskeylocal.rstrip('\n').split()
                            if dskey['digest'].upper() == dskeylocal[5].upper() and dskey['key_tag'] == dskeylocal[2] and dskey['digest_type'] == dskeylocal[4] and dskey['algorithm'] == dskeylocal[3]:
                                found_key += 1

                    if found_key != 0:
                            print(f"  Found existing matching key {dskey['key_tag']}. No delete required.")
                    else:
                        print(f"  Key {dskey['key_tag']} not found, so key needs deleting...")
                        delkey = urlget('dnsSecDeleteRecord', {'domain': domain, 'digest': dskey['digest'], 'keyTag': dskey['key_tag'], 'digestType': dskey['digest_type'], 'alg': dskey['algorithm']})
                        print(f"    Key {dskey['key_tag']} deleted !!")
            except KeyError:
                pass
        else:
            print(f"Domain {domain} didn't find in local account")
except KeyError:
    print("Didn't find any domain in NameSilo account")

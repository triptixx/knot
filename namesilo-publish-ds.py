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

lstdomainlocal = subproc("/knot/sbin/knotc conf-read zone.domain | awk '{print $NF}'")
lstdomains     = urlget('listDomains')
lstdomains     = xmltodict.parse(lstdomains.text, force_list={'domain'})

for domainlocal in lstdomainlocal.split('\n'):
    domainlocal = re.sub(r'\.$', '', domainlocal)

    found_domain = 0
    try:
        for domain in lstdomains['namesilo']['reply']['domains']['domain']:
            domain = xmltostr(domain)
            if domainlocal == domain:
                found_domain += 1
    except KeyError:
        pass

    if found_domain != 0:
        print(f'Domain {domainlocal} located in NameSilo account')

        lstdskeylocal = subproc(f"/knot/sbin/keymgr {domainlocal} ds | awk '$5 == \"4\"'")
        if len(lstdskeylocal):
            for dskeylocal in lstdskeylocal.split('\n'):
                dskeylocal = dskeylocal.rstrip('\n').split()
                print('  Checking existing DNSSEC keys...')
                print(f'    Digest: {dskeylocal[5]}')
                print(f'    KeyTag: {dskeylocal[2]}')
                print(f'    DigestType: {dskeylocal[4]}')
                print(f'    Algorithm: {dskeylocal[3]}')

                lstdskey = urlget('dnsSecListRecords', {'domain': domainlocal})
                lstdskey = xmltodict.parse(lstdskey.text, force_list={'ds_record': True})

                found_key = 0
                try:
                    for dskey in lstdskey['namesilo']['reply']['ds_record']:
                        if dskey['digest'].upper() == dskeylocal[5].upper() and dskey['key_tag'] == dskeylocal[2] and dskey['digest_type'] == dskeylocal[4] and dskey['algorithm'] == dskeylocal[3]:
                            found_key += 1
                except KeyError:
                    pass

                if found_key != 0:
                    print('  Found existing matching key. No upload required.')
                else:
                    print('  Key not found, so key needs uploading...')
                    addkey = urlget('dnsSecAddRecord', {'domain': domainlocal, 'digest': dskeylocal[5], 'keyTag': dskeylocal[2], 'digestType': dskeylocal[4], 'alg': dskeylocal[3]})
                    subksk = subproc(f'/knot/sbin/knotc zone-ksk-submitted {domainlocal}', False)
                    print(f'  Knot Submit : {subksk}')
        else:
            print('  No DNSSEC keys for submission')
    else:
        print(f"Domain {domainlocal} didn't find in NameSilo account")

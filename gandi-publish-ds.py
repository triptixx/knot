#!/usr/bin/python3

import os, sys, re
import subprocess
import requests
import struct, base64

endpoint = os.environ['ENDPOINT'] if 'ENDPOINT' in os.environ else sys.exit('no endpoint in environnement system')
apikey   = os.environ['APIKEY'] if 'APIKEY' in os.environ else sys.exit('no apikey in environnement system')

def urlget(index, apikey):
    response = requests.get(
        f'{endpoint}{index}',
        headers={'authorization': f'Apikey {apikey}'}
    )
    return response

def calc_keyid(flags, protocol, algorithm, dnskey):
    st = struct.pack('!HBB', int(flags), int(protocol), int(algorithm))
    st += base64.b64decode(dnskey)

    cnt = 0
    for idx in range(len(st)):
        s = struct.unpack('B', st[idx:idx+1])[0]
        if (idx % 2) == 0:
            cnt += s << 8
        else:
            cnt += s

    return ((cnt & 0xFFFF) + (cnt >> 16)) & 0xFFFF

print(f'Connecting to Gandi API endpoint {endpoint}')
try:
    arrdomains = urlget('domain/domains', apikey)
    arrdomains.raise_for_status()
    print('  Found API version: v5')
except requests.exceptions.HTTPError as e:
    sys.exit(e)

arrdomain = subprocess.run("/knot/sbin/knotc conf-read zone.domain | awk '{print $NF}'", shell=True, check=True, capture_output=True, text=True).stdout.strip('\n')

for domains in arrdomains.json():
    for domain in arrdomain.split('\n'):
        domain = re.sub(r'\.$', '', domain)

        if domains['fqdn'] == domain:
            print(f'Domain {domain} located in Gandi account\nChecking existing DNSSEC keys...')

            arrzone = subprocess.run(f"/knot/sbin/knotc zone-read {domain} @ CDNSKEY | cut -d' ' -f2-", shell=True, check=True, capture_output=True, text=True).stdout.strip('\n')

            for zone in arrzone.split('\n'):
                cdnkey = zone.rstrip('\n').split()
                print(f'  Domain: {domain}')
                print(f'  Flag: {cdnkey[3]}')
                print(f'  Alg: {cdnkey[5]}')
                print(f'  Key: {cdnkey[6]}')

                keytag = calc_keyid(cdnkey[3], cdnkey[4], cdnkey[5], cdnkey[6])
                print(f'  Key: {keytag}')

        else:
            print(f"Didn't find {domain} in account. Exiting.")

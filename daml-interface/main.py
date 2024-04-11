import asyncio
import dazl
import json
import pprint

from dazl.ledger import Boundary
from dazl.ledgerutil import ACS

def alice_party_id():
    with open('target/parties.json') as f:
        return json.load(f)['alice']

def package_id(filename):
    with open(f'target/{filename}') as f:
        return json.load(f)

PACKAGE_ID_V1=package_id('package-id-v1.json')
PACKAGE_ID_V2=package_id('package-id-v2.json')
PACKAGE_ID_SCRIPTS=package_id('package-id-scripts.json')
PACKAGE_ID_IFACE=package_id('package-id-iface.json')

print('PACKAGE_ID_V1=', PACKAGE_ID_V1)
print('PACKAGE_ID_V2=', PACKAGE_ID_V2)
print('PACKAGE_ID_SCRIPTS=', PACKAGE_ID_SCRIPTS)
print('PACKAGE_ID_IFACE=', PACKAGE_ID_IFACE)



# tid='*'
tid=f'{PACKAGE_ID_V1}:Main:Point'
# tid=f'{PACKAGE_ID_IFACE}:ApplicationAPI:ICartesianCoordinate'

async def show_acs(conn):
    async with ACS(conn, {tid: {}}) as acs:
        snapshot = await acs.read()

        print(snapshot)

async def show_create_events(conn):
    async with conn.stream_many(tid) as stream:
        async for event in stream.items():
            if isinstance(event, Boundary):
                break

            print(pprint.pformat({
                '_cid': event.contract_id.value,
                '_tid': event.contract_id.value_type,
                'payload': event.payload
            }))
            print()

async def main():
    async with dazl.connect(url='http://localhost:6865', read_as=alice_party_id()) as conn:
        await show_create_events(conn)

asyncio.run(main())

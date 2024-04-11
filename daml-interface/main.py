import asyncio
import dazl
import json
import pprint

from dazl.ledger import Boundary
from dazl.ledgerutil import ACS

def alice_party_id():
    with open('target/parties.json') as f:
        return json.load(f)['alice']


# tid='*'
tid='bfbb3a82936cb29e7d9de8712dddbbb01653eec4e89e1ec69f17f23c6ba92e8f:Main:Point'
# tid="a34d833806e62f585cfe1f110a93392bce88437898e8b91bf2c3f3ea69a36e57:ApplicationAPI:ICartesianCoordinate"
# tid="ApplicationAPI:ICartesianCoordinate"

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

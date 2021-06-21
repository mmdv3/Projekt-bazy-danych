import psycopg2
import json

#python cursor init
conn = psycopg2.connect("dbname=student user=app password=qwerty")
cur = conn.cursor();

a = input()
#with self.connection as cursor:
#   cursor.execute(open("init.sql","r").read())
if (a == "--init"):
    cur.execute(open("init.sql","r").read())
    conn.commit()
    print("{Status:OK}")
else:
    a_json = json.loads(a)
    if a_json["function"] == "flight":
        #print(a_json["params"]["airports"])
        airport_num = len(a_json["params"]["airports"]) 
        if airport_num == 2:

        #print(airport_num)
        
    #print("not an init")



#print(type(a_json))
#
#args = parser.parse_args()

#dump = json.dumps(args.query)
#query = json.loads(dump)
#
#print(type(dump))
#print(dump)
#print(type(query))
#
#kupa = '{"kupa" : 1}'
#kupa_json = json.loads(kupa)
#print(type(kupa_json))
#print(kupa_json["kupa"])

#python cursor close
cur.close()
conn.close()

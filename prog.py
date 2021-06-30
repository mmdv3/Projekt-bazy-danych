import psycopg2
import json

def commit_changes_exit_script(connection, cursor):
    connection.commit()

    output = {"status": cur.fetchone()[0] }
    print(json.dumps(output))

    cursor.close()
    connection.close()

    exit()

def commit_changes_print_results(connection, cursor, data):
    connection.commit()

    output = {"status": "OK", "data": data}
    print(json.dumps(output))

#python cursor init
conn = psycopg2.connect("dbname=student user=app password=qwerty")
cur = conn.cursor();

a = input()

if (a == "--init"):
    cur.execute(open("init.sql","r").read())
    commit_changes_exit_script(conn, cur)
    
with open(a, "r") as file:
    for line in file:
        a_json = json.loads(line)
        a_params = a_json["params"]
        data = []

        if a_json["function"] == "flight":
            a_airports = a_params["airports"]
            airport_num = len(a_json["params"]["airports"]) 
        
            if airport_num == 3:
                cur.execute("""select flight 
                (%s::integer,%s,%s,%s::timestamptz,%s::timestamptz, 
                %s, %s::timestamptz, %s::timestamptz)""",
                (a_params["id"],a_airports[0]["airport"],
                    a_airports[1]["airport"], a_airports[0]["takeoff_time"],
                    a_airports[1]["landing_time"], a_airports[2]["airport"],
                    a_airports[1]["takeoff_time"], a_airports[2]["landing_time"]))
            if airport_num == 2:
                cur.execute("""select flight
                        (%s::integer,%s,%s,%s::timestamptz,%s::timestamptz)""",
                        (a_params["id"],a_airports[0]["airport"],
                            a_airports[1]["airport"], a_airports[0]["takeoff_time"],
                            a_airports[1]["landing_time"]))
       
        if a_json["function"] == "list_flights":
            cur.execute("select list_flight(%s::integer)", a_params["id"])
            results = cur.fetchall()

            for result in results:
                result = result[0][1:-1].split(',')
                #result = result[0].split(',')
                temp_dict = {"rid": result[0], "from": result[1], "to": result[2], "takeoff_time": result[3][1:-1]}
                #print(temp_dict)
                data.append(temp_dict)

        if a_json["function"] == "list_cities":
            cur.execute("select list_cities(%s::integer, %s::integer)", (a_params["id"], a_params["dist"]))
            results = cur.fetchall()

            for result in results:
                result = result[0][1:-1].split(',')
                temp_dict = { "name": result[0], "prov": result[1], "country": result[2] }
                data.append(temp_dict)

        if a_json["function"] == "list_airport":
            cur.execute("select list_airport(%s, %s::integer)", (a_params["iatacode"], a_params["n"]))
            results = cur.fetchall()

            for result in results:
                temp_dict = { "id": str(result[0]) }
                data.append(temp_dict)

        if a_json["function"] == "list_city":
            cur.execute("select list_city(%s, %s, %s, %s::integer, %s::integer)", 
                    (a_params["name"], a_params["prov"], a_params["country"], a_params["n"], a_params["dist"]))
            results = cur.fetchall()

            for result in results:
                result = result[0][1:-1].split(',')
                temp_dict = { "rid": result[0], "mdist": result[1] }
                data.append(temp_dict)
            
        commit_changes_print_results(conn, cur, data)
        
cur.close()
conn.close()

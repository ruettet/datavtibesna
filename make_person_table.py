import sqlite3
from codecs import open

con = sqlite3.connect(":memory:")
cur = con.cursor()
cur.execute("create table people(id, last_name, first_name, language_id, publicid, created_at, updated_at, gender_id, permalink, birthdate_id, death_date_id, country_id, city, name, key_name, alias_of_id, cached_slug, status, url, document)")

print("working on the people")
with open("/media/sf_datasets/data-vti-be/people.sql") as f:
  cur.executescript(f.read())

cur.execute("select distinct id, name from people")
person_ids = cur.fetchall()

rows = [str(person_id[0]) + "\t" + person_id[1] + "\n" for person_id in person_ids]
with open("person.table", "w", "utf-8") as f:
  f.writelines(rows)

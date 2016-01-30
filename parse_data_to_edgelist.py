import sqlite3
from collections import Counter
from codecs import open

con = sqlite3.connect(":memory:")
cur = con.cursor()

cur.execute("create table people(id, last_name, first_name, language_id, publicid, created_at, updated_at, gender_id, permalink, birthdate_id, death_date_id, country_id, city, name, key_name, alias_of_id, cached_slug, status, url, document)")

cur.execute("create table productions(id, title, inspiration, target_audience_text_nl, target_audience_from, target_audience_to, rerun_of_id, verified, created_at, updated_at, season_id, permalink, target_audience_text_fr, target_audience_text_en, description_nl, description_fr, description_en, external_id, number_by_country, library_location, cached_slug, status, document)")

cur.execute("create table seasons(id, start_year, end_year, name, created_at, updated_at, permalink, cached_slug, status)")

cur.execute("create table relationships(id, audio_video_title_id, organisation_id, person_id, production_id, archive_part_id, function_text, type, created_at, updated_at, article_id, function_id, book_title_id, 'index', ephemerum_id, ico_title_id, genre_id, role_info, reference_type, venue_id, language_id, order_id, language_note, delivery_date, press_cutting_id, warehouse_id, donation_id, periodical_id, organisation_from_id, organisation_to_id, organisation_relation_type_id, creation_date_id, cancellation_date_id, start_activities_date_id, end_activities_date_id, language_role_id, profession_id, speciality_id, status, vip)")

print("working on the people")
with open("/media/sf_datasets/data-vti-be/people.sql") as f:
  cur.executescript(f.read())

print("working on the productions")
with open("/media/sf_datasets/data-vti-be/productions.sql") as f:
  cur.executescript(f.read())

print("working on the seasons")
with open("/media/sf_datasets/data-vti-be/seasons.sql") as f:
  cur.executescript(f.read())

print("working on the relationships")
with open("/media/sf_datasets/data-vti-be/relationships.sql") as f:
  cur.executescript(f.read())

all_nodes = {}
all_edges = []
cur.execute("select id from productions where season_id in (1670, 1671, 1672, 1673, 1674, 1675, 1676, 1705, 1706, 1708, 1709, 1710, 1711) and rerun_of_id IS NULL")
productions =  cur.fetchall()
i = 1
for production_id in productions:
  if i%1000 == 0:
    print i, "of", len(productions)
  i += 1
  nodes = []
  cur.execute("select person_id from relationships where production_id == " + str(production_id[0]) + " and function_id in (11571, 11933, 11971, 11977, 12009, 12018, 12019, 12092, 12156)")
  person_ids_in_production = cur.fetchall()
  for person_id in person_ids_in_production:
    if person_id[0] != None:
#      cur.execute("select first_name, last_name from people where id == " + str(person_id[0]))
#      name = cur.fetchone()
#      full_name = " ".join([unicode(name[0]), unicode(name[1])])
      if person_id[0] not in nodes:
        nodes.append(str(person_id[0]))
  edges = []
  for a in nodes:
    for b in nodes:
      if a != b and "\t".join(sorted([b, a])) not in edges:
        edges.append("\t".join(sorted([a, b])))
  all_edges.extend(edges)

with open("edgelist.el", "w", "utf-8") as f:
  f.write("\n".join(all_edges))


#This script will pull data from the PokeAPI and insert it into a table in BigQuery

#Import libraries
import requests
from google.cloud import bigquery
import os

#BigQuery credentials and key
credentials_path = "Keypath"
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path

#Function to get existing Pokémon IDs from the BigQuery table
def get_existing_pokemon_ids(dataset_id, table_id):
    client = bigquery.Client()
    query = f"""
        SELECT id FROM `{client.project}.{dataset_id}.{table_id}`
    """
    query_job = client.query(query)
    existing_ids = {row["id"] for row in query_job}
    return existing_ids

#Function to fetch Pokémon data from the PokeAPI

def fetch_pokemon_data(limit=900, existing_ids=set()):
    url = f"https://pokeapi.co/api/v2/pokemon?limit={limit}"
    response = requests.get(url)
    response.raise_for_status()
    data = response.json()
    
    # Create a list to store the data for each Pokémon
    pokemon_list = []
    for pokemon in data["results"]:
        details_response = requests.get(pokemon["url"])
        details_response.raise_for_status()
        details = details_response.json()
        
        if details["id"] in existing_ids:
            continue
        
        abilities = [ability["ability"]["name"] for ability in details["abilities"]]
        types = [ptype["type"]["name"] for ptype in details["types"]]
        
        stats = {stat["stat"]["name"]: stat["base_stat"] for stat in details["stats"]}
        moves = [move["move"]["name"] for move in details["moves"]]
        
        species_response = requests.get(details["species"]["url"])
        species_response.raise_for_status()
        species_data = species_response.json()
        
        capture_rate = species_data["capture_rate"]
        evolution_chain_url = species_data["evolution_chain"]["url"]
        
        pokemon_list.append({
            "id": details["id"],
            "name": details["name"],
            "height": details["height"],
            "weight": details["weight"],
            "base_experience": details["base_experience"],
            "abilities": ", ".join(abilities),
            "types": ", ".join(types),
            "hp": stats.get("hp", 0),
            "attack": stats.get("attack", 0),
            "defense": stats.get("defense", 0),
            "special_attack": stats.get("special-attack", 0),
            "special_defense": stats.get("special-defense", 0),
            "speed": stats.get("speed", 0),
            "moves": ", ".join(moves),
            "capture_rate": capture_rate,
            "evolution_chain_url": evolution_chain_url
        })
    
    return pokemon_list

#Function to load Pokémon data into BigQuery
def load_data_to_bigquery(dataset_id, table_id, pokemon_data):
    client = bigquery.Client()
    table_ref = client.dataset(dataset_id).table(table_id)
    table = client.get_table(table_ref)
    
    errors = client.insert_rows_json(table, pokemon_data)
    if errors:
        print("Errors occurred:", errors)
    else:
        print("Data loaded successfully!")

#Main function to run the script
def main():
    project_id = "projectname"
    dataset_id = "projectdataset"
    table_id = "pokemontable"
    
    existing_ids = get_existing_pokemon_ids(dataset_id, table_id)
    pokemon_data = fetch_pokemon_data(limit=900, existing_ids=existing_ids)
    
    if pokemon_data:
        load_data_to_bigquery(dataset_id, table_id, pokemon_data)
    else:
        print("No new Pokémon to load.")

#Run the main function
if __name__ == "__main__":
    main()

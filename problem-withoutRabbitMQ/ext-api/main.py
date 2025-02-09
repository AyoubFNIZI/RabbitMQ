from fastapi import FastAPI
import random
from typing import List

app = FastAPI()

def generate_fake_data(count: int = 100000):
    first_names = ["John", "Jane", "Mike", "Sarah", "David", "Lisa"]
    last_names = ["Smith", "Johnson", "Brown", "Davis", "Wilson", "Moore"]
    
    data = []
    for _ in range(count):
        record = {
            "firstname": random.choice(first_names),
            "lastname": random.choice(last_names),
            "age": random.randint(18, 80)
        }
        data.append(record)
    return data

@app.get("/data")
def get_data():
    return generate_fake_data()
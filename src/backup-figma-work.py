#!/usr/bin/env python3

import requests
import json
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

# Retrieve the access token from the environment variable
ACCESS_TOKEN = os.getenv('BackupES2FigmaWork')

# Check if the access token was retrieved successfully
if not ACCESS_TOKEN:
    print("Error: Figma access token not found. Please ensure it is set in the .env file.")
    exit(1)

# Use your actual Figma File Key
FILE_KEY = 'yjrGmErueQtZgLdPq18Qvo'

# Set headers for the API request
headers = {
    'X-Figma-Token': ACCESS_TOKEN
}

# Define the API endpoint
url = f'https://api.figma.com/v1/files/{FILE_KEY}'

# Make the API request
response = requests.get(url, headers=headers)

if response.status_code == 200:
    # Parse the JSON response
    data = response.json()

    # Create a timestamped filename
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'figma_backup_{FILE_KEY}_{timestamp}.json'

    # Define the backup directory
    backup_dir = './figma_backups'
    os.makedirs(backup_dir, exist_ok=True)

    # Save the data to a JSON file
    file_path = os.path.join(backup_dir, filename)
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=4)

    print(f'Successfully backed up to {file_path}')
else:
    print(f'Failed to fetch file data. Status code: {response.status_code}')
    print(f'Error message: {response.text}')

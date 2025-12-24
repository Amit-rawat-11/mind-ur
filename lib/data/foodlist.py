import re

# Read the Dart file
with open('/home/amit/Desktop/Projects/Mindure/lib/data/sample_food.dart', 'r', encoding='utf-8') as f:
    data = f.read()

# Find all occurrences of "name": "..."
names = re.findall(r'"name":\s*"([^"]+)"', data)

# Write ALL names (including duplicates) to a text file
with open('all_food_names.txt', 'w', encoding='utf-8') as out:
    for name in names:
        out.write(name + '\n')

print(f'Total food names (including duplicates): {len(names)}')
#########################################################################33
import re

# Read the Dart file
with open('/home/amit/Desktop/Projects/Mindure/lib/data/sample_food.dart', 'r', encoding='utf-8') as f:
    data = f.read()

# Find all occurrences of "name": "..."
names = re.findall(r'"name":\s*"([^"]+)"', data)

# Remove duplicates, keep only the first occurrence
seen = set()
filtered_names = []
for name in names:
    if name not in seen:
        filtered_names.append(name)
        seen.add(name)

# Write the filtered names to a text file
with open('food_names_no_duplicates.txt', 'w', encoding='utf-8') as out:
    for name in filtered_names:
        out.write(name + '\n')

print(f"Original total: {len(names)}")
print(f"After removing duplicates: {len(filtered_names)}")





################################################################3

import re
from collections import Counter

# Read the Dart file
with open('/home/amit/Desktop/Projects/Mindure/lib/data/sample_food.dart', 'r', encoding='utf-8') as f:
    data = f.read()

# Find all occurrences of "name": "..."
names = re.findall(r'"name":\s*"([^"]+)"', data)

# Count occurrences of each name
name_counts = Counter(names)

# Print all names that appear more than once
print("Duplicate food names (with number of occurrences):")
for name, count in name_counts.items():
    if count > 1:
        print(f"{name} ({count} times)")

# If you want just the names (not counts), use:
# duplicates = [name for name, count in name_counts.items() if count > 1]
# print(duplicates)

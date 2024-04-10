import os


def find_duplicates(directory):
    subdirectories = {}
    duplicates = []

    for root, dirs, files in os.walk(directory):
        for dir in dirs:
            print(dir)
            path = os.path.join(root, dir)
            if dir in subdirectories:
                duplicates.append(path)
            else:
                subdirectories[dir] = path

    return duplicates

# Replace 'directory_path' with the path to your main directory
directory_path = '/path/to/main/directory'
duplicates = find_duplicates(directory_path)

if duplicates:
    print("Duplicates found")
    # write duplicates to a txt file
    with open('duplicates.txt', 'w') as f:
        for duplicate in duplicates:
            f.write(duplicate + '\n')
            
else:
    print("No duplicates found.")
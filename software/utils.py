# Creates the bitmap file, appends 1 for decoy gates, 0 for original gates
def create_and_append(filename, line_number, value, total_number_lines): 
    try:
        # Open the file in read mode to check if it exists
        with open(filename, 'r') as file:
            lines = file.readlines()

        # Check if the specified line exists
        if line_number <= len(lines):
            # Open the file in write mode to update the specified line
            with open(filename, 'w') as file:
                # Update the specified line by concatenating the new value
                lines[line_number - 1] = lines[line_number - 1].strip() + str(value) + '\n'

                # Write the modified lines back to the file
                file.writelines(lines)

            print(f"Successfully appended value {value} to line {line_number} in {filename}")
        else:
            print(f"Error: Line {line_number} does not exist in {filename}")

    except FileNotFoundError:
        # If the file doesn't exist, create it and append the value to the specified line
        with open(filename, 'w') as file:
            lines = ['\n'] * total_number_lines  # Create empty lines
            lines[line_number - 1] = str(value) + '\n'  # Append the new value to the specified line
            file.writelines(lines)

        print(f"Successfully created {filename} and appended value {value} to line {line_number}")

# Processes the bitmap file in roder to feed this bitmap into python uart by converting it to the format that our hardware code understands
def process_file(input_filename, output_filename):
    with open(input_filename, 'r') as input_file:
        lines = input_file.readlines()

    num_lines = len(lines)
    remainder = 128 % num_lines
    padding_length = 128 - remainder

    processed_data = ''
    current_position = 0

    # Process each position (i-th position)
    for i in range(128):
        # Collect digits from each line
        for line_index, line in enumerate(lines):
            line = line.strip()
            # If the line has enough digits, add the i-th digit to the processed data
            if i < len(line):
                processed_data += line[i]
                current_position += 1
            # If the line doesn't have enough digits, pad with '0'
            else:
                processed_data += '0'
                current_position += 1

        # If the current position reaches 128 and there are remaining lines,
        # fill the remaining characters with '1's
        if current_position == padding_length and remainder > 0:
            processed_data += '1' * remainder
            current_position += remainder

        # If the current position reaches 128, start a new line
        if current_position == 128:
            processed_data += '\n'
            current_position = 0

    # Write the processed data to the output file
    with open(output_filename, 'w') as output_file:
        output_file.write(processed_data)


# Example usage:
# input_file = 'example.txt'
# output_file = 'output.txt'

# process_file(input_file, output_file)
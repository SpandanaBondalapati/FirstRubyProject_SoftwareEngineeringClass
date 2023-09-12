=begin
Spandana Bondalapati
CSC415-01 Software Engineering
Dr. Pulimood
Assignment 1
=end

require 'csv'

# Initialize hash maps to store the values
event_information = {}
student_information = {}

# Create a new hash map to store the potential activities

# Read the 'Event Information' CSV file and store the values in the hash map
CSV.foreach('input_event.csv', headers: true) do |row|

  event_information[row['Event-ID']] = {

    'Event-Name' => row['Event-Name'],
    'Event-Issues' => row['Event-Issues'].split('; '),
    'Min-Students' => row['Min-Students'],
    'Max-Students' => row['Max-Students']

  }

end

# Read the 'Student Information' CSV file and store the values in the hash map
CSV.foreach('input_student.csv', headers: true) do |row|

  student_information[row['Student-ID']] = {

    'Interests' => row['Interests'].split('; ')

  }

end

# Map student-interest to event-issues to find potential activities

# Declare interests array globally to use in event_information block
student_interests = []

student_information.each do |student_id, student_info| # block params

  # check if we are iterating correctly
  # puts "#{key}: #{value}"

  # store interests as an array of strings
  # must be able to hold up to 3 interests
  student_interests = student_info['Interests']
  #for_potential_events[student_id] = []
  
  # puts student_interests

  # iterate through each interest
  # student_interests.each do |interests|...end
end 

event_information.each do |event_id, event_info|

  event_issues = event_info['Event-Issues']
  puts event_issues
  
end


# Print the hash maps to check the values are stored properly
# puts "Event Information:"
# puts event_information

# puts "Student Information:"
# puts student_information

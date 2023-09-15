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

# hash with the potential projects depending on interests
potential_projects = {}

# hash with the invalid interests
invalid_student_interests = {}

# Declare interests array globally to use in event_information block
student_interests = []
event_issues = []

# Read the 'Event Information' CSV file and store the values in the hash map
CSV.foreach('event.csv', headers: true) do |row|

  event_information[row['Event-ID']] = {

    'Event-Name' => row['Event-Name'],
    'Event-Issues' => row['Event-Issues'].split('; '),
    'Min-Students' => row['Min-Students'],
    'Max-Students' => row['Max-Students']

  }

end

# Read the 'Student Information' CSV file and store the values in the hash map
CSV.foreach('student.csv', headers: true) do |row|

  student_information[row['Student-ID']] = {
    'Interests' => row['Interests'].split('; ')
  }

end

student_information.each do |student_id, student_info| # block params
  # check if we are iterating correctly
   # puts student_information.keys
   # "#{key}: #{value}"

  # store interests as an array of strings; must be able to hold up to 3 interests
  student_interests = student_info['Interests']
  potential_projects[student_id] = []

  # **TO-DO** Store invalid student interests into a seperate hash to handle after all valid interests have been processed

  event_information.each do |event_id, event_info|

    event_issues = event_info['Event-Issues']
    #event_issues.each do |issue|
      #puts "#{event_id}: #{issue}"
    #end
    if (student_interests & event_issues).any?
      # If there's a match, add the event to the student's list of potential events
      # Append event ID to array at student ID key in hash
      potential_projects[student_id] << event_id 
    end

  end

end # end of student_information hash iteration loop


# Scheduling algorithm to assign students to volunteering activities
assigned_activity = {}

# Globally define the priority queue of potential events, where the event with the lowest number
# => of students is at the top and the event with the highest number of students is at the bottom
# A sorted version of the potential projects hash map
pritority_proj_queue = {} # key-value is event ID => number of volunteers
event_information.each do |event_id, _| 
  # SOME CODE HERE
end

# pritority_proj_queue.min_by {}

potential_projects.each do |student_id, projects|

  # figure out how to do a conditional sort of the potential projects hash map 
  # key-value is student-ID => event-ID
  # Condition 1: Preferably an activity that has the least amount of students
  # Condition 2: Student is matched with an activity that meets most of their interests
  # => It must meet at least one of their interests, so look for an activity that meets
  # => all 3 and if there are none then search for one that matches at least 2
  # => and then search for one that matches at least 1
  # Assume that if a student lists even one invalid issue, they're automatically going to be processed at the lowest priority level


  assigned_activity = projects.min_by {}







end





# Print to see potential events
potential_projects.each do |student_id, potential_projects|
  puts "Student #{student_id} potential events: #{potential_projects.join(', ')}"
end




# Print the hash maps to check the values are stored properly
# puts "Event Information:"
# puts event_information

# puts "Student Information:"
# puts student_information







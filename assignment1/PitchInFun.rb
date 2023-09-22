
# Spandana Bondalapati CSC415-01
# PitchInFun - (Ruby Assignment 1)
# Relevant 'input' files: PitchInFun.rb, events2.csv, interests2.csv
# Produced 'output' files: output_file1 (CSV), output_file3 (.txt file with summary)

# Capabilities Comment: This program's purpose is to schedule students into volunteering events
# with the intent of maximimizing efficency, such as having the most amount of events running as possible.
# The program's algorithm's main functionalities include prirotiizing students based on who provided
# only valid social issues, which events have the least amount of students, and which events that would be
# most relavent to a student's interest. The algorithm makes sure to give students who listed any valid
# issues the lowest priority and randomlly assigns them to acitives that have the least amount of students.

# Last Modified: September 21st, 2023

require 'csv'

# Initalize Hash Maps
event_information = {}
student_information = {}
potential_projects = {}
assigned_activity = {}
priority_proj_queue = {} # key-value is event ID => number of volunteers

# Initalize Arrays
students_with_invalid_interests = []
student_interests = []
event_issues = []
canceled_events = []
valid_interests = ["food insecurity", "poverty", "racial inequality", "climate change", "homelessness", "healthcare", "gender inequality"]

# Read the events CSV file and store the values in the hash map called 'Event-Information'
# The key is the volunteering event ID and the values are the event attributes such as name, event issues, minimumum + maximum students
CSV.foreach('events2.csv', headers: true) do |row|

  # note: The .to_i ruby method coverts the string to an integer
  event_information[row['Event-Id']] = {
    'Event-Name' => row['Event-Name'],
    'Event-Issues' => row['Event-Issues'].split('; '),
    'Min-Students' => row['Min-Students'].to_i,
    'Max-Students' => row['Max-Students'].to_i
  }

end

# Read the CSV file and store the values in the hash map called 'Student-Information'
# The key is the student-ID and the value is the social issues the student is interested in volunteering for.
# The program will later check if the students interests are valid (from the valid_interests array)
CSV.foreach('interests2.csv', headers: true) do |row|

  student_information[row['Student-Id']] = {
    'Interests' => row['Interests'].split('; ')
  }

end

# In this segment of code, I find projects that students (who put down only valid interests) could potentially be placed into.
# I determine if a project is a 'potential project' if the event has *any* social issues that the valid student had listed.
# Here, we are iterating through the student_information hash in order to identify which are potential projects for each student
student_information.each do |student_id, student_info| # block params

  # For debugging purposes: check if the program is iterating through the hash correctly
  # "#{key}: #{value}"  

  # Store interests as an array of strings. Student must list 2 to 4 interests.  
  student_interests = student_info['Interests']

  # Define a hash map to store potential projects for each student (Student-ID=> The IDs of potential projects)
  potential_projects[student_id] = []

  # Students who have listed one or more invalid interests (one that is not in the valid students array) is deemed an "invalid student"
  # Invalid students are placed into the 'students_with_invalid_interests' hash-map and are handled after all the students who listed purely
  # valid issues are processed. This way students who try to "cheat the system" are given lower prirorty than the students who followed the rules
  if (student_interests - valid_interests).any?
    students_with_invalid_interests << student_id

    # Filter the invalid interests out of the student_interests array to only contain valid interests.
    # Then, we can use the student_interests hash which has only valid social issues to find potential projects
    student_interests = student_interests & valid_interests

  end  

  # Iterate through the event_information hash map to populate the event_issues array
  event_information.each do |event_id, event_info|

    event_issues = event_info['Event-Issues']

    # Debugging Purposes - printing out events_information hashmap
    #event_issues.each do |issue|
      #puts "#{event_id}: #{issue}"
    #end

    # This if-statement checks if there is any overlap between student-interests and event-issues. If there is overlap, then the event
    # is considered a potential event for that specific student and is appended. 
    # potential_projects hash map ------> Student-ID => Potential Event ID
    if (student_interests & event_issues).any?
      potential_projects[student_id] << event_id 
    end

  end

end # end of student_information hash iteration loop (comment for my own organization)


# Now that we have all of our valid student's mapped to their potential projects, we can create a scheduling algorithm to
# figure out the best potential project to put them into based on various factors such a number of overlapping interests as
# well as if there is space available in the volunteering event.

# Define and intialize the priority queue of potential events, where the event with the lowest number of students is at the 
# top and the event with the highest number of students is at the bottom. 
# Right now, the number of volunteers for each event ID is 0 as no students/volunteers have been assigned to projects yet. 
event_information.each do |event_id, _| 

  priority_proj_queue[event_id] = 0

end

# puts priority_proj_queue ---> DEBUGGING PURPOSES (can ignore)

# In the below potential_projects block, I am iterating through the potential projects hashmap to find out how many
# social issues listed by a student overlaps with the event-issues of each of their potential events they may want to do. 
# I am doing this because I want to (preferably) assign students to an event they are most interested in doing.

potential_projects.each do |student_id, projects|

  # The project_scores hash map will have the project-ID mapped to the number of similar interests a student has with it
  project_scores = {}
  
  projects.each do |project_id|

    # Here I am once again populating the event_issues and student_interests from the event_information and student_information hashes
    event_issues = event_information[project_id]['Event-Issues']
    student_interests = student_information[student_id]['Interests']
  
    # Then, I find the NUMBER of similar interests a student has for a particular project/event (project-id)
    num_similar = (student_interests & event_issues).size
    project_scores[project_id] = num_similar

  end

  # sorted scores has the priority score of each project
  sorted_scores = project_scores.sort_by do |project_id, score| # 'score' is essentially num_similar

    [-score, priority_proj_queue[project_id]] 
    # priority_proj_queue[project_id] is essentially making sure if two project have the same
    # amount of similar interests, then the project with the least amount of assigned students comes first.
    # We do this prioritize volunteering projects with the least amount of volunteers to minimize cancelations

  end

  # puts sorted_scores ---> for debugging purposes

  # We must make sure we don't go over the maximum number of students
  best_project = sorted_scores.find do |project_id, _|
    event_info = event_information[project_id]
    priority_proj_queue[project_id] < event_info['Max-Students']
  end

  if best_project

    # Get the project ID with the .first method
    best_project_id = best_project.first
    # I hashed the best project's ID to the student ID in the assigned_activity hash-map
    assigned_activity[student_id] = best_project_id

    # Increase the volunteer count for the chosen project the student is assinged to.
    # priority_proj_queue[best_project_id] accesses the value associated with the best_project_id
    # best_project_id is acting as a key to look up the associated value (current volunteer count)
    priority_proj_queue[best_project_id] += 1
  end

end

# Since all the "valid students" (students who only listed valid issues) are delt with
# we can now focus on assinging students who listed all or a few invalid issues to events

# Any student who listed even one invalid issue is placed randomlly into an event

# Iterate through the students_with_invalid_interests hash-map
students_with_invalid_interests.each do |student_id|
  
  # Find the projects with the least number of students without going over max students limit
  least_volunteers_project_ids = priority_proj_queue.select do |event_id, x| 
    x < event_information[event_id]['Max-Students'] && x == priority_proj_queue.values.min 
  end.keys
  
  # We are checking if there are any elements/IDs in the least_volunteers_project_ids ARRAY
  if least_volunteers_project_ids.any?

    # The .sample ruby method is essentially selecting a random element (or ID in this case)
    # and assigning it to the best_project_id variable
    best_project_id = least_volunteers_project_ids.sample

   else 
     # puts no suitable project for student #{student_id}"
     next

  end
  
  # Increase the volunteer count for the (randomly) chosen project
  priority_proj_queue[best_project_id] += 1

  # Assign the chosen project to the student. We hash the best project ID to the student ID
  assigned_activity[student_id] = best_project_id

end


# Must cancel an event if the volunteer count is less than the minimimum required for the event
priority_proj_queue.each do |event_id, student_count|
  if student_count < event_information[event_id]['Min-Students']
    canceled_events << event_id # append event ID to hash
  end
end

# We can print which events were canceled
# canceled_events.each do |event_id|
#    puts "Activity with event-id #{event_id} has been canceled."
# end

# Can print the volunteering activity ID and all its assigned students to double check everything
# assigned_activity.each do |student_id, project_id|
#   puts "Student #{student_id} has been assigned to project #{project_id}"
# end

# Print to see potential events
# potential_projects.each do |student_id, potential_projects|
#   # puts "Student #{student_id} potential events: #{potential_projects.join(', ')}"
# end

# Make output_file1 CSV and output_file3 TXT file (summary)

CSV.open('output_file1.csv', 'wb') do |csv|

  csv << ['Event-Id', 'Event-Name', 'Event-Issues', 'Min-Students', 'Max-Students', 'Num-Students', 'Roster', 'Status']
  
  event_information.each do |event_id, event_info|

    roster = assigned_activity.select { |student_id, assigned_event_id| assigned_event_id == event_id }.map do |student_id, _|

      matching_issues = (student_information[student_id]['Interests'] & event_info['Event-Issues']).join(', ')
      "#{student_id} #{matching_issues}"

    end.join('; ')

    num_students = priority_proj_queue[event_id]
    roster = 'None' if roster.empty?

    status = if canceled_events.include?(event_id)
               'Canceled'
             elsif num_students <= event_info['Max-Students'] && num_students >= event_info['Min-Students']
               'Ok'
             else
               'Problem'
             end

    csv << [event_id, event_info['Event-Name'], event_info['Event-Issues'].join('; '), event_info['Min-Students'], event_info['Max-Students'], num_students, roster, status]

  end
end

# Generate output text file

# Do necessary calculations for the summary
valid_student_count = student_information.size - students_with_invalid_interests.size
events_can_run = event_information.count { |event_id, event_info| priority_proj_queue[event_id] >= event_info['Min-Students'] }
events_may_cancel = event_information.count { |event_id, event_info| priority_proj_queue[event_id] < event_info['Min-Students'] && priority_proj_queue[event_id] > 0 }
events_canceled = canceled_events.size

File.open('output_file3.txt', 'w') do |file|

  file.puts "Number of students: #{valid_student_count}"
  file.puts "Number of events that can run: #{events_can_run}"
  file.puts "Number of events that may be canceled: #{events_may_cancel}"
  file.puts "Number of events that have been canceled: #{events_canceled}"
end


# Also, display summary to the terminal screen

puts "Number of students: #{valid_student_count}"
puts "Number of events that can run: #{events_can_run}"
puts "Number of events that may be canceled: #{events_may_cancel}"
puts "Number of events that have been canceled: #{events_canceled}"

# # puts students_with_invalid_interests --> for debugging



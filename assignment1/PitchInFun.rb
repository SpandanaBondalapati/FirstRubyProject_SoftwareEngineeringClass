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
students_with_invalid_interests = []


# Declare interests array globally to use in event_information block
student_interests = []
event_issues = []

valid_interests = ["food insecurity", "poverty", "racial inequality", "climate change", "homelessness", "healthcare", "gender inequality"]

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

# This is where I find potential projects for each student based on any volunteer
# project issues that match their interests. We are not actually assigning projects here
student_information.each do |student_id, student_info| # block params
  # check if we are iterating correctly
   # puts student_information.keys
   # "#{key}: #{value}"

  # store interests as an array of strings; must be able to hold up to 3 interests
  student_interests = student_info['Interests']
  potential_projects[student_id] = []

  # **TO-DO** Store invalid student interests into a seperate hash to handle after all valid interests have been processed

  if (student_interests - valid_interests).any?

    students_with_invalid_interests << student_id
    next

  end


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

priority_proj_queue = {} # key-value is event ID => number of volunteers
event_information.each do |event_id, _| 

  priority_proj_queue[event_id] = 0

end

# puts priority_proj_queue



potential_projects.each do |student_id, projects|
  project_scores = {}

  # figure out how to do a conditional sort of the potential projects hash map 
  # key-value is student-ID => event-ID
  # Condition 1: Preferably an activity that has the least amount of students
  # Condition 2: Student is matched with an activity that meets most of their interests
  # => It must meet at least one of their interests, so look for an activity that meets
  # => all 3 and if there are none then search for one that matches at least 2
  # => and then search for one that matches at least 1
  # Assume that if a student lists even one invalid issue, they're automatically going to be processed at the lowest priority level

   # First, find the best project (does it align with 3, 2 or 1 of their interests)

  projects.each do |project_id|

    event_issues = event_information[project_id]['Event-Issues']
    student_interests = student_information[student_id]['Interests']
  
    num_similar = (student_interests & event_issues).size
    project_scores[project_id] = num_similar

  end

  # sorted scores has the priority score of each project
  sorted_scores = project_scores.sort_by do |project_id, score|

    [-score, priority_proj_queue[project_id]] 

  end
  # puts sorted_scores

  # must make sure we don't go over the max num of students
  bestProject = sorted_scores.detect do |project_id, _|

    event_information[project_id]['Max-Students'].to_i > priority_proj_queue[project_id]

  end

  if bestProject
    best_project = bestProject.first # get the project-id
    assigned_activity[student_id] = best_project

    # Increase the volunteer count for the chosen project
    priority_proj_queue[best_project] += 1

  else
    puts "must assign to a project w the least amt of volunteers"

  end

end

# we must deal with students that input invalid student interests
students_with_invalid_interests.each do |student_id|

  least_volunteers_project_ids = priority_proj_queue.select { |_, x| x == priority_proj_queue.values.min }.keys
  
  # check if there are any elements in the least_volunteers_project_ids array/enumerable
  if least_volunteers_project_ids.any?
    best_project_id = least_volunteers_project_ids.sample

  else
    puts "No suitable project for student #{student_id}"
  end
  
  # Increase the volunteer count for the chosen project
  priority_proj_queue[best_project_id] += 1

  # Assign the chosen project to the student
  assigned_activity[student_id] = best_project_id
end

# Must cancel a volunteering activity if there are no students assigned to it
canceled_events = []
priority_proj_queue.each do |event_id, student_count|
  if student_count == 0
    canceled_events << event_id
  end
end

canceled_events.each do |event_id|
   puts "Activity with event-id #{event_id} has been canceled."
end


assigned_activity.each do |student_id, project_id|
  # puts "Student #{student_id} has been assigned to project #{project_id}"
end

# Print to see potential events
potential_projects.each do |student_id, potential_projects|
  # puts "Student #{student_id} potential events: #{potential_projects.join(', ')}"
end

CSV.open('output_file1.csv', 'wb') do |csv|
  # Write the header row
  csv << ['Event-Id', 'Event-Name', 'Event-Issues', 'Min-Students', 'Max-Students', 'Num-Students', 'Roster', 'Status']
  
  # Write data rows
  event_information.each do |event_id, event_info|
    roster = assigned_activity.select { |_, assigned_event_id| assigned_event_id == event_id }.map { |student_id, _| "#{student_id} your_issue_here" }.join('; ')
    roster = 'None' if roster.empty?
    num_students = roster == 'None' ? 0 : roster.split('; ').size
    status = if num_students >= event_info['Min-Students'].to_i
               'Ok'
             elsif num_students == 0
               'Problem'
             else
               'Cancel'
             end
    csv << [event_id, event_info['Event-Name'], event_info['Event-Issues'].join('; '), event_info['Min-Students'], event_info['Max-Students'], num_students, roster, status]
  end
end

File.open('output_file3.txt', 'w') do |file|
  valid_student_count = student_information.size - students_with_invalid_interests.size
  events_can_run = event_information.count { |_, event_info| priority_proj_queue[event_info['Event-ID']] >= event_info['Min-Students'].to_i }
  events_may_cancel = event_information.count { |_, event_info| priority_proj_queue[event_info['Event-ID']] < event_info['Min-Students'].to_i }
  events_zero_students = priority_proj_queue.count { |_, v| v == 0 }

  file.puts "Number of students: #{valid_student_count}"
  file.puts "Number of events that can run: #{events_can_run}"
  file.puts "Number of events that may be canceled: #{events_may_cancel}"
  file.puts "Number of events that have 0 students assigned: #{events_zero_students}"
end


# Print the hash maps to check the values are stored properly
# puts "Event Information:"
# puts event_information

# puts "Student Information:"
# puts student_information







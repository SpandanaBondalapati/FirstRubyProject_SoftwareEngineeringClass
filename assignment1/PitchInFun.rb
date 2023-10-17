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

# Last Modified (For Inital Submission): September 21st, 2023

=begin 

Updated Capabilities Comment: For the the assignment 1 revision, the focus is on improving my project's modulairty as well as implementing 
the missing user interaction where the user can specify their input and output file names. 

* I unfortunately ran out of time to properly comment the code again, but got full marks on the previous submission for comments

=end

require 'csv'

# Declare a list of valid social issues to reference
valid_interests = ["food insecurity", "poverty", "racial inequality", "climate change", "homelessness", "healthcare", "gender inequality"]

class ReadEvent
  attr_reader :event_name, :event_issues, :min_students, :max_students

  # Read the events CSV file and store the values in the hash map called 'Event-Information'
  # The key is the volunteering event ID and the values are the event attributes such as name, event issues, minimumum + maximum students
  def initialize(event_name, event_issues, min_students, max_students)
    @event_name = event_name
    @event_issues = event_issues
    @min_students = min_students
    @max_students = max_students
  end

  def self.populate_event_hash(file)
    event_information = {}

    CSV.foreach(file, headers: true) do |row|
      event_information[row['Event-Id']] = ReadEvent.new(
        row['Event-Name'],
        row['Event-Issues'].split('; '),
        row['Min-Students'].to_i,
        row['Max-Students'].to_i
      )
    end

    # Print the event information
    event_information.each do |key, event|
      #puts "#{key} : #{event.event_name}, #{event.event_issues.join(', ')}, #{event.min_students}, #{event.max_students}"
    end
    
  end
end

class ReadInterest

  # Allows the instance variables to be read outside the class
  attr_reader :stud_id, :interests

  # Constructor for the class
  def initialize(stud_id, interests)
    @stud_id = stud_id
    @interests = interests
  end

  def self.populate_student_hash(file)

    student_information = {}

    # Read the CSV file and store the values in the hash map called 'Student-Information'
    # The key is the student-ID and the value is the social issues the student is interested in volunteering for.
    # The program will later check if the students interests are valid (from the valid_interests array)
    CSV.foreach(file, headers: true) do |row|
      student_information[row['Student-Id']] = ReadInterest.new(
        row['Student-Id'],
        row['Interests'].split('; ')

      )
    end

    # Print the student information
    student_information.each do |key, student_info|
      #puts "#{key} : #{student_info.interests.join(', ')}"
    end
  end

end

# Class to handle valid students and match them with events
# In this segment of code, I find projects that students (who put down only valid interests) could potentially be placed into.
# I determine if a project is a 'potential project' if the event has *any* social issues that the valid student had listed.
# Here, we are iterating through the student_information hash in order to identify which are potential projects for each student
class ValidStudentHandler

  attr_reader :student_information, :event_information, :valid_interests, :potential_projects, :priority_proj_queue, :students_with_invalid_interests

  # Constructor for the class
  def initialize(student_information, event_information, valid_interests)

    @student_information = student_information
    @event_information = event_information
    @valid_interests = valid_interests
    @potential_projects = {}
    @priority_proj_queue = {}

  end


  # Determine potential projects for each student based on their interests
  def determine_potential_projects
    @students_with_invalid_interests = []
    @student_information.each do |student_id, student_info|
      student_interests = student_info.interests
  
      @potential_projects[student_id] = []
  
      if (student_interests - @valid_interests).any?
        @students_with_invalid_interests << student_id
        student_interests = student_interests & @valid_interests
      end  
  
      @event_information.each do |event_id, event_info|
        event_issues = event_info.event_issues
        if (student_interests & event_issues).any?
          @potential_projects[student_id] << event_id 
        end
      end
    end
    @potential_projects
  end
  

  # Initialize priority queue for projects
  def init_priority_proj_queue
    @event_information.each do |event_id, _| 
      @priority_proj_queue[event_id] = 0
    end
    @priority_proj_queue
  end

  # Assign students to their best potential projects
  def assign_best_projects
    assigned_activity = {}

    @potential_projects.each do |student_id, projects|
      project_scores = {}
      projects.each do |project_id|
        #event_issues = @event_information[project_id]['Event-Issues']
        event_issues = @event_information[project_id].event_issues
        #student_interests = @student_information[student_id]['Interests']
        student_interests = @student_information[student_id].interests
        num_similar = (student_interests & event_issues).size
        project_scores[project_id] = num_similar
      end

      sorted_scores = project_scores.sort_by do |project_id, score|
        [-score, @priority_proj_queue[project_id]]
      end

      best_project = sorted_scores.find do |project_id, _|
        event_info = @event_information[project_id]
        #@priority_proj_queue[project_id] < event_info['Max-Students']
        @priority_proj_queue[project_id] < event_info.max_students
      end

      if best_project
        best_project_id = best_project.first
        assigned_activity[student_id] = best_project_id
        @priority_proj_queue[best_project_id] += 1
      end
    end

    assigned_activity
  end

  

end

# Since all the "valid students" (students who only listed valid issues) are delt with
# we can now focus on assinging students who listed all or a few invalid issues to events
# Any student who listed even one invalid issue is placed randomlly into an event
# Iterate through the students_with_invalid_interests hash-map
class HandleInvalidStudents
  attr_reader :students_with_invalid_interests

  
  def initialize(event_information)
    @event_information = event_information
  end

  

  # Assigns students who have invalid interests to events
  def assign_students(students_with_invalid_interests, priority_proj_queue)
    assigned_activity = {}

    students_with_invalid_interests.each do |student_id|
      best_project_id = find_least_volunteer_project(priority_proj_queue)
      next unless best_project_id
      
      priority_proj_queue[best_project_id] += 1
      assigned_activity[student_id] = best_project_id
    end

    assigned_activity
  end
  
  # Returns events that must be canceled due to not meeting minimum student count
  def events_to_cancel(priority_proj_queue)
    canceled_events = []
    
    priority_proj_queue.each do |event_id, student_count|
      if student_count < @event_information[event_id].min_students
        canceled_events << event_id
      end
    end
    
    canceled_events
  end

  private

  # Selects a project with the least number of students without going over max limit
  def find_least_volunteer_project(priority_proj_queue)
    least_volunteers_project_ids = priority_proj_queue.select do |event_id, x| 
      x < @event_information[event_id].max_students && x == priority_proj_queue.values.min
    end.keys

    least_volunteers_project_ids.any? ? least_volunteers_project_ids.sample : nil
  end
end

class OutputHandler
  def initialize(event_information, assigned_activity, priority_proj_queue, student_information, canceled_events, students_with_invalid_interests)
    @event_information = event_information
    @assigned_activity = assigned_activity
    @priority_proj_queue = priority_proj_queue
    @student_information = student_information
    @canceled_events = canceled_events
    @students_with_invalid_interests = students_with_invalid_interests
  end
  

  def generate_csv_output(filename)
    CSV.open(filename, 'wb') do |csv|
      csv << ['Event-Id', 'Event-Name', 'Event-Issues', 'Min-Students', 'Max-Students', 'Num-Students', 'Roster', 'Status']
      
      @event_information.each do |event_id, event_info|
        csv << event_row(event_id, event_info)
      end
    end
  end
  
  def generate_summary_output(filename)
    File.open(filename, 'w') do |file|
      summary_content.each { |line| file.puts line }
    end
  end
  
  def print_summary_to_terminal
    summary_content.each { |line| puts line }
  end

  private

  def event_row(event_id, event_info)
    roster = @assigned_activity.select { |student_id, assigned_event_id| assigned_event_id == event_id }.map do |student_id, _|
      matching_issues = (@student_information[student_id].interests & event_info.event_issues).join(', ')
      "#{student_id} #{matching_issues}"
    end.join('; ')

    num_students = @priority_proj_queue[event_id]
    roster = 'None' if roster.empty?

    status = determine_status(event_id, num_students, event_info)

    [event_id, event_info.event_name, event_info.event_issues.join('; '), event_info.min_students, event_info.max_students, num_students, roster, status]
  end

  def determine_status(event_id, num_students, event_info)
    if @canceled_events.include?(event_id)
      'Canceled'
    elsif num_students <= event_info.max_students && num_students >= event_info.min_students
      'Ok'
    else
      'Problem'
    end
  end

  # Use this function to display the summary 
  def summary_content

    #valid_student_count = @student_information.size - students_with_invalid_interests.size
    valid_student_count = @student_information.size - @students_with_invalid_interests.size
    events_can_run = @event_information.count { |event_id, event_info| @priority_proj_queue[event_id] >= event_info.min_students }
    events_may_cancel = @event_information.count { |event_id, event_info| @priority_proj_queue[event_id] < event_info.min_students && @priority_proj_queue[event_id] > 0 }
    events_canceled = @canceled_events.size

    [
      "Number of students: #{valid_student_count}",
      "Number of events that can run: #{events_can_run}",
      "Number of events that may be canceled: #{events_may_cancel}",
      "Number of events that have been canceled: #{events_canceled}"
    ]
  end

end


# Include user interaction to specify the file names
# Include error handling in case they specify an input file that is not included in directory
def prompt_for_filename(message)
  puts message
  filename = gets.chomp

  until File.exist?(filename)
    puts "File '#{filename}' does not exist. Please provide a valid filename."
    filename = gets.chomp
  end

  filename
end

# Method calls and creating instances of the classes that were made:

event_file = prompt_for_filename("Please provide the name of the events CSV file:")
interest_file = prompt_for_filename("Please provide the name of the interests CSV file:")
output_csv_file = prompt_for_filename("Please provide the name for the CSV output file:")
output_summary_file = prompt_for_filename("Please provide the name for the summary output file:")

event_information = ReadEvent.populate_event_hash(event_file)
student_information = ReadInterest.populate_student_hash(interest_file)

valid_student_handler = ValidStudentHandler.new(student_information, event_information, valid_interests)
potential_projects = valid_student_handler.determine_potential_projects
priority_proj_queue = valid_student_handler.init_priority_proj_queue
assigned_activity = valid_student_handler.assign_best_projects

# Handle invalid students
invalid_students_handler = HandleInvalidStudents.new(event_information)
assigned_activity_for_invalid_students = invalid_students_handler.assign_students(valid_student_handler.students_with_invalid_interests, priority_proj_queue)
canceled_events = invalid_students_handler.events_to_cancel(priority_proj_queue)


output_handler = OutputHandler.new(event_information, assigned_activity, priority_proj_queue, student_information, canceled_events, valid_student_handler.students_with_invalid_interests)
output_handler.generate_csv_output('output_file1.csv')
output_handler.generate_summary_output('output_file3.txt')
output_handler.print_summary_to_terminal()

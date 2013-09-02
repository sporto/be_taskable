class {{class_name}} < BeTaskable::TaskResolver

	def consensus?(task)
		# task.any_assignment_done?
		# if any assignment is completed then return true

		# task.majority_of_assignments_done?
		# if the majority of assignments are completed then return true

		# task.all_assignments_done?
		# if all assignments are completed then return true
			
		# use task.assignments to calculate consensus manually
		# false
	end
			
	def is_task_relevant?(task)
		# get the taskable by calling task.taskable
		# evaluate if a task is still relevant
		# e.g. the taskable object is no longer valid
		# if this method returns false then:
		#   - the task will be marked as irrelevant 
		#   - the assignments will be deleted (except the already completed ones)
		true
	end

	def assignees_for_task(task)
		# get the taskable by calling task.taskable
		[]
	end

	def due_date_for_assignment(assignment)
		# get the taskable by calling assignment.taskable
		nil
	end
	
	def visible_date_for_assignment(assignment)
		# get the taskable by calling assignment.taskable
		nil
	end

	def label_for_task(task)
		# get the taskable by calling task.taskable
		""
	end

	def label_for_assignment(assignment)
		# get the taskable by calling assignment.taskable
		""
	end

	def url_for_assignment(assignment)
	# get the taskable by calling assignment.taskable
		""
	end

	# hooks
	def on_creation(task)
	end

	def on_completion(task)
	end

	def on_expiration(task)
	end

end
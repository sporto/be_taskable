module BeTaskable
	class TaskResolver

		def consensus?(task)
			raise NotImplementedError
		end

		def is_task_relevant?(task)
			true
		end

		def assignees_for_task(task)
			[] #raise NotImplementedError
		end

		def due_date_for_assignment(assignment)
			nil
		end

		def visible_date_for_assignment(assignment)
			nil
		end

		def label_for_task(task)
			""
		end

		def label_for_assignment(assignment)
			""
		end

		def url_for_assignment(assignment)
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
end

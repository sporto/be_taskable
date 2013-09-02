class User < ActiveRecord::Base
	be_tasker
end

class Taskable < ActiveRecord::Base
	be_taskable
end

class TaskablePublishTaskResolver < BeTaskable::TaskResolver
end

class TaskableReviewTaskResolver < BeTaskable::TaskResolver

	def consensus?(assignments)
		false
	end

	def assignees_for_task(task)
		[]
	end

	def due_date_for_assignment(assignment)
		DateTime.now + 10.days
	end

	def label_for_task(task)
		"Task label #{task.id}"
	end

	def label_for_assignment(assignment)
		"Assignment label #{assignment.id}"
	end

	def url_for_assignment(assignment)
		"Assignment url #{assignment.id}"
	end

end
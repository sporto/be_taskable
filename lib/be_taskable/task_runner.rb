module BeTaskable
	class TaskRunner

		attr_reader :task

		def initialize(task)
			raise ArgumentError, "Invalid task" unless task.is_a?(BeTaskable::Task)
			@task = task
		end

		def refresh

			return if task.completed?

			_mark_assignments_as_unconfirmed

			if _relevant?
				_make_task_relevant
				_update_task_label
				_update_assignments
			else
				_make_task_irrelevant
			end

			_delete_unconfirmed_assignments
		end

		def resolver
			task.resolver
		end

		def _mark_assignments_as_unconfirmed
			_assignments.uncompleted.update_all(confirmed: false)
		end

		def _delete_unconfirmed_assignments
			_assignments.uncompleted.unconfirmed.delete_all
		end

		def _update_task_label
			task.update_attribute(:label, resolver.label_for_task(task))
		end

		def _make_task_relevant
			task.make_relevant if task.can_make_relevant?
		end

		def _make_task_irrelevant
			# assignments will be just deleted
			# no need to update them
			task.make_irrelevant if task.can_make_irrelevant?
		end

		def _update_assignments
			_assignees.each do |assignee|
				# find the assignment
				assignment = _assignments.where(assignee_id: assignee.id).last

				unless assignment
					assignment = _assignments.create(assignee: assignee)
				end
				
				assignment.complete_by = resolver.due_date_for_assignment(assignment)
				assignment.visible_at = resolver.visible_date_for_assignment(assignment)
				assignment.label = resolver.label_for_assignment(assignment)
				assignment.url = resolver.url_for_assignment(assignment)
				assignment.confirmed = true
				assignment.save
			end
		end

		def _relevant?
			# if the taskable cannot be found then assume it is not relevant
			return false unless task.taskable
			resolver.is_task_relevant?(task)
		end

		def _assignees
			resolver.assignees_for_task(task)
		end

		def _assignments
			task.assignments
		end

	end
end
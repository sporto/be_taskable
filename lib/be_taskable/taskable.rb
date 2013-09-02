module BeTaskable
	module Taskable

		def be_taskable(*actions)
			include InstanceMethods

			has_many :tasks, class_name: '::BeTaskable::Task', dependent: :destroy, as: :taskable
		end

		def _task_resolver_name_for_action(action)
			self.name + action.camelize + 'TaskResolver'
		end

		def _task_resolver_for_action(action)
			_task_resolver_name_for_action(action).constantize.new
		end

		module InstanceMethods

			# hook for testing
			# e.g. expect(instance).to be_taskable
			def taskable?
				true
			end

			# @param {String} action Name of the action
			# @return {Object} Resolver instance for the given action
			def task_resolver_for_action(action)
				self.class._task_resolver_for_action(action)
			end

			# Create a task and run it
			# @param {String} action Name of the action
			# @return {BeTaskable::Task} A task object
			def create_task_for_action(action)
				raise(ActiveRecord::RecordNotSaved, "Taskable must be persisted") unless self.persisted?

				task = tasks.create(action: action)
				
				if task.persisted?
					task.on_creation
					task.refresh
				else
					raise "Couldn't create task #{task.errors.full_messages}"
				end

				task
			end

			# Finds or Create a task and run it
			# @param {String} action Name of the action
			# @return {BeTaskable::Task} A task object
			def create_or_refresh_task_for_action(action)
				# if already created use that task
				task = last_current_task_for_action(action)
				
				if !task
					task = create_task_for_action(action)
				else
					task.refresh
				end

				task
			end

			# @param {String} action Name of the action
			# @return {ActiveRecord::Relation}
			def tasks_for_action(action)
				tasks.where(action: action)
			end

			def current_tasks_for_action(action)
				tasks.where(action: action).current
			end

			# @param {String} action Name of the action
			# @return {BeTaskable::Task} Last task for the given action
			def last_task_for_action(action)
				tasks_for_action(action).last
			end

			# @return {BeTaskable::Task} Last current task for the given action
			def last_current_task_for_action(action)
				current_tasks_for_action(action).last
			end

			# @return {Array} All current assignments for this taskable
			def task_assignments
				tasks.map(&:assignments).flatten
			end

			# @return {Array} All current assignments for this action
			# returns an empty array if it cannot find the task
			def task_assignments_for_action(action)
				tasks_for_action(action).map(&:assignments).flatten
			end


			# @param {String} action
			# @param {Object} assignee
			# @return {TaskAssignment}
			# Return nil if it cannot find the task
			def task_assignment_for(action, assignee)
				task = last_task_for_action(action)
				task.assignment_for(assignee) if task
			end

			def current_task_assignment_for(action, assignee)
				task = last_current_task_for_action(action)
				task.assignment_for(assignee) if task
			end

			# @param {String} action Name of the action
			# Completes the last task for an action (and all the assignments)
			def complete_task_for_action(action)
				task = last_task_for_action(action)
				return false unless task
				task.complete!
			end

			# Completes all task for this action
			# Only for uncompleted tasks
			def complete_tasks_for_action(action)
				ts = current_tasks_for_action(action)

				return false unless ts.any?
				ts.each do |task|
					task.complete!
				end
				true
			end

			# @param {String} action Name of the action
			# @param {Object} assignee
			# Completes a task assignment
			def complete_task_for(action, assignee)
				task = last_task_for_action(action)
				return false unless task
				task.complete_by(assignee)
			end

			# Expire all task for this action
			# Only for uncompleted tasks
			def expire_tasks_for_action(action)
				ts = current_tasks_for_action(action)
				
				return false unless ts.any?
				ts.each do |task|
					task.expire
				end
				true
			end

		end

	end
end
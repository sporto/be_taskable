module BeTaskable
	module Tasker

		def be_tasker
			include InstanceMethods

			has_many :task_assignments, class_name: '::BeTaskable::TaskAssignment', dependent: :destroy, foreign_key: :assignee_id
		end

		module InstanceMethods

			# hook for testing
			# e.g. expect(instance).to be_tasker
			def tasker?
				true
			end

		end

	end
end
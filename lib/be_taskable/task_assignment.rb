module BeTaskable
	class TaskAssignment < ActiveRecord::Base
		belongs_to :task, class_name: '::BeTaskable::Task'
		belongs_to :assignee, polymorphic: true

		scope :completed, where('completed_at IS NOT NULL')
		scope :uncompleted, where(completed_at: nil)
		scope :expired, where('expired_at IS NOT NULL')
		scope :unexpired, where(expired_at: nil)
		scope :unconfirmed, where(confirmed: [nil, false])
		scope :visible, ->{ where('visible_at IS NULL OR visible_at < ?', DateTime.now.to_formatted_s(:db)) }
		scope :overdue, ->{ where('complete_by < ? AND completed_at IS NULL', DateTime.now.to_formatted_s(:db)) }
		scope :not_overdue, ->{ where('complete_by IS NULL OR complete_by > ?', DateTime.now.to_formatted_s(:db)) }
		scope :enacted, where(enacted: true)

		def self.current
			self.uncompleted.unexpired.not_overdue.visible
		end

		# @return {Boolean}
		def completed?
			!!completed_at
		end

		# @return {Boolean}
		def visible?
			self.class.visible.exists?(self)
		end

		# completes the assignment by the assignee
		# it triggers a hook in task (on_assignment_complete)
		def complete
			return false if completed?
			self.update_attribute(:completed_at, DateTime.now)
			self.update_attribute(:enacted, true)
			task.on_assignment_completed(self)
			true
		end

		# Gets the label from the resolver
		def label!
			resolver.label_for_assignment(self)
		end

		# Gets the url from the resolver
		def url!
			resolver.url_for_assignment(self)
		end

		# @return {Object} A resolver instance
		def resolver
			task.resolver
		end

		def taskable
			task.taskable
		end

	end
end

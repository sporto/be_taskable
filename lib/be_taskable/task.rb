module BeTaskable
	class Task < ActiveRecord::Base
		
		has_many :assignments, class_name: '::BeTaskable::TaskAssignment', dependent: :destroy
		belongs_to :taskable, polymorphic: true

		scope :completed, where('completed_at IS NOT NULL')
		scope :uncompleted, where(completed_at: nil)
		scope :expired, where('expired_at IS NOT NULL')
		scope :unexpired, where(expired_at: nil)
		# scope :overdue, ->() { where('complete_by IS NOT NULL AND completed_at = NULL AND completed_at < ?', DateTime.now) }

		validates :taskable_type, presence: true
		validates :taskable_id, presence: true
		validates :action, presence: true #, uniqueness: { scope: [:taskable_type, :taskable_id] }

		def self.current
			self.uncompleted.unexpired
		end

		state_machine :state, initial: :open do
			event :complete do
				transition :open => :completed
			end
			event :expire do
				transition :open => :expired
			end
			event :make_irrelevant do
				transition :open => :irrelevant
			end
			event :make_relevant do
				transition :irrelevant => :open
			end
			after_transition :open => :completed, :do => :_on_completion
			after_transition :open => :expired, :do => :_on_expiration
		end

		#-------------------------------------------------------------------------
		# Actions
		#-------------------------------------------------------------------------

		# refresh
		# Check that the current assignments are still relevant
		# Create new assignments as needed or deletes them
		# needs to run for irrelevant
		def refresh
			return if completed?
			_runner.refresh
		end

		# tally
		# Check all the completed assignments and decides wherever to complete the task
		# @return nil if completed
		def tally
			return if completed?
			complete if consensus?
		end

		# calls refresh and then tally
		# needs to run for irrelevant
		def audit
			return if completed?
			refresh
			tally
		end

		# completes the assignment for the given assignee
		# @param {Object} assignee
		# @return false if no assignment found
		def complete_by(assignee)
			assignment = assignment_for(assignee)
			return false unless assignment
			assignment.complete
		end

		# consensus?
		# @return Boolean
		def consensus?
			resolver.consensus?(self)
		end

		#-------------------------------------------------------------------------
		# Accessors
		#-------------------------------------------------------------------------

		# @return {Array} List of current assignees for this task
		def assignees
			assignments.map(&:assignee)
		end

		# @return {String} Gets the label from the resolver for this task
		def label!
			resolver.label_for_task(self)
		end

		def assignment_for(assignee)
			assignments.where(assignee_id: assignee.id).last
		end

		def enacted_assignments
			assignments.enacted
		end

		# resolver
		# @return A resolver instance
		def resolver
			if taskable
				taskable.task_resolver_for_action(action)
			else
				# puts self.id
				# puts self.taskable_id
				# puts self.taskable_type
				# puts self.taskable
				raise "Cannot find taskable" 
			end
		end

		#-------------------------------------------------------------------------
		# Hooks
		#-------------------------------------------------------------------------

		def on_creation
			resolver.on_creation(self)
		end

		# hook: called from an assignment when completed
		def on_assignment_completed(assignment)
			tally
		end

		#-------------------------------------------------------------------------
		# Consensus helpers
		#-------------------------------------------------------------------------

		def all_assignments_done?
			assignments.all?{ |a| a.completed? }
		end

		def any_assignment_done?
			assignments.any?{ |a| a.completed? }
		end

		def majority_of_assignments_done?
			done = assignments.find_all{ |a| a.completed? }
			done.size > (assignments.size.to_f / 2)
		end

		#-------------------------------------------------------------------------
		# Pseudo private
		#-------------------------------------------------------------------------

		def _runner
			@runner ||= BeTaskable::TaskRunner.new(self)
		end

		# called when the task is marked as complete by the state machine
		def _on_completion
			self.update_attribute(:completed_at, DateTime.now)
			assignments.update_all(completed_at: DateTime.now)
			resolver.on_completion(self)
		end

		# expires the task and all the assignments
		def _on_expiration
			self.update_attribute(:expired_at, DateTime.now)
			assignments.each do |assignment|
				assignment.expire
			end
			resolver.on_expiration(self)
		end

	end
end
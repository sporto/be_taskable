require "active_record"
require "active_record/version"
# require "action_view"

$LOAD_PATH.unshift(File.dirname(__FILE__))

module BeTaskable
	def self.table_name_prefix
		'be_taskable_'
	end
end

require "state_machine"
require "be_taskable/taskable"
require "be_taskable/tasker"
require "be_taskable/task"
require "be_taskable/task_assignment"
require "be_taskable/task_resolver"
require "be_taskable/task_runner"

if defined?(ActiveRecord::Base)
	ActiveRecord::Base.extend BeTaskable::Taskable
	ActiveRecord::Base.extend BeTaskable::Tasker
end

# view helpers
# if defined?(ActionView::Base)
#   ActionView::Base.send :include, ActsAsTaggableOn::TagsHelper
# end
require 'rails/generators'

module BeTaskable
	class ResolverGenerator < Rails::Generators::Base
		desc "Create a Task Resolver"

		def self.source_root
			@source_root ||= File.join(File.dirname(__FILE__), 'templates')
		end

		argument :taskable, type: :string
		argument :action_name, type: :string

		def copy_class_file
			dest = "app/task_resolvers/#{taskable}_#{action_name}_task_resolver.rb"
			copy_file "resolver.rb.tpl", dest
			class_name = "#{taskable.camelize}#{action_name.camelize}TaskResolver"
			gsub_file dest, '{{class_name}}', class_name
		end

		# def copy_spec_file
		# 	dest = "spec/services/#{name}_service_spec.rb"
		# 	copy_file "spec.rb.tpl", dest
		# 	gsub_file dest, '{{class_name}}', "#{name.camelize}Service"
		# end

	end
end
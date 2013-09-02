require 'rails/generators'
require 'rails/generators/migration'

module BeTaskable
	class MigrationGenerator < Rails::Generators::Base

		include Rails::Generators::Migration

		desc "Generates migration for BeTaskable Models"

		def self.orm
			Rails::Generators.options[:rails][:orm]
		end

		def self.source_root
			File.join(File.dirname(__FILE__), 'templates', (orm.to_s unless orm.class.eql?(String)) )
		end

		def self.orm_has_migration?
			[:active_record].include? orm
		end

		def self.next_migration_number(dirname)
			if ActiveRecord::Base.timestamped_migrations
				migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
				migration_number += 1
				migration_number.to_s
			else
				"%.3d" % (current_migration_number(dirname) + 1)
			end
		end

		def create_migration_file
			if self.class.orm_has_migration?
				migration_template 'migration.rb', "db/migrate/#{migration_name}"
			end
		end

		def migration_name
			'be_taskable_migration'
		end

	end
end
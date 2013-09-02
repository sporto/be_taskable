# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))
# require 'gbg_tasks'

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require 'logger'
require 'database_cleaner'
require 'active_record'
require 'action_view'
require 'action_controller'
require 'rspec/rails'
require 'rspec-steps'

# Make sure the right version of bundler is loaded
begin
	require "rubygems"
	require "bundler"

	if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.5")
		raise RuntimeError, "Your bundler version is too old. Run `gem install bundler` to upgrade."
	end

# Set up load paths for all bundled gems
Bundler.setup
rescue Bundler::GemNotFound
	raise RuntimeError, "Bundler couldn't find some gems. Did you run \`bundlee install\`?"
end

Bundler.require
require File.expand_path('../../lib/be_taskable', __FILE__)

# set adapter to use, default is sqlite3
# to use an alternative adapter run => rake spec DB='postgresql'
db_name = ENV['DB'] || 'sqlite3'
database_yml = File.expand_path('../database.yml', __FILE__)

# Load the data
if File.exists?(database_yml)
	active_record_configuration = YAML.load_file(database_yml)

	ActiveRecord::Base.configurations = active_record_configuration
	config = ActiveRecord::Base.configurations[db_name]

	begin
		ActiveRecord::Base.establish_connection(db_name)
		ActiveRecord::Base.connection	
	rescue
		case db_name
			when /mysql/
				ActiveRecord::Base.establish_connection(config.merge('database' => nil))
				ActiveRecord::Base.connection.create_database(config['database'],  {:charset => 'utf8', :collation => 'utf8_unicode_ci'})
			when 'postgresql'
				ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
				ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => 'utf8'))
			end

		ActiveRecord::Base.establish_connection(config)
	end

	ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))
	ActiveRecord::Base.default_timezone = :utc

	ActiveRecord::Base.silence do
		ActiveRecord::Migration.verbose = false

		load(File.dirname(__FILE__) + '/schema.rb')
		load(File.dirname(__FILE__) + '/models.rb')
	end

else
	raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
end

RSpec.configure do |config|
	config.treat_symbols_as_metadata_keys_with_true_values = true
	config.fail_fast = true

	# Run specs in random order to surface order dependencies. If you find an
	# order dependency and want to debug it, you can fix the order by providing
	# the seed, which is printed after each run.
	#     --seed 1234
	# config.order = "random"

	config.before :suite do
		DatabaseCleaner.strategy = :deletion
	end

	config.before(:each) do
		DatabaseCleaner.start
	end

	config.after(:each) do
		DatabaseCleaner.clean
	end

end
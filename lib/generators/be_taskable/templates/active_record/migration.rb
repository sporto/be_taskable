class BeTaskableMigration < ActiveRecord::Migration
	def self.up
		create_table :be_taskable_tasks do |t|
			t.string :action
			t.references :taskable, polymorphic: true
			t.string :state
			t.string :label
			t.datetime :completed_at
			t.datetime :expired_at
			t.timestamps
		end
		
		create_table :be_taskable_task_assignments do |t|
			t.integer :task_id
			t.references :assignee, polymorphic: true
			t.string :label
			t.string :url
			t.boolean :confirmed
			t.boolean :enacted
			t.datetime :visible_at
			t.datetime :complete_by
			t.datetime :completed_at
			t.datetime :expired_at
			t.timestamps
		end
		
		add_index :be_taskable_tasks, [:taskable_id, :taskable_type]
		add_index :be_taskable_task_assignments, :task_id
	end
	
	def self.down
		drop_table :be_taskable_tasks
		drop_table :be_taskable_task_assignments
	end
end
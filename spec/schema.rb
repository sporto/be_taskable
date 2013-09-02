ActiveRecord::Schema.define :version => 0 do

	create_table 'users', force: true do |t|
		t.timestamps
	end

	create_table 'taskables', force: true do |t|
		t.timestamps
	end

	create_table 'be_taskable_tasks', force: true do |t|
		t.string :action
		t.string :state
		t.integer :taskable_id
		t.string :taskable_type
		t.string :label
		t.datetime :completed_at
		t.datetime :expired_at
		t.timestamps
	end

	create_table 'be_taskable_task_assignments', force: true do |t|
		t.integer :task_id
		t.integer :assignee_id
		t.string :assignee_type
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

end

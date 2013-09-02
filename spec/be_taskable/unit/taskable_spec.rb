require File.expand_path('../../../spec_helper', __FILE__)

describe 'BeTaskable::Taskable' do

	let(:task) { double.as_null_object }
	let(:assignee) { double.as_null_object }
	let(:taskable) { Taskable.new }
	let(:resolver) { double.as_null_object }

	before do
		taskable.stub(:task_resolver_for_action).and_return(resolver)
		resolver.stub(:assignees_for_task).and_return([])
	end

	describe '#_task_resolver_name_for_action' do

		it "responds to _task_resolver_name_for_action" do
			expect(Taskable).to respond_to('_task_resolver_name_for_action')
		end

		it "returns the right name" do
			res = Taskable._task_resolver_name_for_action('publish')
			expect(res).to eq('TaskablePublishTaskResolver')
		end

		it "returns the right name for underscored actions" do
			res = Taskable._task_resolver_name_for_action('publish_something')
			expect(res).to eq('TaskablePublishSomethingTaskResolver')
		end
	end

	describe '#_task_resolver_for_action' do

		it "throws if it cannot find the resolver" do
			expect{ Taskable._task_resolver_for_action('update') }.to raise_error
		end

		it "returns the resolver" do
			res = Taskable._task_resolver_for_action('publish')
			expect(res).to be_instance_of(TaskablePublishTaskResolver)
		end
	end

	it "responds to taskable?" do
		expect(taskable).to be_taskable
	end

	describe ".task_resolver_for_action" do
		it "asks the class" do
			taskable.unstub(:task_resolver_for_action)
			action = 'publish'
			Taskable.should_receive(:_task_resolver_for_action).with(action)
			taskable.task_resolver_for_action(action)
		end
	end

	describe ".tasks" do
		it "responds to tasks" do
			expect(taskable).to respond_to('tasks')
		end

		it "finds the tasks" do
			taskable.save
			taskable.tasks.create
			taskable.tasks.create
			expect(taskable.tasks.size).to eq(2)
		end
	end

	describe ".create_task_for_action" do

		before do
			taskable.save
		end

		it "raises if it cannot find the resolver" do
			taskable.unstub(:task_resolver_for_action)
			expect{ taskable.create_task_for_action('view') }.to raise_error
		end

		it "raises if the taskable is not saved" do
			taskable = Taskable.new
			expect{ taskable.create_task_for_action('publish') }.to raise_error(ActiveRecord::RecordNotSaved)
		end

		it "creates a task" do
			task = taskable.create_task_for_action('publish')
			expect(taskable.tasks.size).to eq(1)
		end

		it "creates a different task everytime" do
			task1 = taskable.create_task_for_action('publish')
			task2 = taskable.create_task_for_action('publish')
			expect(taskable.tasks.size).to eq(2)
		end

		it "has the right taskable" do
			task = taskable.create_task_for_action('publish')
			expect(task.taskable).to eq(taskable)
		end

		it "returns the task with the right action" do
			task = taskable.create_task_for_action('publish')
			expect(task.action).to eq('publish')
		end

		it "calls task.refresh" do
			task = double.as_null_object
			task.should_receive(:refresh)
			taskable.tasks.stub(:create).and_return(task)
			task = taskable.create_task_for_action('publish')
		end

		it "calls task.on_creation" do
			task = double.as_null_object
			task.should_receive(:on_creation)
			taskable.tasks.stub(:create).and_return(task)
			task = taskable.create_task_for_action('publish')
		end
	end

	describe ".create_or_refresh_task_for_action" do
		it "uses an existing task if possible" do
			taskable.save
			taskable.create_task_for_action('publish')
			taskable.should_not_receive(:create_task_for_action)
			taskable.create_or_refresh_task_for_action('publish')
		end

		it "creates a new task if not there" do
			taskable.should_receive(:create_task_for_action)
			taskable.create_or_refresh_task_for_action('publish')
		end
	end

	describe ".tasks_for_action" do
		it "responds to tasks_for_action" do
			expect(taskable).to respond_to('tasks_for_action')
		end

		it "finds the tasks" do
			taskable.save
			task1 = taskable.tasks.create(action: 'create')
			task2 = taskable.tasks.create(action: 'update')

			expect(taskable.tasks_for_action('create')).to eq([task1])
		end
	end

	describe ".last_task_for_action" do
		it "responds to last_task_for_action" do
			expect(taskable).to respond_to('last_task_for_action')
		end

		it "finds the task" do
			taskable.save
			task1 = taskable.tasks.create(taskable: taskable, action: 'create')
			task2 = taskable.tasks.create(taskable: taskable, action: 'update')

			res = taskable.last_task_for_action('create')
			expect(res).to eq(task1)
		end

		it "returns nil if it cannot find the task" do
			res = taskable.last_task_for_action('create')
			expect(res).to be_nil
		end
	end

	describe ".task_assignments" do
		it "responds to task_assignments" do
			expect(taskable).to respond_to('task_assignments')
		end

		it "finds the assignments" do
			taskable.save
			task1 = taskable.tasks.create(taskable: taskable, action: 'create')
			task2 = taskable.tasks.create(taskable: taskable, action: 'update')
			task1.assignments.create
			task2.assignments.create
			expect(taskable.task_assignments.size).to eq(2)
		end
	end

	describe ".task_assignments_for_action" do
		it "responds to task_assignments_for_action" do
			expect(taskable).to respond_to('task_assignments_for_action')
		end

		it "finds the assignments" do
			taskable.save
			task1 = taskable.tasks.create(action: 'publish')
			task2 = taskable.tasks.create(action: 'submit')
			task1.assignments.create
			task2.assignments.create
			res = taskable.task_assignments_for_action('publish')
			expect(res.size).to eq(1)
		end

		it "returns an empty array if if cannot find the task" do
			res = taskable.task_assignments_for_action('review')
			expect(res).to be_empty
		end
	end

	describe ".task_assignment_for" do
		it "requires an assignee" do
			expect{ taskable.task_assignment_for('publish') }.to raise_error(ArgumentError)
		end

		it "calls assignment_for on task" do
			task.should_receive(:assignment_for).with(assignee)
			taskable.stub(:last_task_for_action).and_return(task)
			taskable.task_assignment_for('publish', assignee)
		end

		it "returns nil if if cannot find the task" do
			res = taskable.task_assignment_for('publish', assignee)
			expect(res).to be_nil
		end
	end

	describe ".complete_task_for_action" do

		it "requires an action" do
			expect{ taskable.complete_task_for_action }.to raise_error(ArgumentError)
		end

		it "calls complete! on the task" do
			task = double.as_null_object
			task.should_receive(:complete!)
			taskable.stub(:last_task_for_action).and_return(task)
			taskable.complete_task_for_action('publish')
		end

		it "return true" do
			task = double.as_null_object
			task.stub(:complete!).and_return(true)
			taskable.stub(:last_task_for_action).and_return(task)
			res = taskable.complete_task_for_action('publish')
			expect(res).to be_true
		end

		it "returns false if it cannot find the task" do
			res = taskable.complete_task_for_action('publish')
			expect(res).to be_false
		end
	end

	describe ".complete_task_for" do

		it "requires an assignee" do
			expect{ taskable.complete_task_for('publish') }.to raise_error(ArgumentError)
		end

		it "calls complete_by on task" do
			task.should_receive(:complete_by).with(assignee)
			taskable.stub(:last_task_for_action).and_return(task)
			taskable.complete_task_for('publish', assignee)
		end

		it "returns true" do
			task.stub(:complete_by).and_return(true)
			taskable.stub(:last_task_for_action).and_return(task)
			res = taskable.complete_task_for('publish', assignee)
			expect(res).to be_true
		end

		it "returns false if it cannot find the task" do
			res = taskable.complete_task_for('publish', assignee)
			expect(res).to be_false
		end
	end

	describe ".complete_tasks_for_action" do
		it "returns false if it cannot find any tasks" do
			res = taskable.complete_tasks_for_action('review')
			expect(res).to be_false
		end

		it "sends complete! to all tasks" do
			task1 = double.as_null_object
			task2 = double.as_null_object
			task1.should_receive(:complete!)
			task2.should_receive(:complete!)
			tasks = [task1, task2]
			taskable.stub(:current_tasks_for_action).and_return(tasks)
			res = taskable.complete_tasks_for_action('review')
		end
	end

	describe ".expire_tasks_for_action" do
		it "returns false if it cannot find any tasks" do
			res = taskable.expire_tasks_for_action('review')
			expect(res).to be_false
		end

		it "sends expire to all tasks" do
			task1 = double.as_null_object
			task2 = double.as_null_object
			task1.should_receive(:expire)
			task2.should_receive(:expire)
			tasks = [task1, task2]
			taskable.stub(:current_tasks_for_action).and_return(tasks)
			res = taskable.expire_tasks_for_action('review')
		end
	end

end
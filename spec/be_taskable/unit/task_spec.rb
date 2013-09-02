require File.expand_path('../../../spec_helper', __FILE__)

describe 'BeTaskable::Task' do

	let(:assignee) { stub_model(User) }
	let(:resolver) { double.as_null_object }
	let(:assignment) { double.as_null_object }
	let(:taskable) { Taskable.create }
	let(:action) { 'Publish' }
	let(:task) { BeTaskable::Task.new(taskable: taskable, action: action) }
	let(:runner) { double.as_null_object }

	before do
		task.stub(:resolver).and_return(resolver)
		resolver.stub(:label_for_task).and_return('Label for task')
	end

	describe "#completed" do
		it "finds completed tasks" do
			task1 = BeTaskable::Task.create(taskable: taskable, action: 'update', completed_at: DateTime.now)
			task2 = BeTaskable::Task.create(taskable: taskable, action: 'review')
			res = BeTaskable::Task.completed.all
			expect(res).to eq([task1])
		end
	end

	describe "#uncompleted" do
		it "finds uncompleted tasks" do
			task1 = BeTaskable::Task.create(taskable: taskable, action: 'update', completed_at: DateTime.now)
			task2 = BeTaskable::Task.create(taskable: taskable, action: 'review')
			res = BeTaskable::Task.uncompleted.all
			expect(res).to eq([task2])
		end
	end

	describe "#expired" do
		it "finds expired tasks" do
			task1 = BeTaskable::Task.create(taskable: taskable, action: 'update', expired_at: DateTime.now)
			task2 = BeTaskable::Task.create(taskable: taskable, action: 'review')
			res = BeTaskable::Task.expired.all
			expect(res).to eq([task1])
		end
	end

	describe "#unexpired" do
		it "finds unexpired tasks" do
			task1 = BeTaskable::Task.create(taskable: taskable, action: 'update', expired_at: DateTime.now)
			task2 = BeTaskable::Task.create(taskable: taskable, action: 'review')
			# expect(task1).to be_persisted
			# expect(task2).to be_persisted
			res = BeTaskable::Task.unexpired.all
			expect(res).to eq([task2])
		end
	end

	describe "#current" do
		it "finds current tasks" do
			task1 = BeTaskable::Task.create(taskable: taskable, action: 'update', expired_at: DateTime.now)
			task2 = BeTaskable::Task.create(taskable: taskable, action: 'update', completed_at: DateTime.now)
			task3 = BeTaskable::Task.create(taskable: taskable, action: 'review')
			res = BeTaskable::Task.current.all
			expect(res).to eq([task3])
		end
	end

	describe "validations" do
		it "can create two task with the same taskable and action" do
			taskable = Taskable.create
			action = 'publish'
			task1 = BeTaskable::Task.create(taskable: taskable, action: action)
			task2 = BeTaskable::Task.create(taskable: taskable, action: action)

			expect(task2.errors).to be_empty
		end
	end

	it "can save the task" do
		task.save
		expect(task).to be_persisted
	end

	describe ".taskable" do
		it "responds to taskable" do
			expect(task).to respond_to('taskable')
		end

		it "finds taskable" do
			taskable = Taskable.create
			task = taskable.tasks.create
			expect(task.taskable).to eq(taskable)
		end
	end

	describe ".assignments" do
		it 'responds to assignments' do
			expect(task).to respond_to('assignments')
		end
	end

	describe ".assignees" do
		it "responds to assignees" do
			expect(task).to respond_to('assignees')
		end

		it "finds the assignees" do
			user = User.create
			task.save
			task.assignments.create(assignee: user)
			
			expect(task.assignees).to eq([user])
		end
	end

	describe ".resolver" do

		before do
			task.unstub(:resolver)
		end

		it "asks the taskable for the resolver" do
			taskable.should_receive(:task_resolver_for_action)
			task.resolver
		end
	end

	describe "._runner" do
		it "returns a runner" do
			res = task._runner
			expect(res).to be_instance_of(BeTaskable::TaskRunner)
		end
	end

	describe ".refresh" do

		before do			
			task.stub(:_runner).and_return(runner)
		end

		it "calls the runner" do
			runner.should_receive(:refresh)
			task.refresh
		end

		it "doesnt run for completed task" do
			task.stub(:state).and_return('completed')
			runner.should_not_receive(:refresh)
			task.refresh
		end

		it "runs for open task" do
			task.stub(:state).and_return('open')
			runner.should_receive(:refresh)
			task.refresh
		end

		it "runs for irrelevant task" do
			task.stub(:state).and_return('irrelevant')
			runner.should_receive(:refresh)
			task.refresh
		end
	end

	describe ".audit" do

		before do
			task.save
		end

		it "calls refresh" do
			task.should_receive(:refresh)
			task.audit
		end

		it "calls tally" do
			# puts task.inspect
			task.should_receive(:tally)
			task.audit
		end

		it "doesnt run for completed task" do
			task.stub(:state) { 'completed' }
			task.should_not_receive(:refresh)
			task.audit
		end

		it "runs for open task" do
			task.stub(:state) { 'open' }
			task.should_receive(:refresh)
			task.audit
		end

		it "runs for irrelevant task" do
			task.stub(:state) { 'irrelevant' }
			task.should_receive(:refresh)
			task.audit
		end
	end

	describe ".consensus?" do
		before do
			task.stub(:resolver).and_return(resolver)
		end

		it "ask the resolver for consensus?" do
			resolver.should_receive(:consensus?)
			task.consensus?
		end

		it "pases the task to the resolver" do
			# assignments = [1,2]
			# task.stub(:assignments).and_return(assignments)
			resolver.should_receive(:consensus?).with(task)
			task.consensus?
		end
	end

	describe ".tally" do
		it "doesnt do anything is already completed" do
			task.update_attribute(:state, 'completed')
			task.stub(:consensus?).and_return(true)
			task.should_not_receive(:_on_completion)
			task.tally
		end

		it "calls on_completion when completed" do
			task.stub(:consensus?).and_return(true)
			task.should_receive(:_on_completion)
			task.tally
		end

		it "doesn't call _on_completion if not completed" do
			task.stub(:consensus?).and_return(false)
			task.should_not_receive(:_on_completion)
			task.tally
		end

		it "doesnt run for completed task" do
			task.stub(:state) { 'completed' }
			task.should_not_receive(:complete)
			task.tally
		end

		it "runs for open task" do
			task.stub(:state) { 'open' }
			task.should_receive(:complete)
			task.tally
		end

		it "runs for irrelevant task" do
			task.stub(:state) { 'irrelevant' }
			task.should_receive(:complete)
			task.tally
		end
	end

	describe ".on_creation" do
		it "calls the resolver" do
			resolver.should_receive(:on_creation).with(task)
			task.on_creation
		end
	end

	describe ".complete" do
		it "changes the state" do
			task.complete
			expect(task).to be_completed
		end

		it "calls _on_completion" do
			task.should_receive(:_on_completion)
			task.complete
		end

		it "returns true" do
			res = task.complete
			expect(res).to be_true
		end
	end

	describe "._on_completion" do
		before do
			task.stub(:resolver).and_return(resolver)
		end

		it "changes completed_at  on the tasks" do
			task._on_completion
			expect(task.completed_at).to be_within(1.minute).of(DateTime.now)
		end

		it "calls on_completion on the resolver" do
			resolver.should_receive(:on_completion)
			task._on_completion
		end

		it "marks all assignments as completed" do
			task.save
			a1 = task.assignments.create()
			a2 = task.assignments.create()
			task._on_completion
			a1.reload
			a2.reload
			expect(a1).to be_completed
			expect(a2).to be_completed
		end
	end

	describe "assignment_for" do
		it "find the assignment for the assignee" do
			task.save
			assignment = task.assignments.create(assignee: assignee)
			res = task.assignment_for(assignee)
			expect(res).to eq(assignment)
		end
	end

	describe ".complete_by" do

		let(:assignment) { double.as_null_object }

		before do
			task.stub(:assignment_for).and_return(assignment)
		end

		it "requires an assignee" do
			expect{ task.complete_by }.to raise_error(ArgumentError)
		end

		it "sends complete to the assignment" do
			assignment.should_receive(:complete)
			task.complete_by(assignee)
		end

		it "returns true" do
			res = task.complete_by(assignee)
			expect(res).to be_true
		end

		it "returns false if it cannot find the assignment" do
			task.stub(:assignment_for).and_return(nil)
			res = task.complete_by(assignee)
			expect(res).to be_false
		end
	end

	describe ".expire" do
		it "marks the task as expired" do
			# expect(task).to be_open
			res = task.expire
			# expect(res).to be_true
			# puts task.state
			# task.reload
			expect(task).to be_expired
		end

		it "calls _on_expiration" do
			task.should_receive(:_on_expiration)
			task.expire
		end
	end

	describe "._on_expiration" do

		it "sets the expired date" do
			task.expire
			expect(task.expired_at).to be_within(1.minute).of(DateTime.now)
		end

		it "marks the assignments as expired" do
			task.stub(:assignments).and_return([assignment])
			assignment.should_receive(:expire)
			task._on_expiration
		end

		it "calls on_expiration on the resolver" do
			resolver.should_receive(:on_expiration)
			task._on_expiration
		end
	end

	describe ".on_assignment_completed" do
		it "triggers a tally" do
			task.should_receive(:tally)
			task.on_assignment_completed(assignment)
		end
	end

	describe ".label!" do
		it "asks the resolver" do
			resolver.should_receive(:label_for_task)
			task.label!
		end
	end

	describe "consensus helpers" do

		let(:assignment1) { stub_model(BeTaskable::TaskAssignment) }
		let(:assignment2) { stub_model(BeTaskable::TaskAssignment) }
		let(:assignment3) { stub_model(BeTaskable::TaskAssignment) }
		let(:assignment4) { stub_model(BeTaskable::TaskAssignment) }
		let(:assignments) { [assignment1, assignment2, assignment3, assignment4] }

		before do
			task.stub(:assignments).and_return(assignments)
		end

		describe ".majority_of_assignments_done?" do

			it "is not true if minority done" do
				assignment1.stub(:completed?).and_return(true)
				res = task.majority_of_assignments_done?
				expect(res).to be_false
			end

			it "is not true if half done" do
				assignment1.stub(:completed?).and_return(true)
				assignment2.stub(:completed?).and_return(true)
				res = task.majority_of_assignments_done?
				expect(res).to be_false
			end

			it "is true if majority done" do
				assignment1.stub(:completed?).and_return(true)
				assignment2.stub(:completed?).and_return(true)
				assignment3.stub(:completed?).and_return(true)
				res = task.majority_of_assignments_done?
				expect(res).to be_true
			end

		end

		describe ".any_assignment_done?" do

			it "is not false if none done" do
				res = task.any_assignment_done?
				expect(res).to be_false
			end

			it "is not true if one is done" do
				assignment1.stub(:completed?).and_return(true)
				res = task.any_assignment_done?
				expect(res).to be_true
			end

			it "is not true if more than one is done" do
				assignment1.stub(:completed?).and_return(true)
				assignment2.stub(:completed?).and_return(true)
				res = task.any_assignment_done?
				expect(res).to be_true
			end
		end

		describe ".all_assignments_done?" do

			it "is not false if none done" do
				res = task.all_assignments_done?
				expect(res).to be_false
			end

			it "is not false if majority done" do
				assignment1.stub(:completed?).and_return(true)
				assignment2.stub(:completed?).and_return(true)
				assignment3.stub(:completed?).and_return(true)
				res = task.all_assignments_done?
				expect(res).to be_false
			end

			it "is not true if all done" do
				assignment1.stub(:completed?).and_return(true)
				assignment2.stub(:completed?).and_return(true)
				assignment3.stub(:completed?).and_return(true)
				assignment4.stub(:completed?).and_return(true)
				res = task.all_assignments_done?
				expect(res).to be_true
			end
		end
	end

	describe ".enacted_assignments" do
		it "returns the assignees that actually did the task" do
			user1 = User.create
			user2 = User.create
			task.save
			as1 = task.assignments.create(assignee: user1)
			as2 = task.assignments.create(assignee: user2, enacted: true)
			res = task.enacted_assignments
			expect(res).to eq([as2])
		end
	end

end
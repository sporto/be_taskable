require File.expand_path('../../../spec_helper', __FILE__)

describe 'BeTaskable::TaskRunner' do

	let(:resolver) { double.as_null_object }
	let(:taskable) { stub_model(Taskable) }
	let(:task) { BeTaskable::Task.new(taskable: taskable, action: 'review') }
	let(:runner) { BeTaskable::TaskRunner.new(task) }
	let(:assignee1) { stub_model(User) }
	let(:assignee2) { stub_model(User) }
	let(:assignee3) { stub_model(User) }
	let(:assignees) { [assignee1, assignee2] }
	let(:label_for_assigment) { 'Label for assignment' }
	let(:url_for_assignment) { '/url/for/assignment' }

	before do
		resolver.stub(:due_date_for_assignment).and_return(DateTime.now)
		resolver.stub(:visible_date_for_assignment).and_return(DateTime.now)
		resolver.stub(:label_for_task).and_return('Label for task')
		resolver.stub(:label_for_assignment).and_return(label_for_assigment)
		resolver.stub(:url_for_assignment).and_return(url_for_assignment)
		runner.stub(:resolver).and_return(resolver)
		runner.stub(:_tally)
	end

	describe "initialize" do
		it "requires a task" do
			expect{ BeTaskable::TaskRunner.new }.to raise_error(ArgumentError)
		end

		it "requires a task" do
			expect{ BeTaskable::TaskRunner.new(2) }.to raise_error(ArgumentError)
		end

		it "requires a task" do
			expect{ BeTaskable::TaskRunner.new(task) }.not_to raise_error
		end

	end

	describe ".resolver" do
		it "asks the task for the resolver" do
			runner.unstub(:resolver)
			task.should_receive(:resolver)
			runner.resolver
		end
	end

	describe "._assignees" do
		it "asks the resolver for the assignees" do
			# runner.stub(:resolver).and_return(resolver)
			resolver.should_receive(:assignees_for_task)
			runner._assignees
		end
	end

	describe ".refresh" do

		before do
			task.save
			runner.stub(:_assignees).and_return(assignees)
		end

		it "asks the resolver for relevant status of the task" do
			resolver.should_receive(:is_task_relevant?)
			runner.refresh
		end

		it "sets the label on the task" do
			l = "Label"
			resolver.stub(:label_for_task).and_return(l)
			runner.refresh
			expect(task.label).to eq(l)
		end

		it "creates an assignment for all assignees" do
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
		end

		it "asks the resolver for the due date" do
			resolver.should_receive(:due_date_for_assignment)
			runner.refresh
		end

		it "sets the complete_by as given by the resolver" do
			d = DateTime.now + 3.days
			resolver.stub(:due_date_for_assignment).and_return(d)
			runner.refresh
			assignment = BeTaskable::TaskAssignment.first
			expect(assignment.complete_by).to be_within(1.minute).of(d)
		end

		it "asks the resolver for the visible at date" do
			resolver.should_receive(:visible_date_for_assignment)
			runner.refresh
		end

		it "sets the visible_at as given by the resolver" do
			d = DateTime.now + 3.days
			resolver.stub(:visible_date_for_assignment).and_return(d)
			runner.refresh
			assignment = BeTaskable::TaskAssignment.first
			expect(assignment.visible_at).to be_within(1.minute).of(d)
		end

		it "sets the assignment label as given by the resolver" do
			runner.refresh
			assignment = BeTaskable::TaskAssignment.first
			expect(assignment.label).to eq(label_for_assigment)
		end

		it "sets the assignment url as given by the resolver" do
			runner.refresh
			assignment = BeTaskable::TaskAssignment.first
			expect(assignment.url).to eq(url_for_assignment)
		end

		it "doesn't create duplicate assignments" do
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
		end

		it "deletes an assignment when not relevant anymore" do
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
			assignees.pop
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(1)
		end

		it "creates new assignment if needed" do
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
			assignees.push(assignee3)
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(3)
		end

		it "doesn't delete completed assignments" do
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
			BeTaskable::TaskAssignment.last.update_attribute(:completed_at, DateTime.now)
			assignees.pop
			runner.refresh
			expect(BeTaskable::TaskAssignment.count).to eq(2)
		end

		it "marks the task as irrelevant if taskable cannot be found" do
			task.stub(:taskable){ nil }
			runner.refresh
			expect(task).to be_irrelevant
		end

		context 'irrelevant task' do
			before do
				# task.save
				puts task.errors.full_messages
				resolver.stub(:is_task_relevant?).and_return(false)
			end

			# it "is persisted" do
			# 	expect(task).to be_persisted
			# end

			it "marks the task as irrelevant" do
				# task.should_receive(:make_irrelevant)

				runner.refresh
				expect(task).to be_irrelevant
			end

			it "deletes the existing assignments" do
				task.assignments.create
				expect(task.assignments.size).to eq(1)
				runner.refresh
				expect(task.assignments.size).to eq(0)
			end

			it "doesn't change the state of an already completed task" do
				task.update_attribute(:state, 'completed')
				task.should_not_receive(:make_irrelevant)
				runner.refresh
			end

			it "doesn't delete assignments on an already completed task" do
				task.update_attribute(:state, 'completed')
				task.assignments.create
				expect(task.assignments.size).to eq(1)
				runner.refresh
				expect(task.assignments.size).to eq(1)
			end

		end

	end

end
require File.expand_path('../../../spec_helper', __FILE__)

describe 'End to End' do

	let(:user1) { User.create }
	let(:user2) { User.create }
	let(:user3) { User.create }
	let(:assignees) { [user1, user2] }
	let(:taskable) { Taskable.create }
	let(:resolver) { TaskableReviewTaskResolver.new }

	before do
		user1
		user2
		user3

		resolver.stub(:assignees_for_task).and_return(assignees)

		TaskableReviewTaskResolver.stub(:new).and_return(resolver)
	end

	# Create a task
	# make sure assignees are assigned
	# complete an assignment
	# complete another assignment (that triggers consensus)
	# task should be completed
	it 'works' do
		# resolver should receive on_creation when a task is created
		resolver.should_receive(:on_creation)

		task = taskable.create_task_for_action('review')

		# there should be two assigments now
		expect(BeTaskable::TaskAssignment.count).to eq(2)

		# add more assignees
		assignees.push(user3)

		# task should have a label provided by the resolver
		expect(task.label).to eq("Task label #{task.id}")

		task.refresh

		# there should be 3 assigments now
		expect(BeTaskable::TaskAssignment.count).to eq(3)

		# assignment should have a label provided by the resolver
		assignment = BeTaskable::TaskAssignment.first
		expect(assignment.label).to eq("Assignment label #{assignment.id}")

		# assignment should have a url provided by the resolver
		expect(assignment.url).to eq("Assignment url #{assignment.id}")

		# assignment should have due date as provided by the resolver
		expect(assignment.complete_by).to be_within(1.minute).of(DateTime.now + 10.days)

		# complete the task for one of the assignees
		taskable.complete_task_for('review', user1)

		# the task should still be uncompleted
		expect(task).not_to be_completed

		# change the consensus
		resolver.stub(:consensus?).and_return true

		# the resolver shoud receive on_completion
		resolver.should_receive(:on_completion)

		# complete another task
		taskable.complete_task_for('review', user2)

		# task should be completed
		task.reload
		# puts task.state
		# puts task.assignments.inspect
		expect(task).to be_completed
	end

end
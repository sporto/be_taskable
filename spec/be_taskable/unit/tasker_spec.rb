require File.expand_path('../../../spec_helper', __FILE__)

describe 'BeTaskable::Tasker' do

	let(:user) { User.new }
	let(:task) { BeTaskable::Task.new }

	it "responds to tasker?" do
		expect(user).to be_tasker
	end

	it "responds to task_assignments" do
		expect(user).to respond_to(:task_assignments)
	end

	it "has task assignments" do
		user.save
		task.save
		assignment = BeTaskable::TaskAssignment.create(task: task, assignee: user)

		expect(user.task_assignments.size).to eq(1)
	end

end
require File.expand_path('../../../spec_helper', __FILE__)

describe "Irrelevance" do 

	let(:user1) { User.create }
	let(:user2) { User.create }
	let(:assignees) { [user1, user2] }
	let(:taskable) { Taskable.create }
	let(:resolver) { TaskableReviewTaskResolver.new }
	let(:task) { taskable.create_task_for_action('review') }

	before do
		user1
		user2

		resolver.stub(:assignees_for_task).and_return(assignees)
		TaskableReviewTaskResolver.stub(:new).and_return(resolver)

		task
	end

	it "works" do
		#################################################
		# "creates the assigments when relevant"
			expect(task).to be_open

			# there should be two assigments now
			expect(BeTaskable::TaskAssignment.count).to eq(2)

		#################################################
		# "deletes the assignments when irrelevant"
			# expect(BeTaskable::TaskAssignment.count).to eq(2)

			# make the task irrelevant
			resolver.stub(:is_task_relevant?).and_return(false)

			task.refresh

			expect(task).to be_irrelevant
			expect(BeTaskable::TaskAssignment.count).to eq(0)

		#################################################
		# "recreates the assignments when relevant again"

			# make task relevant again
			resolver.unstub(:is_task_relevant?)

			task.refresh

			expect(task).to be_open
			# there should be two assigments now
			expect(BeTaskable::TaskAssignment.count).to eq(2)
		
		#################################################
		# "doesnt delete already completed assignments"

			expect(BeTaskable::TaskAssignment.count).to eq(2)

			resolver.stub(:is_task_relevant?).and_return(false)
			resolver.stub(:consensus?).and_return(false)

			BeTaskable::TaskAssignment.first.complete
			
			task.refresh

			expect(BeTaskable::TaskAssignment.count).to eq(1)
		
	end
	
end
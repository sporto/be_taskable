require File.expand_path('../../../spec_helper', __FILE__)

describe 'BeTaskable::TaskAssignment' do

	let(:task) { double.as_null_object }
	let(:resolver) { double.as_null_object }
	let(:assignment) { BeTaskable::TaskAssignment.new }

	before do
		assignment.stub(:task).and_return(task)
		assignment.stub(:resolver).and_return(resolver)
	end

	describe "#completed" do
		it "finds the completed" do
			a1 = BeTaskable::TaskAssignment.create(completed_at: DateTime.now)
			a2 = BeTaskable::TaskAssignment.create()
			res = BeTaskable::TaskAssignment.completed.all
			expect(res).to eq([a1])
		end
	end

	describe "#uncompleted" do
		it "finds the uncompleted" do
			a1 = BeTaskable::TaskAssignment.create(completed_at: DateTime.now)
			a2 = BeTaskable::TaskAssignment.create()
			res = BeTaskable::TaskAssignment.uncompleted.all
			expect(res).to eq([a2])
		end
	end

	describe "#overdue" do
		it "finds the overdue" do
			a1 = BeTaskable::TaskAssignment.create(complete_by: DateTime.now - 1.day)
			a2 = BeTaskable::TaskAssignment.create(complete_by: DateTime.now + 1.day)
			a3 = BeTaskable::TaskAssignment.create()
			res = BeTaskable::TaskAssignment.overdue.all
			expect(res).to eq([a1])
		end
	end

	describe "#not_overdue" do
		it "finds the not_overdue" do
			a1 = BeTaskable::TaskAssignment.create(complete_by: DateTime.now - 1.day)
			a2 = BeTaskable::TaskAssignment.create(complete_by: DateTime.now + 1.day)
			a3 = BeTaskable::TaskAssignment.create()
			res = BeTaskable::TaskAssignment.not_overdue.all
			expect(res).to eq([a2, a3])
		end
	end

	describe "#visible" do
		it "finds the visible" do
			a1 = BeTaskable::TaskAssignment.create(visible_at: DateTime.now - 1.day)
			a2 = BeTaskable::TaskAssignment.create()
			a3 = BeTaskable::TaskAssignment.create(visible_at: DateTime.now + 1.day)
			res = BeTaskable::TaskAssignment.visible.all
			expect(res).to eq([a1, a2])
		end
	end

	describe "#expired" do
		it "finds the expired" do
			a1 = BeTaskable::TaskAssignment.create(expired_at: DateTime.now - 1.day)
			a2 = BeTaskable::TaskAssignment.create()
			res = BeTaskable::TaskAssignment.expired.all
			expect(res).to eq([a1])
		end
	end

	describe "#unexpired" do
		it "finds the unexpired" do
			a1 = BeTaskable::TaskAssignment.create(expired_at: DateTime.now - 1.day)
			a2 = BeTaskable::TaskAssignment.create()
			res = BeTaskable::TaskAssignment.unexpired.all
			expect(res).to eq([a2])
		end
	end

	describe "#current" do

		let(:a1) { BeTaskable::TaskAssignment.create() }
		let(:a2) { BeTaskable::TaskAssignment.create(expired_at: DateTime.now - 1.day) }
		let(:a3) { BeTaskable::TaskAssignment.create(complete_by: DateTime.now - 1.day) }
		let(:a4) { BeTaskable::TaskAssignment.create(complete_by: DateTime.now + 1.day) }
		let(:a5) { BeTaskable::TaskAssignment.create(completed_at: DateTime.now - 1.day) }
		let(:a6) { BeTaskable::TaskAssignment.create(visible_at: DateTime.now + 1.day) }

		before do
			a1;a2;a3;a4;a5;a6
		end

		it "finds them" do
			res = BeTaskable::TaskAssignment.current.all
			expect(res).to eq([a1, a4])
		end

		it "doesnt find expired" do
			res = BeTaskable::TaskAssignment.current.all
			expect(res).not_to include(a2)
		end

		it "doesnt find overdue" do
			res = BeTaskable::TaskAssignment.current.all
			expect(res).not_to include(a3)
		end

		it "doesnt find completed" do
			res = BeTaskable::TaskAssignment.current.all
			expect(res).not_to include(a5)
		end

		it "doesnt find invisibles" do
			res = BeTaskable::TaskAssignment.current.all
			expect(res).not_to include(a6)
		end

	end

	describe ".taskable" do
		it "ask the task" do
			task.should_receive(:taskable)
			assignment.taskable
		end
	end

	describe ".resolver" do
		it 'asks the task' do
			assignment.unstub(:resolver)
			task.should_receive(:resolver)
			assignment.resolver
		end
	end

	describe ".complete" do
		it 'sets the completed_at' do
			assignment.complete
			expect(assignment.completed_at).to be_within(1.minute).of(DateTime.now)
		end

		it "calls on_assignment_completed on task" do
			task.should_receive(:on_assignment_completed).with(assignment)
			assignment.complete
		end

		it "returns true" do
			res = assignment.complete
			expect(res).to be_true
		end

		it "returns false if assignment has already been completed" do
			assignment.update_attribute(:completed_at, DateTime.now)
			res = assignment.complete
			expect(res).to be_false
		end

		it "sets an errors array if it returns false" do
			assignment.update_attribute(:completed_at, DateTime.now)
			res = assignment.complete
			expect(res).to be_false
			#expect(res.errors.size).not_to be_empty
		end

		it "sets enacted" do
			res = assignment.complete
			# assignment.reload
			expect(assignment).to be_enacted
		end
	end

	describe ".label!" do
		it "asks the resolver" do
			resolver.should_receive(:label_for_assignment)
			assignment.label!
		end
	end

	describe ".url!" do
		it "asks the resolver" do
			resolver.should_receive(:url_for_assignment)
			assignment.url!
		end
	end

end
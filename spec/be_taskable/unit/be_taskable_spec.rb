require File.expand_path('../../../spec_helper', __FILE__)

describe 'BeTaskable' do

	describe "#be_taskable" do

		it "should provide a class method be_taskable" do
			expect(ActiveRecord::Base).to respond_to('be_taskable')
		end

		it "should provide a class method be_tasker" do
			expect(ActiveRecord::Base).to respond_to('be_tasker')
		end

	end

end
require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class TestAController
  include Lockdown::Session
end

describe Lockdown::Session do
  before do
    @controller = TestAController.new

    @actions = %w(posts/index posts/show posts/new posts/edit posts/create posts/update posts/destroy)

    @session = {:access_rights => @actions}

    @controller.stub!(:session).and_return(@session)
  end

  describe "#nil_lockdown_values" do
  end

  describe "#current_user_access_in_group?" do
    it "should return true if current user is admin" do
      @actions = :all
      @session = {:access_rights => @actions}
      @controller.stub!(:session).and_return(@session)

      @controller.current_user_access_in_group?(:group).should == true
    end
  end

  describe "#current_user_is_admin?" do
    it "should return true if access_rights == :all" do
      @actions = :all
      @session = {:access_rights => @actions}
      @controller.stub!(:session).and_return(@session)

      @controller.current_user_is_admin?.should == true
    end
  end

  describe "#nil_lockdown_values" do
  end

  describe "#nil_lockdown_values" do
  end

  describe "#nil_lockdown_values" do
  end
end

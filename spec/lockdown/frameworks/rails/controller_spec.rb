require File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper])

class TestAController
  extend Lockdown::Frameworks::Rails::Controller
  include Lockdown::Frameworks::Rails::Controller::Lock::InstanceMethods
end

describe Lockdown::Frameworks::Rails::Controller do
  before do
    @controller = TestAController

    @actions = %w(posts/index posts/show posts/new posts/edit posts/create posts/update posts/destroy)

    #@controller.stub!(:available_actions).with(:posts).and_return(@actions)

    @lockdown = mock("lockdown")
  end

  describe "#available_actions" do
    it "should return action_methods" do
      post_controller = mock("PostController")
      post_controller.stub!(:action_methods).and_return(@actions)

      @controller.available_actions(post_controller).
        should == @actions
    end
  end

  describe "#controller_name" do
    it "should return action_methods" do
      post_controller = mock("PostController")
      post_controller.stub!(:controller_name).and_return("PostController")

      @controller.controller_name(post_controller).should == "PostController"
    end
  end

end

describe Lockdown::Frameworks::Rails::Controller::Lock do
  before do
    @controller = TestAController.new
  end
  
  describe "#configure_lockdown" do
    it "should call check_session_expiry and store_location" do
      @controller.should_receive(:check_session_expiry)
      @controller.should_receive(:store_location)

      @controller.configure_lockdown
    end
  end
end

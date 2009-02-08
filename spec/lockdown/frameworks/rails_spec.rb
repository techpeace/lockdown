require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Lockdown::Frameworks::Rails do
  before do
    @rails = Lockdown::Frameworks::Rails
    @rails.stub!(:use_me?).and_return(true)

    @lockdown = mock("lockdown")
  end


  describe "#included" do
    it "should extend lockdown with rails environment" do
      @lockdown.should_receive(:extend).
        with(Lockdown::Frameworks::Rails::Environment)

      @rails.should_receive(:mixin)

      @rails.included(@lockdown)
    end
  end

  describe "#mixin" do
    it "should perform class_eval on controller view and system to inject itself" do
      mod = mock("rails specific functionality")

      Lockdown.stub!(:controller_parent).and_return(mod)
      Lockdown.stub!(:view_helper).and_return(mod)

      Lockdown::System.should_receive(:class_eval)

      mod.should_receive(:class_eval).twice

      @rails.mixin
    end
  end
end

describe Lockdown::Frameworks::Rails::Environment do

  RAILS_ROOT = "/shibby/dibby/do"
  before do
    @env = class Test; extend Lockdown::Frameworks::Rails::Environment; end
  end

  describe "#project_root" do
    it "should return rails root" do
      @env.project_root.should == "/shibby/dibby/do"
    end
  end

  describe "#init_file" do
    it "should return path to init_file" do
      @env.stub!(:project_root).and_return("/shibby/dibby/do")
      @env.init_file.should == "/shibby/dibby/do/lib/lockdown/init.rb"
    end
  end

  describe "#controller_class_name" do
    it "should add Controller to name" do
      @env.controller_class_name("user").should == "UserController"
    end

    it "should convert two underscores to a namespaced controller" do
      @env.controller_class_name("admin__user").should == "Admin::UserController"
    end
  end

  describe "#controller_parent" do
    it "should return ActionController::Base" do
      module ActionController; class Base; end end

      @env.controller_parent.should == ActionController::Base
    end
  end

  describe "#view_helper" do
    it "should return ActionView::Base" do
      module ActionView; class Base; end end
      
      @env.view_helper.should == ActionView::Base
    end
  end
end


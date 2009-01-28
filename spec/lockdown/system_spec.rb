require File.join(File.dirname(__FILE__), %w[.. spec_helper])
require File.join(File.dirname(__FILE__), %w[.. .. lib lockdown rules])

describe Lockdown::System do
  it "should require rights if version <= 0.7" do
    Lockdown.stub!(:version).and_return('0.7.1')
    Lockdown::Rights.should_receive(:extended).with(Lockdown::System)
    load File.join(File.dirname(__FILE__), %w[.. .. lib lockdown system.rb])
  end

  it "should require rules if version > 0.7" do
    Lockdown.stub!(:version).and_return('0.8.0')
    Lockdown::Rules.should_receive(:extended).with(Lockdown::System)
    require File.join(File.dirname(__FILE__), %w[.. .. lib lockdown system.rb])
  end

  it "should fetch the option" do
    Lockdown::System.options = {}
    Lockdown::System.options['test'] = "my test"
    Lockdown::System.fetch('test').should == "my test"
  end

  it "should fetch the controller class" do
    klass = mock("User Controller Class")
    Lockdown.stub!(:controller_class_name).and_return(:users)
    Lockdown::System.controller_classes = {}
    Lockdown::System.controller_classes[:users] = klass
    Lockdown::System.fetch_controller_class(:users).should equal(klass)
  end
end

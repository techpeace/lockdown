require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class TestSystem; extend Lockdown::Rules; end

describe Lockdown::Rules do
  before do
    @rules = TestSystem
    @rules.set_defaults
  end

  it "#set_permission should create and return a Permission object" do
    @rules.set_permission(:user_management).
      should == Lockdown::Permission.new(:user_management) 
  end

  it "#set_public_access should define the permission as public" do
    @rules.set_permission(:user_management)
    @rules.set_public_access(:user_management)
  end

  it "#set_public_access should define the permission as public" do
    @rules.set_permission(:user_management)
    @rules.set_public_access(:user_management)
  end
end

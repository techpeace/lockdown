require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe Lockdown::Permission do
  before do
    @user_paths = ["users/index", "users/show", "users/new", "users/edit", "users/create", "users/update", "users/destroy"]
    
    @permission = Lockdown::Permission.new(:user_management)
    @permission.stub!(:paths_for).and_return(@user_paths)
  end

  describe "#with_controller" do
    it "should set current_context to ControllerContext" do
      @permission.with_controller(:users)
      @permission.current_context.name.should equal(:users)
    end
  end

  describe "#only_methods" do
  end

  describe "#except_methods" do
  end

  describe "#to_model" do
  end

  describe "#where" do
  end

  describe "#equals" do
  end

  describe "#is_in" do
  end
end

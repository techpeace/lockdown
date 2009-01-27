require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe Lockdown::Permission do
  before do
    @user_paths = ["users/index", "users/show", "users/new", "users/edit", "users/create", "users/update", "users/destroy"]
    
    @permission = Lockdown::Permission.new(:user_management)
    @permission.stub!(:paths_for).and_return(@user_paths)
  end

  describe "#with_controller" do
    before do
      @permission.with_controller(:users)
    end

    it "should set current_context to ControllerContext" do
      @permission.current_context.name.should equal(:users)
    end

    it "should raise InvalidRuleContext trying to access methods out of context" do
      methods = [:where, :equals, :is_in, :includes]

      methods.each do |method|
        lambda{@permission.send(method, :sample_param)}.
          should raise_error(Lockdown::InvalidRuleContext)
      end
    end
  end

  describe "#only_methods" do
  end

  describe "#except_methods" do
  end

  describe "#to_model" do
    before do
      @permission.to_model(:user)
    end

    it "should raise InvalidRuleContext trying to access methods out of context" do
      methods = [:with_controller, :and_controller, :equals, :is_in, :includes]

      methods.each do |method|
        lambda{@permission.send(method, :sample_param)}.
          should raise_error(Lockdown::InvalidRuleContext)
      end
    end
  end

  describe "#where" do
    before do
      @permission.to_model(:user).where(:current_user_id)
    end

    it "should raise InvalidRuleContext trying to access methods out of context" do
      methods = [:with_controller, :and_controller, :to_model]

      methods.each do |method|
        lambda{@permission.send(method, :sample_param)}.
          should raise_error(Lockdown::InvalidRuleContext)
      end
    end
  end

  describe "#equals" do
    before do
      @permission.to_model(:user).where(:current_user_id).equals(:id)
    end

    it "should raise InvalidRuleContext trying to access methods out of context" do
      methods = [:where, :equals, :is_in, :includes]

      methods.each do |method|
        lambda{@permission.send(method, :sample_param)}.
          should raise_error(Lockdown::InvalidRuleContext)
      end
    end
  end

  describe "#is_in" do
    before do
      @permission.to_model(:user).where(:current_user_id).is_in(:manager_ids)
    end

    it "should raise InvalidRuleContext trying to access methods out of context" do
      methods = [:where, :equals, :is_in, :includes]

      methods.each do |method|
        lambda{@permission.send(method, :sample_param)}.
          should raise_error(Lockdown::InvalidRuleContext)
      end
    end
  end
end

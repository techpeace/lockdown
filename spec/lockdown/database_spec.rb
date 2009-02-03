require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe Lockdown::Database do
  before do
    Lockdown::System.stub!(:get_permissions).and_return([:permission])
    Lockdown::System.stub!(:get_user_groups).and_return([:user_group])
  end

  describe "#sync_with_db" do
    it "should call create_new_permissions, delete_extince_permissions and maintain_user_groups" do
      Lockdown::Database.should_receive :create_new_permissions
      Lockdown::Database.should_receive :delete_extinct_permissions
      Lockdown::Database.should_receive :maintain_user_groups

      Lockdown::Database.sync_with_db
    end
  end

  describe "#create_new_permissions" do
    it "should create permission from @permissions" do
      Lockdown::System.stub!(:permission_assigned_automatically?).and_return(false)

      Permission = mock('Permission')
      Permission.stub!(:find).and_return(false)
      Permission.should_receive(:create).with(:name => 'Permission')

      Lockdown::Database.create_new_permissions
    end
  end

  describe "#delete_extinct_permissions" do
    it "should create permission from @permissions" do
      permission = mock('permission')
      permission.stub!(:id).and_return("3344")
      permission.stub!(:name).and_return("sweet permission")
      permissions = [permission]

      Permission = mock('Permission')
      Permission.stub!(:find).with(:all).and_return(permissions)

      Lockdown.should_receive(:database_execute).
        with("delete from permissions_user_groups where permission_id = 3344")
      permission.should_receive(:destroy)

      Lockdown::Database.delete_extinct_permissions
    end
  end
end

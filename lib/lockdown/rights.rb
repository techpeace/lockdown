module Lockdown
  module Rights
    attr_accessor :permissions #:nodoc:
    attr_accessor :user_groups #:nodoc:

    # :public_access allows access to all
    attr_reader :public_access #:nodoc:
    # :protected_access will restrict access to authenticated users.
    attr_reader :protected_access #:nodoc:

    # Future functionality:
    # :private_access will restrict access to model data to their creators.
    # attr_accessor :private_access 

    # Sets permission with arrays of access_rights, e.g.:
    # ["controller_a/method_1", "controller_a/method_2", ...]

    def initialize_rights
      @permissions ||= {}
      @user_groups ||= {}

      @public_access ||= []
      @protected_access ||= []
    end

    def set_permission(name, *method_arrays)
      permissions[name] ||= []
      method_arrays.each{|ary| permissions[name] += ary}
    end
    
    # Permissions are stored as a hash with the value being the method_arrays
    def get_permissions
      permissions.keys
    end
      
    def permission_exists?(perm)
      get_permissions.include?(perm)
    end

    def access_rights_for_permission(perm)
      sym = Lockdown.get_symbol(perm)
        
      unless permission_exists?(sym)
        raise SecurityError, "Permission requested is not defined: #{sym}"
      end
      permissions[sym]
    end

    def set_user_group(name, *perms)
      user_groups[name] ||= []
      perms.each do |perm| 
        unless permission_exists?(perm)
          raise SecurityError, "For UserGroup (#{name}), permission is invalid: #{perm}"
        end
        user_groups[name].push(perm)
      end
    end
    
    def get_user_groups
      user_groups.keys
    end

    def user_group_exists?(ug)
      get_user_groups.include?(ug)
    end

    # Determine if the user group is defined in init.rb
    def has_user_group?(ug)
      sym = Lockdown.get_symbol(ug)

      return true if sym == Lockdown.administrator_group_symbol
      user_group_exists?(sym)
    end

    def set_public_access(*perms)
      perms.each{|perm| @public_access += permissions[perm]}
    end

    def public_access?(perm)
      public_access.include?(perm)
    end

    def set_protected_access(*perms)
      perms.each{|perm| @protected_access += permissions[perm]}
    end

    def protected_access?(perm)
      protected_access.include?(perm)
    end

    def permission_assigned_automatically?(perm)
      public_access?(perm) || protected_access?(perm)
    end

    # Test user for administrator rights
    def administrator?(usr)
      user_has_user_group?(usr, Lockdown.administrator_group_symbol)
    end

    # Returns array of controller/action values administrators can access.
    def administrator_rights
      Lockdown::System.all_controllers_all_methods
    end
      
    def make_user_administrator(usr)
      unless Lockdown.database_table_exists?(UserGroup)
        create_administrator_user_group 
      end

      usr.user_groups << UserGroup.find_or_create_by_name(Lockdown.administrator_group_string)
    end

    # Returns array of controller/action values all logged in users can access.
    def standard_authorized_user_rights
      Lockdown::System.public_access + Lockdown::System.protected_access 
    end

    # Return array of controller/action values user can access.
    def access_rights_for_user(usr)
      return unless usr
      return :all if administrator?(usr)

      rights = standard_authorized_user_rights
        
      usr.user_groups.each do |grp|
        permissions_for_user_group(grp) do |perm|
          rights += access_rights_for_permission(perm) 
        end
      end
      rights
    end

    # Use this for the management screen to restrict user group list to the
    # user.  This will prevent a user from creating a user with more power than
    # him/her self.
    def user_groups_assignable_for_user(usr)
      return [] if usr.nil?
        
      if administrator?(usr)
        UserGroup.find_by_sql <<-SQL
          select user_groups.* from user_groups order by user_groups.name
        SQL
      else
        UserGroup.find_by_sql <<-SQL
            select user_groups.* from user_groups, user_groups_users
             where user_groups.id = user_groups_users.user_group_id
             and user_groups_users.user_id = #{usr.id}	 
             order by user_groups.name
        SQL
      end
    end

    # Similar to user_groups_assignable_for_user, this method should be
    # used to restrict users from creating a user group with more power than
    # they have been allowed.
    def permissions_assignable_for_user(usr)
      return [] if usr.nil?
      if administrator?(usr)
        get_permissions.collect{|k| Permission.find_by_name(Lockdown.get_string(k)) }.compact
      else
        user_groups_assignable_for_user(usr).collect{|g| g.permissions}.flatten.compact
      end
    end

    def permissions_for_user_group(ug)
      sym = Lockdown.get_symbol(ug)
      perm_array = []  

      if has_user_group?(sym)
        permissions = user_groups[sym] || []
      else
        permissions = ug.permissions
      end


      permissions.each do |perm|
        perm_sym = Lockdown.get_symbol(perm)

        unless permission_exists?(perm_sym)
          raise SecurityError, "Permission associated to User Group is invalid: #{perm}"
        end

        if block_given?
          yield perm_sym
        else
          perm_array << perm_sym
        end
      end

      return perm_array unless block_given?
    end


    private

    def user_has_user_group?(usr, sym)
      usr.user_groups.each do |ug|
        return true if Lockdown.convert_reference_name(ug.name) == sym
      end
      false
    end

    def create_administrator_user_group
      UserGroup.create :name => Lockdown.administrator_group_string
    end
      
  end
end
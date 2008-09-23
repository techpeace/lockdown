module Lockdown
  module Rights
    attr_accessor :permissions #:nodoc:
    attr_accessor :user_groups #:nodoc:

    # :public_access allows access to all
    attr_accessor :public_access #:nodoc:
    # :protected_access will restrict access to authenticated users.
    attr_accessor :protected_access #:nodoc:

    # Future functionality:
    # :private_access will restrict access to model data to their creators.
    # attr_accessor :private_access 

    # Sets permission with arrays of access_rights, e.g.:
    # ["controller_a/method_1", "controller_a/method_2", ...]
    def set_permission(name, *method_arrays)
      @permissions[name] ||= []
      method_arrays.each{|ary| @permissions[name] += ary}
    end
    
    # Permissions are stored as a hash with the value being the method_arrays
    def get_permissions
      @permissions.keys
    end
      
    def set_user_group(name, *perms)
      @user_groups[name] ||= []
      perms.each do |perm| 
        unless permission_exists?(perm)
          raise SecurityError, "For UserGroup (#{name}), permission is invalid: #{perm}"
        end
        @user_groups[name].push(perm)
      end
    end
    
    def get_user_groups
      @user_groups.keys
    end

    def set_public_access(*perms)
      perms.each{|perm| @public_access += @permissions[perm]}
    end

    def set_protected_access(*perms)
      perms.each{|perm| @protected_access += @permissions[perm]}
    end

  end
end
module Lockdown
  module Session
    def nil_lockdown_values
      [:expiry_time, :user_id, :user_name, :user_profile_id, :access_rights].each do |val|
        session[val] = nil if session[val]
      end
    end 
    
    def current_user_access_in_group?(grp)
      return true if current_user_is_admin?
        Lockdown::System.user_groups[grp].each do |perm|
          return true if access_in_perm?(perm)
        end
      false
    end

    def current_user_is_admin?
      session[:access_rights] == :all
    end

    def add_lockdown_session_values(user)
      session[:access_rights] = Lockdown::System.access_rights_for_user(user)
    end

    def access_in_perm?(perm)
      if Lockdown::System.permissions[perm]
        Lockdown::System.permissions[perm].each do |ar|
          return true if session_access_rights_include?(ar)
        end 
      end
      false
    end

    def session_access_rights_include?(str)
      return false unless session[:access_rights]
      session[:access_rights].include?(str)
    end
  end # Session
end # Lockdown

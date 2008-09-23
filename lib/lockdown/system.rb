module Lockdown
  class System
    class << self
      include Lockdown::Rights

      attr_accessor :options #:nodoc:
      attr_accessor :controller_classes #:nodoc:

      def configure(&block)
        set_defaults

        instance_eval(&block)

        if options[:use_db_models] && options[:sync_init_rb_with_db]
          sync_with_db
        end
      end

      def fetch(key)
        (@options||={})[key]
      end
      

      def permission_exists?(perm)
        get_permissions.include?(perm)
      end


      def permissions_for_user_group(ug)
        sym = Lockdown.get_symbol(ug)
        
        if has_user_group?(sym)
          @user_groups[sym].each do |perm|
            unless permission_exists?(perm)
              raise SecurityError, "Permission associated to User Group is invalid: #{perm}"
            end
            yield perm
          end
        elsif ug.respond_to?(:name)
          # This user group was defined in the database
          ug.permissions.each do |perm|
            perm_sym = Lockdown.get_symbol(perm.name)
            unless permission_exists?(perm_sym)
              raise SecurityError, "Permission associated to User Group is invalid: #{perm_sym}"
            end
            yield perm_sym
          end
        else
          raise SecurityError, "UserGroup is not known: #{ug.inspect}"
        end
      end

      def access_rights_for_permission(perm)
        sym = Lockdown.get_symbol(perm)
        
        unless permission_exists?(sym)
          raise SecurityError, "Permission requested is not defined: #{sym}"
        end
        @permissions[sym]
      end
      
      def public_access?(perm)
        @public_access.include?(perm)
      end

      def protected_access?(perm)
        @protected_access.include?(perm)
      end

      def permission_assigned_automatically?(perm)
        public_access?(perm) || protected_access?(perm)
      end

      def standard_authorized_user_rights
        Lockdown::System.public_access + Lockdown::System.protected_access 
      end

      # Determine if the user group is defined in init.rb
      def has_user_group?(ug)
        sym = Lockdown.get_symbol(ug)

        return true if sym == administrator_group_symbol
        get_user_groups.each do |key|
          return true if key == sym
        end
        false
      end

      # Delete a user group record from the database
      def delete_user_group(str_sym)
        ug = UserGroup.find(:first, :conditions => ["name = ?",Lockdown.get_string(str_sym)])
        ug.destroy unless ug.nil?
      end

      def access_rights_for_user(usr)
        return unless usr
        return :all if administrator?(usr)

        rights = standard_authorized_user_rights
        
        if @options[:use_db_models]
          usr.user_groups.each do |grp|
            permissions_for_user_group(grp) do |perm|
              rights += access_rights_for_permission(perm) 
            end
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
          UserGroup.find(:all, :order => :name)
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
          @permissions.keys.collect{|k| Permission.find_by_name(Lockdown.get_string(k)) }.compact
        else
          groups = user_groups_assignable_for_user(usr)
          groups.collect{|g| g.permissions}.flatten.compact
        end
      end

      def make_user_administrator(usr)
        unless Lockdown.database_table_exists?(UserGroup)
          create_administrator_user_group 
        end

        usr.user_groups << UserGroup.find_or_create_by_name(administrator_group_string)
      end
      
      def administrator?(usr)
        user_has_user_group?(usr, administrator_group_symbol)
      end

      def administrator_rights
        all_controllers
      end
      
      def fetch_controller_class(str)
        @controller_classes[Lockdown.controller_class_name(str)]
      end
      
      protected 

      def set_defaults
        load_controller_classes

        @permissions = {}
        @user_groups = {}
        
        @public_access = []
        @protected_access = []
        @private_access = []

        @options = {
          :use_db_models => true,
          :sync_init_rb_with_db => true,
          :session_timeout => (60 * 60),
          :logout_on_access_violation => false,
          :access_denied_path => "/",
          :successful_login_path => "/"
        }
      end

      private
      
      def create_administrator_user_group
        return unless @options[:use_db_models]
        UserGroup.create :name => administrator_group_name
      end
      
      def user_has_user_group?(usr, sym)
        usr.user_groups.each do |ug|
          return true if convert_reference_name(ug.name) == sym
        end
        false
      end

      def load_controller_classes
        @controller_classes = {}
         
        maybe_load_framework_controller_parent

        Dir.chdir("#{Lockdown.project_root}/app/controllers") do
          Dir["**/*.rb"].sort.each do |c|
            next if c == "application.rb"
            lockdown_load(c) 
          end
        end

        if Lockdown::Env.rails_app? && ENV['RAILS_ENV'] != 'production'
          if ActiveSupport.const_defined?("Dependencies")
            ActiveSupport::Dependencies.clear
          else
            Dependencies.clear
          end
        end
      end

      def maybe_load_framework_controller_parent
        if Lockdown::Env.rails_app?
          if ActiveSupport.const_defined?("Dependencies")
            ActiveSupport::Dependencies.require_or_load("application.rb")
          else
            Dependencies.require_or_load("application.rb")
          end
        else
          load("application.rb") unless const_defined?("Application")
        end
      end
      
      def lockdown_load(file)
        klass = Lockdown.class_name_from_file(file)
        if Lockdown::Env.rails_app?
          if ActiveSupport.const_defined?("Dependencies")
            ActiveSupport::Dependencies.require_or_load(file)
          else
            Dependencies.require_or_load(file)
          end
        else
          load(file) unless qualified_const_defined?(klass)
        end
        @controller_classes[klass] = qualified_const_get(klass) 
      end

      def qualified_const_defined?(klass)
        if klass =~ /::/
          namespace, klass = klass.split("::")
          eval("#{namespace}.const_defined?(#{klass})") if const_defined?(namespace)
        else
          const_defined?(klass)
        end
      end

      def qualified_const_get(klass)
        if klass =~ /::/
          namespace, klass = klass.split("::")
          eval(namespace).const_get(klass)
        else
          const_get(klass)
        end
      end

      # This is very basic and could be handled better using orm specific
      # functionality, but I wanted to keep it generic to avoid creating 
      # an interface for each the different orm implementations. 
      # We'll see how it works...
      def sync_with_db
        # Create permissions not found in the database
        get_permissions.each do |key|
          next if permission_assigned_automatically?(key)
          str = Lockdown.get_string(key)
          p = Permission.find(:first, :conditions => ["name = ?", str])
          unless p
            puts ">> Lockdown: Permission not found in db: #{str}, creating."
            Permission.create(:name => str)
          end
        end

        # Delete the permissions not found in init.rb
        db_perms = Permission.find(:all).dup
        perm_keys = get_permissions
        db_perms.each do |dbp|
          unless perm_keys.include?(Lockdown.get_symbol(dbp.name))
            puts ">> Lockdown: Permission no longer in init.rb: #{dbp.name}, deleting."
            Lockdown.database_execute("delete from permissions_user_groups where permission_id = #{dbp.id}")
            dbp.destroy
          end
        end

        # Create user groups not found in the database
        get_user_groups.each do |key|
          str = Lockdown.get_string(key)
          ug = UserGroup.find(:first, :conditions => ["name = ?", str])
          unless ug
            puts ">> Lockdown: UserGroup not in the db: #{str}, creating."
            ug = UserGroup.create(:name => str)
            #Inefficient, definitely, but shouldn't have any issues across orms.
            permissions_for_user_group(key) do |perm|
              p = Permission.find(:first, :conditions => ["name = ?", Lockdown.get_string(perm)])
              Lockdown.database_execute <<-SQL 
                insert into permissions_user_groups(permission_id, user_group_id)
                values(#{p.id}, #{ug.id})
              SQL
            end
          else
            # Remove permissions from user group not found in init.rb
            ug.permissions.each do |perm|
              perm_sym = Lockdown.get_symbol(perm)
              perm_string = Lockdown.get_string(perm)
              unless @user_groups[key].include?(perm_sym)
                puts ">> Lockdown: Permission: #{perm_string} no longer associated to User Group: #{ug.name}, deleting."
                ug.permissions.delete(perm)
              end
            end

            # Add in permissions from init.rb not found in database
            @user_groups[key].each do |perm|
              perm_string = Lockdown.get_string(perm)
              found = false
              # see if permission exists
              ug.permissions.each do |p|
                found = true if Lockdown.get_string(p) == perm_string 
              end
              # if not found, add it
              unless found
                puts ">> Lockdown: Permission: #{perm_string} not found for User Group: #{ug.name}, adding it."
                p = Permission.find(:first, :conditions => ["name = ?", perm_string])
                ug.permissions << p
              end
            end
          end
        end
      rescue Exception => e
        puts ">> Lockdown sync failed: #{e}" 
      end
    end # class block
  end # System class
end # Lockdown

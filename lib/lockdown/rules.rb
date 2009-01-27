module Lockdown
  module Rules
    def configure(&block)
      @permissions  = {}
      @user_groups  = {}
      @options      = {}

      @controller_classes = []
      @public_access      = []
      @protected_access   = []

      load_controller_classes

      set_defaults 

      instance_eval(&block)

      parse_permissions

      Lockdown::Database.sync_with_db unless skip_sync?
    end

    def set_defaults
      @options = {
        :session_timeout => (60 * 60),
        :logout_on_access_violation => false,
        :access_denied_path => "/",
        :successful_login_path => "/",
        :subdirectory => nil,
        :skip_db_sync_in => ["test"]
      }
    end

    def set_permission(name)
      @permissions[name] = Lockdown::Permission.new(name)
    end
  end
end

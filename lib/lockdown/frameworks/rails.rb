require File.join(File.dirname(__FILE__), "rails", "view")

module Lockdown
  module Frameworks
    module Rails
      class << self
        def use_me?
          Object.const_defined?("ActionController") && ActionController.const_defined?("Base")
        end

        def mixin
          controller_parent.send :include, Lockdown::Frameworks::Rails::ControllerInspector
          controller_parent.send :include, Lockdown::Frameworks::Rails::ControllerLock
          ActionView::Base.send :include, Lockdown::Frameworks::Rails::View
        end

        def project_root
          RAILS_ROOT
        end

        def controller_parent
          ActionController::Base
        end

        def controller_class_name(str)
          str = "#{str}Controller"
          if str.include?("__")
            str.split("__").collect{|p| Lockdown.camelize(p)}.join("::")
          else
            Lockdown.camelize(str)
          end
        end
      end #class block


      require File.join(File.dirname(__FILE__), "..", "controller_inspector")

      module ControllerInspector
        include Lockdown::ControllerInspector::Core
      
        def available_actions(klass)
          klass.public_instance_methods - klass.hidden_actions
        end
      end # ControllerInspector

      #
      # Rails Controller locking methods
      #
      module ControllerLock
        def self.included(base)
          base.send :include, Lockdown::Frameworks::Rails::ControllerLock::InstanceMethods

          base.before_filter do |controller|
            controller.set_current_user
            controller.configure_lock_down
            controller.check_request_authorization
          end

          base.send :helper_method, :authorized?

          base.filter_parameter_logging :password, :password_confirmation
      
          base.rescue_from SecurityError,
            :with => proc{|e| access_denied(e)}
        end

        module InstanceMethods
          def self.included(base)
            base.class_eval do
              alias :send_to  :redirect_to
            end
            base.send :include, Lockdown::Controller::Core
          end

          def sent_from_uri
            request.request_uri
          end
        
          def authorized?(url)
            return false unless url

            return true if current_user_is_admin?

            url.strip!

            url_parts = URI::split(url)
            
            path = url_parts[5]
            
            # See if path is known
            return true if path_allowed?(path)

            # Test to see if url contains id 
            parts = path.split("/").collect{|p| p unless p =~ /\A\d+\z/}.compact
            new_path = parts.join("/")
            
            return true if path_allowed?(new_path)

            # Test for a named routed
            begin
              hsh = ActionController::Routing::Routes.recognize_path(path)
              unless hsh.nil? || hsh[:id]
                return true if path_allowed?(path_from_hash(hsh)) 
              end
            rescue Exception 
              # continue on
            end

            # Passing in different domain
            return true if remote_url?(url_parts[2])

            false
          end
      
          def access_denied(e)
            if Lockdown::System.fetch(:logout_on_access_violation)
              reset_session
            end

            respond_to do |accepts|
              accepts.html do
                store_location
                send_to Lockdown::System.fetch(:access_denied_path)
              end
              accepts.xml do
                headers["Status"] = "Unauthorized"
                headers["WWW-Authenticate"] = %(Basic realm="Web Password")
                render :text => e.message, :status => "401 Unauthorized"
              end
            end
            false
          end

          def path_from_hash(hsh)
            hsh[:controller].to_s + "/" + hsh[:action].to_s
          end

          def remote_url?(domain = nil)
            return false if domain.nil? || domain.strip.length == 0
            request.host.downcase != domain.downcase
          end
        end # InstanceMethods
      end # ControllerLock
    end # Rails
  end # Frameworks
end # Lockdown
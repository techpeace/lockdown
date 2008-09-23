require File.join(File.dirname(__FILE__), "merb", "view")

module Lockdown
  module Frameworks
    module Merb
      class << self
        def use_me?
          Object.const_defined?("Merb") && ::Merb.const_defined?("AbstractController")
        end

        def mixin
          controller_parent.send :include, Lockdown::Frameworks::Merb::ControllerInspector
          controller_parent.send :include, Lockdown::Frameworks::Merb::ControllerLock
          ::Merb::AssetsMixin.send :include, Lockdown::Frameworks::Merb::View
        end

        def project_root
          ::Merb.root
        end

        def controller_parent
          ::Merb::Controller 
        end

        def controller_class_name(str)
          if str.include?("__")
            str.split("__").collect{|p| Lockdown.camelize(p)}.join("::")
          else
            Lockdown.camelize(str)
          end
        end
      end # class block

      require File.join(File.dirname(__FILE__), "..", "controller_inspector")

      module ControllerInspector
        include Lockdown::ControllerInspector::Core
      
        def available_actions(klass)
          klass.callable_actions.keys
        end
      end # ControllerInspector

      #
      # Merb Controller locking methods
      #
      module ControllerLock
        def self.included(base)
          base.send :include, Lockdown::Frameworks::Merb::ControllerLock::InstanceMethods

          base.before :set_current_user
          base.before :configure_lock_down
          base.before :check_request_authorization
        end

        module InstanceMethods
          def self.included(base)
            base.class_eval do
              alias :send_to  :redirect
            end
            base.send :include, Lockdown::Controller::Core
          end

          def sent_from_uri
            request.uri
          end

          def authorized?(path)
            return true if current_user_is_admin?

            # See if path is known
            if path_allowed?(path)
              true 
            else
              false
            end
          end
          
          # Can log Error => e if desired, I don't desire to now.
          # For now, just send home, but will probably make this configurable
          def access_denied(e)
            send_to Lockdown::System.fetch(:access_denied_path)
          end
          
          def path_from_hash(hsh)
            return hsh if hsh.is_a?(String)
            hsh = hsh.to_hash if hsh.is_a?(Mash)
            hsh['controller'].to_s + "/" + hsh['action'].to_s
          end
          
        end # InstanceMethods
      end # ControllerLock
    end # Merb
  end # Frameworks
end # Lockdown
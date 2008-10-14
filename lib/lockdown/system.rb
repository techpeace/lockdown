require File.join(File.dirname(__FILE__), "rights")
require File.join(File.dirname(__FILE__), "database")

module Lockdown
  class System
    class << self
      include Lockdown::Rights

      attr_accessor :options #:nodoc:
      attr_accessor :controller_classes #:nodoc:

      def configure(&block)
        set_defaults

        instance_eval(&block)

        Lockdown::Database.sync_with_db
      end

      # Return option value for key
      def fetch(key)
        (@options||={})[key]
      end

      # *syms is a splat of controller symbols,
      # e.g all_methods(:users, :authors, :books)
      def all_methods(*syms)
        syms.collect{ |sym| paths_for(sym) }.flatten
      end
    
      # controller name (sym) and a splat of methods to 
      # exclude from result
      #
      # All user methods except destroy:
      # e.g all_except_methods(:users, :destroy)
      def all_except_methods(sym, *methods)
        paths_for(sym) - paths_for(sym, *methods) 
      end
    
      # controller name (sym) and a splat of methods to 
      # to build the result
      # 
      # Only user methods index (list), show (good for readonly access):
      # e.g only_methods(:users, :index, :show)
      def only_methods(sym, *methods)
        paths_for(sym, *methods)
      end

      # all controllers, all actions
      #
      # This is admin access
      def all_controllers_all_methods
        controllers = controller_classes
        controllers.collect do |str, klass|
          paths_for( controller_name(klass), available_actions(klass) )
        end.flatten!
      end

      def fetch_controller_class(str)
        controller_classes[Lockdown.controller_class_name(str)]
      end
    
      protected 

      def set_defaults
        load_controller_classes

        initialize_rights

        @options = {
          :session_timeout => (60 * 60),
          :logout_on_access_violation => false,
          :access_denied_path => "/",
          :successful_login_path => "/"
        }
      end

      private 

      def paths_for(str_sym, *methods)
        str_sym = str_sym.to_s if str_sym.is_a?(Symbol)
        if methods.empty?
          klass = fetch_controller_class(str_sym)
          methods = available_actions(klass) 
        end
        path_str = str_sym.gsub("__","\/") 
        returning = methods.flatten.collect{|meth| "#{path_str}/#{meth.to_s}" }
        returning
      end

    end # class block
  end # System class
end # Lockdown

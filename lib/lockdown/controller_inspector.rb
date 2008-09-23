module Lockdown
  module ControllerInspector
    module Core
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
      def all_controllers
        controllers = Lockdown::System.controller_classes
      
        controllers.collect do |controller|
          methods = available_actions(controller)
          paths_for(controller_name(controller), methods)
        end.flatten!
      end
    
      private 

      def paths_for(str_sym, *methods)
        str = str_sym.to_s if str_sym.is_a?(Symbol)
        if methods.empty?
          klass = Lockdown::System.fetch_controller_class(str)
          methods = available_actions(klass) 
        end
        path_str = str.gsub("__","\/") 
        methods.collect{|meth| "#{path_str}/#{meth.to_s}" }
      end

      # Luckily both Rails and Merb have the controller_name method. This 
      # is here in case that changes.
      def controller_name(klass)
        klass.controller_name
      end
    end #Core
  end # ControllerInspector
end # Lockdown

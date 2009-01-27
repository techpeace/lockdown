module Lockdown
  class System
    if Lockdown.major_version == 0 && Lockdown.minor_version <= 7
      # old and crusty.  will be removed at version 1.0
      require File.join(File.dirname(__FILE__), "rights")
      extend Lockdown::Rights
    else
      require File.join(File.dirname(__FILE__), "rules")
      extend Lockdown::Rules
    end


    class << self
      attr_accessor :options
      attr_accessor :permissions
      attr_accessor :user_groups
      attr_accessor :controller_classes

      attr_reader :protected_access 
      attr_reader :public_access
    end


    # Return option value for key
    def self.fetch(key)
      (@options||={})[key]
    end

    def self.paths_for(str_sym, *methods)
      str_sym = str_sym.to_s if str_sym.is_a?(Symbol)
      if methods.empty?
        klass = fetch_controller_class(str_sym)
        methods = available_actions(klass) 
      end
      path_str = str_sym.gsub("__","\/") 
        
      subdir = Lockdown::System.fetch(:subdirectory)
      path_str = "#{subdir}/#{path_str}" if subdir

      controller_actions = methods.flatten
      paths = controller_actions.collect{|meth| "#{path_str}/#{meth.to_s}" }

      if controller_actions.include?("index")
        paths += [path_str]
      end

      paths
    end

    protected 

    def self.fetch_controller_class(str)
      controller_classes[Lockdown.controller_class_name(str)]
    end
  
 end # System class
end # Lockdown

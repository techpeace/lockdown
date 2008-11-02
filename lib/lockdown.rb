require File.join(File.dirname(__FILE__), "lockdown", "classy-inheritance")
require File.join(File.dirname(__FILE__), "lockdown", "helper")

module Lockdown
  class << self
    include Lockdown::Helper

    def mixin
      if mixin_resource?("frameworks")
        unless mixin_resource?("orms")
          raise NotImplementedError, "ORM unknown to Lockdown!"
        end
      else
        raise NotImplementedError, "Framework unknown to Lockdown!"
      end
    end

    private

    def mixin_resource?(str)
      Dir["#{File.dirname(__FILE__)}/lockdown/#{str}/*.rb"].each do |f|
        require "#{f}"
        mod = File.basename(f).split(".")[0]
        mklass = eval("Lockdown::#{str.capitalize}::#{Lockdown.camelize(mod)}")
        if mklass.use_me?
          include mklass
          return true
        end
      end
      false
    end
  end # class block
end # Lockdown


require File.join(File.dirname(__FILE__), "lockdown", "system")
require File.join(File.dirname(__FILE__), "lockdown", "controller")
require File.join(File.dirname(__FILE__), "lockdown", "session")

Lockdown.mixin

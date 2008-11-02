unless Object.const_defined?("Stonean") && Stonean.const_defined?("ClassyInheritance")
  begin
    require "classy-inheritance"
  rescue LoadError
    puts <<-MSG 
      You need to install classy-inheritance to use the provided models.
      With gems, use `gem install classy-inheritance'
    MSG
    exit
  end
end
             

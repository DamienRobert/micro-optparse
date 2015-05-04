require 'rubygems'
require 'minitest/autorun'
begin
  require 'pry-rescue/minitest'
  require 'minitest/reporters'
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
  #Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
rescue LoadError
  #missing goodies
end


require 'helper'
require 'nano/optparse'

class TestNano::Optparse < Minitest::Test

  def test_version
    version = Nano::Optparse.const_get('VERSION')

    assert(!version.empty?, 'should have a VERSION constant')
  end

end

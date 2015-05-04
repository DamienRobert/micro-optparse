require 'helper'
require 'nano-optparse'

class TestNanoOptparse < Minitest::Test

  def test_version
    version = NanoOptparse.const_get('VERSION')

    assert(!version.empty?, 'should have a VERSION constant')
  end

end

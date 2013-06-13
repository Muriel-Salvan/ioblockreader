require 'test/unit'

root_path = File.expand_path("#{File.dirname(__FILE__)}/..")

# Add the test directory to the current load path
$: << "#{root_path}/test"
# And the lib one too
$: << "#{root_path}/lib"

# Require the main library
require 'ioblockreader'

# Load test files to execute
require 'ioblockreader/common/testio'
require 'ioblockreader/common/helpers'
require 'ioblockreader/testcases/interface/common'
require 'ioblockreader/testcases/interface/square_brackets'
require 'ioblockreader/testcases/interface/index'
require 'ioblockreader/testcases/interface/each_block'
require 'ioblockreader/testcases/ioaccesses'

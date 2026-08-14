require "rspec"
require "bigdecimal"
require "bigdecimal/util"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "app"))

require "services/oja/settlement/scheduler"
require "services/oja/settlement/route"
require "services/oja/settlement/transfer_gateway"
require "services/oja/settlement/conditional_batch"

RSpec.configure do |config|
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.disable_monkey_patching!
end

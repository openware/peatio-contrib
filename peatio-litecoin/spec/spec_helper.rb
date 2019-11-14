require "bundler/setup"
require "peatio/litecoin"
require "pry-byebug"
require "webmock/rspec"
require "mocha"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.mock_with :mocha

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

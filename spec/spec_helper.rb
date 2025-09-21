# frozen_string_literal: true

RSpec.configure do |config|
  # Use the expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Exclude integration specs by default. Run with INTEGRATION=1 to include them.
  if ENV['INTEGRATION'] == '1'
    config.filter_run_including integration: true
  else
    config.filter_run_excluding integration: true
  end
end

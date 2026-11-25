###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SandboxModeHelpers
  # Runs the block with SANDBOX_MODE=true, restoring the prior value afterwards.
  def with_sandbox_mode
    original = ENV.fetch('SANDBOX_MODE', nil)
    ENV['SANDBOX_MODE'] = 'true'
    yield
  ensure
    ENV['SANDBOX_MODE'] = original
  end
end

RSpec.configure do |config|
  config.include SandboxModeHelpers
end

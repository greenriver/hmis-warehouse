###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require_relative '/app/config/deploy/docker/lib/asset_compiler'
class RunAssetCompilerJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  def perform
    ::AssetCompiler.new(target_group_name: ENV.fetch('ASSETS_PREFIX')).delay.run! if ENV['ASSETS_PREFIX']
  end

  def max_attempts
    1
  end
end

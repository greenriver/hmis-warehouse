###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Grover.configure do |config|
  config.options = {
    launch_args: [
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  }
end

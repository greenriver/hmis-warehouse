###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Git
  def self.revision
    if File.exist?('REVISION')
      File.read('REVISION')
    else
      ENV['DEPLOYMENT_ID']&.split('::').try(:[], 2)
    end
  rescue StandardError
    'unknown revision'
  end
end

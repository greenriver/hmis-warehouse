###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EdIpImportJob < BaseJob
    queue_as :long_running

    def perform(id)
      Health::EdIpVisitFile.find(id.to_i).create_visits!
    end
  end
end

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class EdIpImportJob < ActiveJob::Base
    queue_as :low_priority

    def perform(id)
      Health::EdIpVisitFile.find(id.to_i).create_visits!
    end
  end
end

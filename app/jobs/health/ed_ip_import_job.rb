###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EdIpImportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(id)
      file = Health::EdIpVisitFile.find(id.to_i)
      file.load!
      file.ingest!(Health::LoadedEdIpVisit.from_file(file))
    end
  end
end

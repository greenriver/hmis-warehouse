###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour
  class ExportJob < ::ExportBaseJob
    def exporter_base
      HmisCsvTwentyTwentyFour::Exporter::Base
    end
  end
end

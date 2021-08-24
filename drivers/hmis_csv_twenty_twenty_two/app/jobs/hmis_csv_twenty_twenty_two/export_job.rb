###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo
  class ExportJob < ::ExportBaseJob
    def exporter_base
      HmisCsvTwentyTwentyTwo::Exporter::Base
    end
  end
end

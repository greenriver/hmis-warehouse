###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvTwentyTwenty::ImportLog < GrdaWarehouse::ImportLog
  belongs_to :loader_log, class_name: 'HmisCsvTwentyTwenty::Loader::LoaderLog', optional: true
  belongs_to :importer_log, class_name: 'HmisCsvTwentyTwenty::Importer::ImporterLog', optional: true
end

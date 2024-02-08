###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::ImportLog < GrdaWarehouse::ImportLog
  belongs_to :loader_log, class_name: 'HmisCsvImporter::Loader::LoaderLog', optional: true
  belongs_to :importer_log, class_name: 'HmisCsvImporter::Importer::ImporterLog', optional: true
end

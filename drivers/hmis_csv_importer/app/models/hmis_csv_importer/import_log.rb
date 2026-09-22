###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/hud-reporting/csv-import.md
class HmisCsvImporter::ImportLog < GrdaWarehouse::ImportLog
  belongs_to :loader_log, class_name: 'HmisCsvImporter::Loader::LoaderLog', optional: true
  belongs_to :importer_log, class_name: 'HmisCsvImporter::Importer::ImporterLog', optional: true
end

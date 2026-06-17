###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvTwentyTwenty::ImportLog < GrdaWarehouse::ImportLog
  belongs_to :loader_log, class_name: 'HmisCsvTwentyTwenty::Loader::LoaderLog', optional: true
  belongs_to :importer_log, class_name: 'HmisCsvTwentyTwenty::Importer::ImporterLog', optional: true
end

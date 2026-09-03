###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.hmis_data_lakes['2020'] = 'HmisCsvTwentyTwenty'
# Rails.application.reloader.to_prepare do
#   Importers::HmisAutoDetect.add_importer('HmisCsvTwentyTwenty')
#   Filters::HmisExport.register_version('HMIS 2020', '2020', 'HmisCsvTwentyTwenty::ExportJob')
# end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.hmis_data_lakes['2022'] = 'HmisCsvTwentyTwentyTwo'
# Rails.application.reloader.to_prepare do
#   Filters::HmisExport.register_version('HMIS 2022', '2022', 'HmisCsvTwentyTwentyTwo::ExportJob')
# end

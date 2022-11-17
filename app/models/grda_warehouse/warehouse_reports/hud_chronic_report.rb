###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class HudChronicReport < Base
    def headers_for_export
      headers = ['Warehouse Client ID']
      headers += ['First Name', 'Last Name', 'DOB'] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
      headers += ['Homeless Since', 'Days Homeless in last three years', 'Months Homeless in last three years', 'Chronic Trigger', 'Involved Projects', 'Last Homeless Service', 'Disability', 'DMH Client', 'Veteran', 'Current SO Enrollment', 'Data Sources']
      headers
    end

    def rows_for_export
      data.map do |client|
        chronic = client['hud_chronic']
        disabilities = client['source_disabilities'].gsub('<br />', ', ')
        data_sources = client['data_sources']
        row = [client['id']]
        row += [client['FirstName'], client['LastName'], client['DOB']] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
        row + [
          chronic['homeless_since'],
          chronic['days_in_last_three_years'],
          chronic['months_in_last_three_years'],
          chronic['trigger'],
          client['chronic_project_names'],
          client['most_recent_service'],
          disabilities,
          yn(chronic['dmh']),
          yn(client['veteran']),
          yn(client['so_clients'].include?(client['id'])),
          data_sources,
        ]
      end
    end
  end
end

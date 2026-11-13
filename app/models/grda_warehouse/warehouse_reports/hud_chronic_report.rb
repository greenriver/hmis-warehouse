###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::WarehouseReports
  class HudChronicReport < Base
    def headers_for_export
      headers = ['Warehouse Client ID']
      headers += ['First Name', 'Last Name', 'DOB'] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
      headers += ['Homeless Since', 'Days Homeless in last three years', 'Months Homeless in last three years', 'Chronic Trigger', 'Involved Projects', 'Last Homeless Service', 'Disability', 'DMH Client', 'Veteran', 'Current SO Enrollment', 'Data Sources']
      headers
    end

    def rows_for_export(user:)
      data.map do |client|
        chronic = client['hud_chronic']
        disabilities = client['source_disabilities'].gsub('<br />', ', ')
        data_sources = client['data_sources']
        policy = user.reporting_policy_for_project(project_id: nil, mode: :download, client_id: client['id'])
        pii = GrdaWarehouse::PiiProvider.from_attributes(policy: policy, first_name: client['FirstName'], last_name: client['LastName'], dob: client['DOB'])
        row = [client['id']]
        row += [pii.first_name, pii.last_name, GrdaWarehouse::PiiProvider.viewable_dob(client['DOB'], policy: policy)] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
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

    def yn(boolean)
      boolean ? 'Y' : 'N'
    end
  end
end

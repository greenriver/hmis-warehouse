###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Youth
  class Export
    include ArelHelper

    def initialize(filter)
      @start_date = filter.start
      @end_date = filter.end
      @filter = filter
    end

    # Clients of age during the range, who also meet
    def clients
      @clients ||=  begin
        clients = GrdaWarehouse::Hud::Client.where(id: clients_within_age_range.select(:id))
        if @filter.effective_project_ids.sort != @filter.all_project_ids.sort
          clients = clients.where(id: clients_within_projects.select(:id))
        end
        if @filter.clients_from_cohorts.exists?
          clients = clients.where(id: @filter.clients_from_cohorts.select(:id))
        end
        clients
      end
    end

    def rows_for_export
      clients.map do |client|
        [
          client.id,
          client.FirstName,
          client.LastName,
          client.race_description,
          HUD.ethnicity(client.Ethnicity),
          client.gender,
          HUD.veteran_status(client.VeteranStatus),
          ApplicationController.helpers.yes_no(client_disabled?(client), include_icon: false),
        ]
      end
    end

    def headers_for_report
      [
        'Client ID',
        'First Name',
        'Last Name',
        'Race',
        'Ethnicity',
        'Gender',
        'Veteran Status',
        'Disabling Condition',
      ]
   end

    private def clients_within_age_range
      @clients_within_age_range ||= GrdaWarehouse::Hud::Client.destination.
        age_group_within_range(start_age: @filter.start_age, end_age: @filter.end_age, start_date: @filter.start, end_date: @filter.end)
    end

    private def clients_within_projects
      @clients_within_projects ||= begin
        GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :project).
          merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user).where(id: @filter.effective_project_ids))
      end
    end

    def client_disabled?(client)
      @disabled_clients ||= GrdaWarehouse::Hud::Client.disabled_client_scope.where(id: clients.select(:id)).pluck(:id)
      @disabled_clients.include?(client.id)
    end

  end
end
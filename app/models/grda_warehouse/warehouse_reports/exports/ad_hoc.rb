###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# NOTES about calculations
# Where there may be more than one answer for a client, the most-recent enrollment or exit that falls
# within the chosen date range

module GrdaWarehouse::WarehouseReports::Exports
  class AdHoc < GrdaWarehouseBase
    self.table_name = :exports_ad_hocs
    include ArelHelper
    include Rails.application.routes.url_helpers
    include ::WarehouseReports::Export

    acts_as_paranoid

    def filter
      @filter ||= ::Filters::DateRangeAndSources.new(options)
    end

    def title
      'Ad-Hoc Export'
    end

    def url
      warehouse_reports_ad_hoc_analysis_index_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
      update(started_at: Time.current)
      update(
        headers: headers_for_report,
        rows: rows_for_export,
        client_count: rows_for_export.count,
        completed_at: Time.current,
      )
    end

    def self.index_columns
      [
        :id,
        :user_id,
        :options,
        :client_count,
        :started_at,
        :completed_at,
        :created_at,
      ]
    end

    def client_scope
      @client_scope ||=  begin
        clients = clients_within_age_range
        clients = clients_with_ongoing_enrollments(clients)
        clients = heads_of_household(clients)
        clients = filter_for_sub_population(clients)
        clients = clients.where(id: clients_within_projects.select(:id)) unless filter.all_projects?
        clients
      end
    end

    private def race_for_client(client)
      description = client.race_description
      return 'Multi-Racial' if description.include?(',')

      description
    end

    def rows_for_export
      @rows_for_export ||= begin
        rows = []
        client_scope.in_batches do |batch|
          report_calculator = WarehouseReport::ExportEnrollmentCalculator.new(batch_scope: batch, filter: filter)
          batch.find_each do |client|
            rows << [
              client.id,
              client.FirstName,
              client.LastName,
              client.age(filter.end),
              race_for_client(client),
              HUD.ethnicity(client.Ethnicity),
              client.gender,
              report_calculator.pregnancy_status_for(client),
              HUD.veteran_status(client.VeteranStatus),
              yes_no(report_calculator.disabled_and_imparing?(client)),
              report_calculator.episode_length_for(client),
              report_calculator.days_homeless(client),
              report_calculator.episode_counts_past_3_years_for(client),
              HUD.project_type(report_calculator.enrollment_for_client(client)&.project&.computed_project_type),
              HUD.destination(report_calculator.exit_for_client(client)&.Destination),
              yes_no(report_calculator.returned?(client)),
              HUD.living_situation(report_calculator.enrollment_for_client(client)&.LivingSituation),
              report_calculator.vispdat_for_client(client)&.score,
              report_calculator.household_size_for(client),
            ]
          end
        end
        rows
      end
    end

    def headers_for_report
      [
        'Client ID',
        'First Name',
        'Last Name',
        'Age',
        'Race',
        'Ethnicity',
        'Gender',
        'Pregnancy Status',
        'Veteran Status',
        'Indefinite and Impairing Disabling Condition',
        'Duration of Most Recent Episode',
        'Total Days Homeless in Past 3 Years',
        'Episodes in the Past 3 Years',
        'Enrollment Type',
        'Destination',
        'Returned to Homelessness after Permanent Exit',
        'Prior Living Situation',
        'VI-SPDAT Score',
        'Household Members',
      ]
    end
  end
end
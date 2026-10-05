###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTES about calculations
# Where there may be more than one answer for a client, the most-recent enrollment or exit that falls
# within the chosen date range
module GrdaWarehouse::WarehouseReports::Exports
  class AdHoc < GrdaWarehouseBase
    self.table_name = :exports_ad_hocs
    include ArelHelper
    include Rails.application.routes.url_helpers
    include ::WarehouseReports::Export
    include Memery

    acts_as_paranoid

    def filter
      @filter ||= ::Filters::DateRangeAndSourcesResidentialOnly.new(options)
    end

    def title
      'Ad-Hoc Export'
    end

    def url
      warehouse_reports_ad_hoc_analysis_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
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
      # Nothing selected and nothing authorized both complete as an empty report
      return GrdaWarehouse::Hud::Client.none unless any_authorized_projects?

      @client_scope ||= begin
        clients = clients_within_age_range
        clients = clients_with_ongoing_enrollments(clients)
        clients = heads_of_household(clients)
        clients = filter_for_sub_population(clients)
        clients = clients.where(id: clients_within_projects.select(:id))
        clients
      end
    end

    def any_authorized_projects?
      authorized_project_ids.present?
    end

    # The filter's selected projects, narrowed to those the user can report on
    memoize private def authorized_project_ids
      project_source.where(id: filter.effective_project_ids).pluck(:id)
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(filter.user, permission: :can_view_assigned_reports)
    end

    private def race_for_client(client)
      fields = client.race_fields
      return 'Multi-Racial' if fields.count > 1

      fields.map { |f| ::HudHelper.util.race f }.join ', '
    end

    def rows_for_export
      @rows_for_export ||= begin
        rows = []
        preload_policies
        client_scope.distinct.in_batches(of: 100) do |batch|
          report_calculator = WarehouseReport::ExportEnrollmentCalculator.new(batch_scope: batch, filter: filter)
          project_ids_by_client = authorized_project_ids_by_client(batch)
          batch.find_each do |client|
            policy = name_policy_for(client, project_ids_by_client.fetch(client.id, []))
            rows << [
              client.id,
              GrdaWarehouse::PiiProvider.viewable_name(client.FirstName, policy: policy, replacement: GrdaWarehouse::PiiProvider::NAME_REDACTED),
              GrdaWarehouse::PiiProvider.viewable_name(client.LastName, policy: policy, replacement: GrdaWarehouse::PiiProvider::NAME_REDACTED),
              client.age(filter.end),
              race_for_client(client),
              client.gender,
              report_calculator.pregnancy_status_for(client),
              HudHelper.util.veteran_status(client.VeteranStatus),
              yes_no(report_calculator.disabled_and_impairing?(client)),
              report_calculator.episode_length_for(client),
              report_calculator.average_episode_length_for(client),
              report_calculator.days_homeless(client),
              report_calculator.episode_counts_past_3_years_for(client),
              HudHelper.util.project_type(report_calculator.enrollment_for_client(client)&.project&.project_type),
              HudHelper.util.destination(report_calculator.exit_for_client(client)&.Destination),
              HudHelper.util.destination(report_calculator.most_recent_exit_with_destination_for_client(client)&.Destination),
              yes_no(report_calculator.returned?(client)),
              HudHelper.util.living_situation(report_calculator.enrollment_for_client(client)&.LivingSituation),
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
        'Gender',
        'Pregnancy Status',
        'Veteran Status',
        'Indefinite and Impairing Disabling Condition',
        'Duration of Most Recent Episode (months)',
        'Average Episode Duration (months)',
        "Total Days Homeless in Past 3 Years as of #{Date.current}",
        "Episodes in the Past 3 Years as of #{filter.last}",
        'Enrollment Type',
        'Earliest Destination within Range',
        'Most-Recent Destination within Range',
        'Returned to Homelessness after Permanent Exit',
        'Most Recent Prior Living Situation',
        'VI-SPDAT Score',
        'Household Members from Most Recent Enrollment',
      ]
    end

    memoize private def export_user
      User.find_by(id: user_id)
    end

    private def preload_policies
      export_user.policy_context.preload_project_dependencies(authorized_project_ids) if export_user && authorized_project_ids.present?
    end

    # { destination client id => [authorized project ids they were enrolled in during the range] }
    private def authorized_project_ids_by_client(batch)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: filter.start, end_date: filter.end).
        where(client_id: batch.select(:id)).
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(id: authorized_project_ids)).
        distinct.
        pluck(:client_id, p_t[:id]).
        group_by(&:first).
        transform_values { |pairs| pairs.map(&:last) }
    end

    # A row aggregates the client's in-range enrollments, so the name shows if any
    # authorized project they were enrolled in allows it.
    private def name_policy_for(client, project_ids)
      return GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance unless export_user

      allowed = project_ids.any? { |id| export_user.reporting_policy_for_project(project_id: id, mode: :download).can_view_name? }
      policy = allowed ? GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance : GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
      GrdaWarehouse::PiiProvider.restrict(policy, restricted: export_user.policy_context.client_restricted?(client.id))
    end
  end
end

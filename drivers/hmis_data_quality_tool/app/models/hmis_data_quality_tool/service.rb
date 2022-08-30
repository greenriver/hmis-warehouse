###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Service < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_services'
    include ArelHelper
    include DqConcern
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true

    def self.detail_headers
      {
        destination_client_id: 'Warehouse Client ID',
        personal_id: 'HMIS Service ID',
        date_provided: 'Date Provided',
        entry_date: 'Entry Date',
        exit_date: 'Exit Date',
        project_operating_start_date: 'Project Operating Start Date',
        project_operating_end_date: 'Project Operating End Date',
        project_tracking_method: 'Project Tracking Method',
        project_type: 'Project Type',
      }.freeze
    end

    def self.calculate_issues(report_items, report)
      sections.each do |_, opts|
        report_items = calculate(**{ report_items: report_items, report: report }.merge(opts))
      end
      report_items
    end

    def self.calculate(report_items:, report:, title:, query:, **_)
      intermediate = {}
      # NOTE: service_scope actually returns the client because we want to know about duplication within the client
      service_scope(query, report).find_each do |client|
        item = report_item_fields_from_client(
          report_items: report_items,
          client: client,
          report: report,
        )

        intermediate[client] = item
      end

      import_intermediate!(intermediate.values)
      report.universe(title).add_universe_members(intermediate) if intermediate.present?

      report_items.merge(intermediate)
    end

    def self.service_scope(scope, report)
      GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report.report_scope).distinct.
        where(scope)
    end

    def self.report_item_fields_from_client(report_items:, client:, report:)
      report_item = report_items[client] || new(
        report_id: report.id,
        client_id: client.id,
        destination_client_id: client.warehouse_client_source.destination_id,
      )
      report_item.first_name = client.FirstName
      report_item.last_name = client.LastName
      report_item.personal_id = client.PersonalID
      report_item.data_source_id = client.data_source_id
      report_item.male = client.Male
      report_item.female = client.Female
      report_item.no_single_gender = client.NoSingleGender
      report_item.transgender = client.Transgender
      report_item.questioning = client.Questioning
      report_items[client] = report_item
    end

    def self.sections
      {
        gender_issues: {
          title: 'Gender',
          description: 'Gender fields and Gender None are incompatible, or invalid gender response was recorded',
          query: gender_issues_query,
        },
        race_issues: {
          title: 'Race',
          description: 'Race fields and Race None are incompatible, or invalid race response was recorded',
          query: race_issues_query,
        },
        dob_issues: {
          title: 'DOB',
          description: 'DOB is blank, before Oct. 10 1910, or after entry date',
          query: dob_issues_query,
        },
      }
    end
  end
end

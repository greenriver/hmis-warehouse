###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class CurrentLivingSituation < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_current_living_situations'
    include ArelHelper
    include DqConcern
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :current_living_situation, class_name: 'GrdaWarehouse::Hud::CurrentLivingSituation', optional: true

    def self.detail_headers
      {
        destination_client_id: { title: 'Warehouse Client ID' },
        current_living_situation_id: { title: 'Current Living Situation ID' },
        hmis_current_living_situation_id: { title: 'HMIS Current Living Situation ID' },
        current_living_situation: { title: 'Current Living Situation', translator: ->(v) { "#{HUD.living_situation(v)} (#{v})" } },
        first_name: { title: 'First Name' },
        last_name: { title: 'Last Name' },
        project_name: { title: 'Project Name' },
        enrollment_id: { title: 'Enrollment ID' },
        information_date: { title: 'Information Date' },
        project_operating_start_date: { title: 'Project Operating Start Date' },
        project_operating_end_date: { title: 'Project Operating End Date' },
      }.freeze
    end

    def self.detail_headers_for_export
      return detail_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      detail_headers.except(:first_name, :last_name)
    end

    # Because multiple of these calculations require inspecting unrelated enrollments
    # we're going to loop over the entire enrollment scope once rather than
    # load it multiple times
    def self.calculate(report_items:, report:)
      current_living_situation_scope(report).find_in_batches do |batch|
        intermediate = {}
        batch.each do |current_living_situation|
          item = report_item_fields_from_current_living_situation(
            report_items: report_items,
            current_living_situation: current_living_situation,
            report: report,
          )
          sections(report).each do |_, calc|
            section_title = calc[:title]
            intermediate[section_title] ||= { denominator: {}, invalid: {} }
            intermediate[section_title][:denominator][current_living_situation] = item if calc[:denominator].call(item)
            intermediate[section_title][:invalid][current_living_situation] = item if calc[:limiter].call(item)
          end
        end
        intermediate.each do |section_title, item_batch|
          import_intermediate!(item_batch[:denominator].values)
          report.universe("#{section_title}__denominator").add_universe_members(item_batch[:denominator]) if item_batch[:denominator].present?
          report.universe("#{section_title}__invalid").add_universe_members(item_batch[:invalid]) if item_batch[:invalid].present?

          report_items.merge!(item_batch)
        end
      end
      report_items
    end

    def self.current_living_situation_scope(report)
      GrdaWarehouse::Hud::CurrentLivingSituation.joins(enrollment: [:service_history_enrollment, :project]).
        preload(enrollment: [:project, client: :warehouse_client_source]).
        merge(report.report_scope).distinct
    end

    def self.report_item_fields_from_current_living_situation(report_items:, current_living_situation:, report:)
      # we only need to do the calculations once, the values will be the same for any current_living_situation,
      # no matter how many times we see it
      report_item = report_items[current_living_situation]
      return report_item if report_item.present?

      project = current_living_situation.enrollment.project
      client = current_living_situation.enrollment.client
      report_item = new(
        report_id: report.id,
        current_living_situation_id: current_living_situation.id,
      )
      report_item.client_id = client.id
      report_item.situation = current_living_situation.CurrentLivingSituation
      report_item.enrollment_id = current_living_situation.enrollment.id
      report_item.first_name = client.FirstName
      report_item.last_name = client.LastName
      report_item.project_name = project.name(report.user)
      report_item.project_id = project.id
      report_item.destination_client_id = client.warehouse_client_source.destination_id
      report_item.hmis_current_living_situation_id = current_living_situation.CurrentLivingSitID
      report_item.data_source_id = current_living_situation.data_source_id
      report_item.information_date = current_living_situation.InformationDate
      report_item.project_operating_start_date = project.OperatingStartDate
      report_item.project_operating_end_date = project.OperatingEndDate
      report_item.project_tracking_method = project.TrackingMethod
      report_item
    end

    def self.sections(_)
      {
        current_living_situation_issues: {
          title: 'Current Living Situation',
          description: 'Current Living Situation is an invalid value',
          required_for: 'All',
          denominator: ->(_item) { true },
          limiter: ->(item) {
            ! HUD.valid_current_living_situations.include?(item.situation)
          },
        },
      }.freeze
    end
  end
end

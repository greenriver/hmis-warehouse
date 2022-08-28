###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Enrollment < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_enrollments'
    include ArelHelper
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true

    def self.detail_headers
      {
        destination_client_id: 'Warehouse Client ID',
        hmis_enrollment_id: 'HMIS Enrollment ID',
        personal_id: 'HMIS Personal ID',
        project_name: 'Project Name',
        exit_id: 'HMIS Exit ID',
        entry_date: 'Entry Date',
        move_in_date: 'Move-in Date',
        exit_date: 'Exit Date',
        age: 'Reporting Age',
        household_max_age: 'Age of Oldest Household Member',
        household_id: 'Household ID',
        head_of_household_count: 'Count of Heads of Household',
        disabling_condition: 'Disabling Condition',
        living_situation: 'Living Situation',
        relationship_to_hoh: 'Relationship to Head of Household',
        coc_code: 'CoC Code',
        destination: 'Exit Destination',
        project_operating_start_date: 'Project Operating Start Date',
        project_operating_end_date: 'Project Operating End Date',
        project_tracking_method: 'Project Tracking Method',
        lot: 'Length of Time in Project',
        days_since_last_service: 'Days Since Last Service',
      }.freeze
    end

    def self.calculate_enrollment_issues(report_enrollments, report)
      [
        [
          disabling_condition_issues_slug,
          disabling_condition_issues_query,
        ],
        [
          hoh_validation_issues_slug,
          hoh_validation_issues_query,
        ],
        [
          living_situation_issues_slug,
          living_situation_issues_query,
        ],
      ].each do |slug, query|
        report_enrollments = calculate(
          report_enrollments: report_enrollments,
          report: report,
          slug: slug,
          query: query,
        )
      end
      report_enrollments
    end

    def self.calculate(report_enrollments:, report:, slug:, query:)
      intermediate_report_enrollments = {}
      enrollment_scope(query, report).find_each do |enrollment|
        intermediate_report_enrollments[enrollment.client] = report_enrollment_fields_from_enrollment(
          report_enrollments: report_enrollments,
          enrollment: enrollment,
          report: report,
        )
      end

      import_intermediate!(intermediate_report_enrollments.values)
      report.universe(slug).add_universe_members(intermediate_report_enrollments) if intermediate_report_enrollments.present?

      report_enrollments.merge(intermediate_report_enrollments)
    end

    def self.import_intermediate!(values)
      import!(
        values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: attribute_names.map(&:to_sym),
        },
      )
    end

    def self.enrollment_scope(scope, report)
      GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        preload(:exit, :project, :services, :enrollment_coc_at_entry, client: :warehouse_client_source).
        merge(report.report_scope).distinct.
        where(scope)
    end

    def self.report_enrollment_fields_from_enrollment(report_enrollments:, enrollment:, report:)
      client = enrollment.client
      report_enrollment = report_enrollments[client] || new(
        report_id: report.id,
        enrollment_id: enrollment.id,
      )
      report_enrollment.client_id = client.id
      report_enrollment.personal_id = client.PersonalID
      report_enrollment.destination_client_id = client.warehouse_client_source.destination_id
      report_enrollment.hmis_enrollment_id = enrollment.EnrollmentID
      report_enrollment.exit_id = enrollment.exit&.ExitID
      report_enrollment.data_source_id = enrollment.data_source_id
      report_enrollment.project_name = enrollment.project.name(report.user)
      report_enrollment.entry_date = enrollment.EntryDate
      report_enrollment.move_in_date = enrollment.MoveInDate
      report_enrollment.exit_date = enrollment.exit&.ExitDate
      report_enrollment.disabling_condition = enrollment.DisablingCondition
      report_enrollment.household_id = enrollment.HouseholdID
      report_enrollment.living_situation = enrollment.LivingSituation
      report_enrollment.relationship_to_hoh = enrollment.RelationshipToHoH
      report_enrollment.coc_code = enrollment.enrollment_coc_at_entry&.CoCCode
      report_enrollment.destination = enrollment.exit&.Destination
      report_enrollment.project_operating_start_date = enrollment.project.OperatingStartDate
      report_enrollment.project_operating_end_date = enrollment.project.OperatingEndDate
      project_tracking_method = enrollment.project.TrackingMethod
      report_enrollment.project_tracking_method = project_tracking_method
      report_age_date = [enrollment.EntryDate, report.filter.start].max
      report_enrollment.age = enrollment.client.age_on(report_age_date)

      hh = report.household(enrollment.HouseholdID)
      report_enrollment.household_max_age = hh.map { |en| en[:age] }.compact.max
      report_enrollment.head_of_household_count = hh.select { |en| en[:relationship_to_hoh] == 1 }.count

      max_date = [report.filter.end, Date.current].min
      en_services = enrollment.services&.select { |s| s.DateProvided <= max_date }

      lot = if project_tracking_method == 3
        # count services <= min of report end and current date
        en_services&.count || 0
      else
        # count dates between entry and min of report end, current_date, exit_date
        max_date = [enrollment.exit&.ExitDate, report.filter.end, Date.current].compact.min
        (max_date - enrollment.EntryDate).to_i
      end
      report_enrollment.lot = lot
      max_service = if project_tracking_method == 3
        # most recent service
        en_services.max_by(&:DateProvided)&.DateProvided
      else
        # min of exit date, report end, current date
        [enrollment.exit&.ExitDate, report.filter.end, Date.current].compact.min
      end
      report_enrollment.days_since_last_service = (report.filter.end - max_service).to_i if max_service.present?
      report_enrollment
    end

    def self.disabling_condition_issues_query
      e_t[:DisablingCondition].not_in(HUD.no_yes_reasons_for_missing_data_options.keys)
    end

    def self.hoh_validation_issues_query
      e_t[:RelationshipToHoH].not_in(HUD.relationships_to_hoh.keys)
    end

    def self.living_situation_issues_query
      e_t[:LivingSituation].eq(nil).or(e_t[:LivingSituation].not_in(HUD.valid_prior_living_situations))
    end

    def self.disabling_condition_issues_slug
      'Disabling Condition'
    end

    def self.hoh_validation_issues_slug
      'Relationship to Head of Household'
    end

    def self.living_situation_issues_slug
      'Living Situation'
    end
  end
end

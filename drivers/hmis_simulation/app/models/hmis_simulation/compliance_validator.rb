###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Audits generated HMIS records against the machine-readable compliance rules
  # in ComplianceRules. Checks record *presence* only — value validity is enforced
  # at generation time by builders sampling from HudHelper.util code sets.
  #
  # Checks performed:
  #   - HmisParticipation — projects where ComplianceRules.hmis_participation_required?
  #   - CeParticipation — CE (type 14) projects only
  #   - Inventory — residential project types (non-SO/SSO/Other/DayShelter/HP/CE)
  #   - DateOfEngagement — SO (type 4) enrollments
  #   - LivingSituation — all enrollments
  #   - EmploymentEducation at entry — residential enrollment types
  #   - CurrentLivingSituation — SO (type 4) and CE (type 14) enrollments
  #   - Assessment — CE (type 14) enrollments
  #   - HealthAndDv at exit — project types where health_and_dv_required? is true (exited enrollments only)
  #
  # Returns an array of violation hashes, each with:
  #   :type        — Symbol identifying the violation
  #   :message     — Human-readable description
  #   :project_name — Project name (for project-level violations)
  #   :project_type — Project type integer
  #
  # Usage:
  #   v = HmisSimulation::ComplianceValidator.new(data_source_id: 42)
  #   violations = v.validate!
  #   puts violations.map { |v| v[:message] }.join("\n")
  class ComplianceValidator
    def initialize(data_source_id:)
      @data_source_id = data_source_id
      @violations = []
    end

    def validate!
      @violations = []
      @project_info_by_pk = nil
      check_project_records
      check_enrollment_fields
      check_enrollment_records
      @violations
    end

    private

    def check_project_records
      projects = Hmis::Hud::Project.
        where(data_source_id: @data_source_id).
        includes(:hmis_participations, :ce_participations, :inventories)

      projects.each do |project|
        pt = project.ProjectType.to_i

        if ComplianceRules.hmis_participation_required?(pt) && project.hmis_participations.empty?
          add_violation(
            type: :missing_hmis_participation,
            project_name: project.ProjectName,
            project_type: pt,
            message: "Project #{project.ProjectName.inspect} (type #{pt}) is missing an HmisParticipation record",
          )
        end

        if ComplianceRules.ce_participation_required?(pt) && project.ce_participations.empty?
          add_violation(
            type: :missing_ce_participation,
            project_name: project.ProjectName,
            project_type: pt,
            message: "CE project #{project.ProjectName.inspect} (type #{pt}) is missing a CeParticipation record",
          )
        end

        next unless ComplianceRules.inventory_required?(pt)
        next if project.inventories.any?

        add_violation(
          type: :missing_inventory,
          project_name: project.ProjectName,
          project_type: pt,
          message: "Residential project #{project.ProjectName.inspect} (type #{pt}) is missing an Inventory record",
        )
      end
    end

    def check_enrollment_fields
      Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id).
        pluck(:project_pk, :EnrollmentID, :DateOfEngagement, :LivingSituation).
        each do |project_pk, enrollment_id, date_of_engagement, living_situation|
          info = project_info_by_pk[project_pk]
          next unless info

          pt = info[:type]
          project_name = info[:name]

          if ComplianceRules.date_of_engagement_required?(pt) && date_of_engagement.blank?
            add_violation(
              type: :missing_date_of_engagement,
              project_name: project_name,
              project_type: pt,
              message: "SO enrollment #{enrollment_id.inspect} in #{project_name.inspect} is missing DateOfEngagement",
            )
          end

          next if living_situation.present?

          add_violation(
            type: :missing_living_situation,
            project_name: project_name,
            project_type: pt,
            message: "Enrollment #{enrollment_id.inspect} in #{project_name.inspect} (type #{pt}) is missing LivingSituation",
          )
        end
    end

    def check_enrollment_records
      check_employment_education(project_info_by_pk)
      check_cls_records(project_info_by_pk)
      check_ce_assessments(project_info_by_pk)
      check_health_and_dv_at_exit(project_info_by_pk)
    end

    def check_employment_education(project_info)
      check_presence_for_projects(
        project_info: project_info,
        project_filter: ->(pt) { ComplianceRules.employment_education_required?(pt) },
        hud_class: Hmis::Hud::EmploymentEducation,
        stage_scope: { DataCollectionStage: 1 },
        adult_hoh_only: true,
        violation_type: :missing_employment_education,
        message_builder: ->(id, name, type) {
          "Enrollment #{id.inspect} in #{name.inspect} (type #{type}) is missing an entry EmploymentEducation record"
        },
      )
    end

    def check_cls_records(project_info)
      check_presence_for_projects(
        project_info: project_info,
        project_filter: ->(pt) { ComplianceRules.cls_required?(pt) },
        hud_class: Hmis::Hud::CurrentLivingSituation,
        violation_type: :missing_cls_record,
        message_builder: ->(id, name, type) {
          "Enrollment #{id.inspect} in #{name.inspect} (type #{type}) is missing a CurrentLivingSituation record"
        },
      )
    end

    def check_ce_assessments(project_info)
      check_presence_for_projects(
        project_info: project_info,
        project_filter: ->(pt) { pt == ComplianceRules::CE_PROJECT_TYPE },
        hud_class: Hmis::Hud::Assessment,
        violation_type: :missing_ce_assessment,
        message_builder: ->(id, name, _type) {
          "CE enrollment #{id.inspect} in #{name.inspect} is missing an Assessment record"
        },
      )
    end

    def check_health_and_dv_at_exit(project_info)
      check_presence_for_projects(
        project_info: project_info,
        project_filter: ->(pt) { ComplianceRules.health_and_dv_required?(pt) },
        hud_class: Hmis::Hud::HealthAndDv,
        stage_scope: { DataCollectionStage: 3 },
        enrollment_condition: ->(scope) { scope.joins(:exit) },
        adult_hoh_only: true,
        violation_type: :missing_health_and_dv_at_exit,
        message_builder: ->(id, name, type) {
          "Exited enrollment #{id.inspect} in #{name.inspect} (type #{type}) is missing an exit HealthAndDv record"
        },
      )
    end

    def check_presence_for_projects(
      project_info:,
      project_filter:,
      hud_class:,
      violation_type:,
      message_builder:,
      stage_scope: nil,
      enrollment_condition: nil,
      adult_hoh_only: false
    )
      matching_pks = project_info.select { |_, info| project_filter.call(info[:type]) }.keys
      return if matching_pks.empty?

      scope = hud_class.where(data_source_id: @data_source_id)
      scope = scope.where(**stage_scope) if stage_scope
      existing_ids = scope.pluck(:EnrollmentID).to_set

      enrollment_scope = Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id, project_pk: matching_pks)
      enrollment_scope = enrollment_condition.call(enrollment_scope) if enrollment_condition

      columns = [:project_pk, :EnrollmentID]
      columns += [:PersonalID, :RelationshipToHoH, :EntryDate] if adult_hoh_only
      rows = enrollment_scope.pluck(*columns)
      dob_by_personal_id = adult_hoh_only ? load_dob_by_personal_id(rows.map { |r| r[2] }) : {}

      rows.each do |row|
        project_pk, enrollment_id = row

        # Income/EmploymentEducation/Health-and-DV are required for adults and HoH only;
        # child members legitimately lack them, so don't flag those enrollments.
        if adult_hoh_only
          _pk, _id, personal_id, relationship_to_hoh, entry_date = row
          next unless ComplianceRules.adult_or_hoh?(
            relationship_to_hoh: relationship_to_hoh,
            dob: dob_by_personal_id[personal_id],
            date: entry_date,
          )
        end

        next if existing_ids.include?(enrollment_id)

        info = project_info[project_pk]
        add_violation(
          type: violation_type,
          project_name: info[:name],
          project_type: info[:type],
          message: message_builder.call(enrollment_id, info[:name], info[:type]),
        )
      end
    end

    def load_dob_by_personal_id(personal_ids)
      Hmis::Hud::Client.
        where(data_source_id: @data_source_id, PersonalID: personal_ids.compact.uniq).
        pluck(:PersonalID, :DOB).
        to_h
    end

    def project_info_by_pk
      @project_info_by_pk ||= Hmis::Hud::Project.
        where(data_source_id: @data_source_id).
        pluck(:id, :ProjectType, :ProjectName).
        each_with_object({}) do |(pk, pt, name), h|
          h[pk] = { type: pt.to_i, name: name }
        end
    end

    def add_violation(type:, message:, project_name: nil, project_type: nil)
      @violations << {
        type: type,
        message: message,
        project_name: project_name,
        project_type: project_type,
      }.compact
    end
  end
end

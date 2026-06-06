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
      check_project_records
      check_enrollment_fields
      @violations
    end

    private

    def check_project_records
      projects = Hmis::Hud::Project.
        where(data_source_id: @data_source_id).
        includes(:hmis_participations, :ce_participations)

      projects.each do |project|
        pt = project.ProjectType.to_i

        if project.hmis_participations.empty?
          add_violation(
            type: :missing_hmis_participation,
            project_name: project.ProjectName,
            project_type: pt,
            message: "Project #{project.ProjectName.inspect} (type #{pt}) is missing an HmisParticipation record",
          )
        end

        next unless ComplianceRules.ce_participation_required?(pt)
        next if project.ce_participations.any?

        add_violation(
          type: :missing_ce_participation,
          project_name: project.ProjectName,
          project_type: pt,
          message: "CE project #{project.ProjectName.inspect} (type #{pt}) is missing a CeParticipation record",
        )
      end
    end

    def check_enrollment_fields
      project_info = Hmis::Hud::Project.
        where(data_source_id: @data_source_id).
        pluck(:id, :ProjectType, :ProjectName).
        each_with_object({}) do |(pk, pt, name), h|
          h[pk] = { type: pt.to_i, name: name }
        end

      Hmis::Hud::Enrollment.
        where(data_source_id: @data_source_id).
        pluck(:project_pk, :EnrollmentID, :DateOfEngagement, :LivingSituation).
        each do |project_pk, enrollment_id, date_of_engagement, living_situation|
          info = project_info[project_pk]
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

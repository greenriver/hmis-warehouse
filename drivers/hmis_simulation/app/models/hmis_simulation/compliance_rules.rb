###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Loads and exposes the machine-readable HUD compliance rules from
  # drivers/hmis_simulation/public/compliance/project_type_rules.json.
  #
  # Rules are keyed by project type integer and encode:
  #   - bootstrap requirements (inventory, HmisParticipation, CeParticipation, sub-bed tracking)
  #   - enrollment entry requirements (DateOfEngagement, EmploymentEducation)
  #   - during-enrollment requirements (CLS frequency and jitter)
  #   - CE-specific requirements (Event, Assessment records)
  #
  # All methods accept a project_type integer and return a boolean or structured value.
  #
  # Usage:
  #   HmisSimulation::ComplianceRules.cls_required?(4)       # => true
  #   HmisSimulation::ComplianceRules.cls_frequency(4)       # => { days: 30, jitter_stddev: 15 }
  #   HmisSimulation::ComplianceRules.rules_for(14)          # => { "bootstrap" => {...}, ... }
  module ComplianceRules
    RULES_PATH = Rails.root.join(
      'drivers', 'hmis_simulation', 'public', 'compliance', 'project_type_rules.json'
    ).freeze
    CE_PROJECT_TYPE = 14
    SO_PROJECT_TYPE = 4
    ES_PROJECT_TYPES = [0, 1].freeze
    # HUD RelationshipToHoH code for "Self (head of household)"
    HEAD_OF_HOUSEHOLD = 1
    ADULT_AGE = 18

    module_function

    # Income (4.02), Health & DV (4.11), and Employment/Education are collected for
    # adults and heads of household only — never for child household members. Used by
    # both the engine (when generating these records) and the ComplianceValidator (when
    # auditing their presence), so the two stay in lockstep. Age is evaluated at the
    # enrollment EntryDate, the standard HUD reference point. A member with an unknown
    # DOB who is not the HoH is treated as a child (records not required).
    def adult_or_hoh?(relationship_to_hoh:, dob:, date:)
      return true if relationship_to_hoh.to_i == HEAD_OF_HOUSEHOLD
      return false if dob.blank? || date.blank?

      GrdaWarehouse::Hud::Client.age(date: date.to_date, dob: dob.to_date).to_i >= ADULT_AGE
    end

    def rules_for(project_type)
      all_rules[project_type.to_s]
    end

    def inventory_required?(project_type)
      all_rules.dig(project_type.to_s, 'bootstrap', 'inventory') || false
    end

    def hmis_participation_required?(project_type)
      all_rules.dig(project_type.to_s, 'bootstrap', 'hmis_participation') || false
    end

    def ce_participation_required?(project_type)
      all_rules.dig(project_type.to_s, 'bootstrap', 'ce_participation') || false
    end

    def employment_education_required?(project_type)
      all_rules.dig(project_type.to_s, 'enrollment_entry', 'employment_education_required') || false
    end

    def health_and_dv_required?(project_type)
      all_rules.dig(project_type.to_s, 'enrollment_entry', 'health_and_dv_required') || false
    end

    def date_of_engagement_required?(project_type)
      all_rules.dig(project_type.to_s, 'enrollment_entry', 'date_of_engagement_required') || false
    end

    def cls_required?(project_type)
      all_rules.dig(project_type.to_s, 'during_enrollment', 'cls_required') || false
    end

    # @return [Hash, nil] { days: Integer, jitter_stddev: Integer } or nil if CLS not required
    def cls_frequency(project_type)
      entry = all_rules.dig(project_type.to_s, 'during_enrollment')
      return nil unless entry&.fetch('cls_required', false)

      {
        days: entry['cls_frequency_days'],
        jitter_stddev: entry['cls_jitter_stddev'],
      }
    end

    def ce_records_required?(project_type)
      all_rules.dig(project_type.to_s, 'ce', 'events_required') || false
    end

    def all_rules
      @all_rules ||= JSON.parse(File.read(RULES_PATH)).reject { |k, _| k.start_with?('_') }.freeze
    end
  end
end

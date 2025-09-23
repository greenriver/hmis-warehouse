###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'

# Script to import CE Match Rules from a CSV format into AC HMIS environment.
# WARNING: This script will DELETE existing eligibility rules for projects listed in the import file
# that are not represented in the new import. Use with caution.
#
# This importer is AC-specific due to logic surrounding unit groups and "housing_needs_preferred_bedroom_size".
# It could be generalized for future use if needed.
#
# Expected CSV format:
#   Project Name,Project ID,Unit Group Name,Rule Name,Rule Expression
#
# Example usage:
#   importer = AcHmis::ImportCeMatchRules20251001.new('path/to/import.csv')
#   importer.import!
#   Hmis::Ce::Match::CandidatePoolBuilder.call # Rebuild candidate pools after import
module AcHmis
  class ImportCeMatchRules20251001
    def initialize(csv_file_path)
      @csv_file_path = csv_file_path
      @errors = []
      @success_count = 0
      @skipped_count = 0
      @project_ids = [] # all project primary keys for projects in the imported file
    end

    # Main import routine:
    # - Reads rules from CSV
    # - Deletes existing eligibility rules for listed projects not present in the import
    # - Imports new rules and default unit group rules.
    def import!
      puts "Starting CE Rules import from #{@csv_file_path}"
      puts '=' * 50

      Hmis::Hud::Base.transaction do
        puts 'Initializing rules...'
        rules = []
        CSV.foreach(@csv_file_path, headers: true) do |row|
          rule_data = process_row(row)
          rules << rule_data if rule_data
        end

        rules_to_create = rules.select(&:new_record?)
        rules_to_keep = rules.select(&:persisted?)
        puts "Found #{rules_to_create.size} rules to import, and #{rules_to_keep.size} rules to keep..."

        to_delete = Hmis::Ce::Match::Rule.eligibility_requirement.
          where(owner: Hmis::Hud::Project.hmis.where(id: @project_ids)).
          where.not(id: rules_to_keep.map(&:id))
        puts "Deleting #{to_delete.count} existing Project-level eligibility rules for this set of projects that we\'re not keeping..."
        to_delete.delete_all

        to_delete = Hmis::Ce::Match::Rule.eligibility_requirement.
          where(owner: Hmis::UnitGroup.where(project_id: @project_ids)).
          where.not(id: rules_to_keep.map(&:id))
        puts "Deleting #{to_delete.count} existing UnitGroup-level eligibility rules for this set of projects that we\'re not keeping..."
        to_delete.delete_all

        puts 'Importing...'
        Hmis::Ce::Match::Rule.import!(rules_to_create)

        puts 'Setting up Unit Group rules...'
        unit_group_default_rules_to_create = build_default_unit_group_rules
        puts "Importing #{unit_group_default_rules_to_create.size} default unit group rules..."
        Hmis::Ce::Match::Rule.import!(unit_group_default_rules_to_create)
      end

      print_summary
    end

    private

    # Processes a single CSV row.
    # Returns Hmis::Ce::Match::Rule object or nil if error.
    # The returned rule object may be new or existing.
    def process_row(row)
      project_id = row['Project ID']&.strip
      rule_name = row['Rule Name']&.strip
      rule_expression = row['Rule Expression']&.strip

      # Validate required fields
      if project_id.blank? || rule_name.blank? || rule_expression.blank?
        error_msg = "Missing required fields for row: Project ID=#{project_id}, Rule Name=#{rule_name}, Rule Expression=#{rule_expression}"
        @errors << error_msg
        puts "ERROR: #{error_msg}"
        return
      end

      # Find the project
      project = Hmis::Hud::Project.hmis.find_by(ProjectID: project_id)
      unless project
        error_msg = "Project with ID #{project_id} not found"
        @errors << error_msg
        puts "ERROR: #{error_msg}"
        return
      end
      @project_ids << project.id

      # Skip rows where Unit Group Name is not null
      unit_group = nil
      if row['Unit Group Name'].present?
        group_name = row['Unit Group Name']
        unit_group = project.unit_groups.find_by(name: group_name)
        unless unit_group
          error_msg = "Unit Group '#{group_name}' not found in project #{project.project_name} (ID: #{project_id})"
          @errors << error_msg
          puts "ERROR: #{error_msg}"
          return
        end
      end

      # Find or initialize rule
      owner = unit_group || project
      rule = Hmis::Ce::Match::Rule.eligibility_requirement.find_or_initialize_by(
        owner: owner,
        name: rule_name,
        expression: rule_expression,
        applicability_config: {},
      )

      if rule.persisted?
        puts "Rule '#{rule_name}' already exists for project #{project.project_name} (ID: #{project_id})"
        @skipped_count += 1
      else
        puts "✓ Initialized new rule '#{rule_name}' for project #{project.project_name} (Owner: #{rule.owner_type.demodulize}) (ID: #{project_id})"
        @success_count += 1
      end

      rule
    end

    # Keys match Pick List Options in Housing Needs Assessment.
    # Values match UnitType description in AC HMIS. (see drivers/hmis_external_apis/lib/data/ac_hmis/unit_types.json)
    ASSESSMENT_RESPONSE_TO_UNIT_TYPES = {
      # To be eligible for SRO/SRO Chronic Homeless/Accessible, must be referred to "SRO"
      'SRO' => ['SRO', 'SRO Chronic Homeless', 'SRO Accessible'],
      # To be eligible for 1BR/1BR Chronic Homeless/Accessible, must be referred to "1 Bed"
      '1 Bed' => ['1 Bed Room', '1 Bed Room Chronic Homeless', '1 Bed Room Accessible'],
      '2 Bed' => ['2 Bed Room', '2 Bed Room Chronic Homeless', '2 Bed Room Accessible'],
      '3 Bed' => ['3 Bed Room', '3 Bed Room Chronic Homeless', '3 Bed Room Accessible'],
      '4 Bed' => ['4 Bed Room', '4 Bed Room Chronic Homeless', '4 Bed Room Accessible'],
      'Households with Children' => ['Households with Children'],
      'Households without Children' => ['Households without Children'],
    }.freeze

    # Builds default unit group rules based on ASSESSMENT_RESPONSE_TO_UNIT_TYPES mapping.
    # For example, a unit group with "1 Bed Room" will get a rule requiring referral to "1 Bed".
    # Returns array of new Hmis::Ce::Match::Rule objects (not yet saved)
    def build_default_unit_group_rules
      project_scope = Hmis::Hud::Project.hmis.where(id: @project_ids)
      puts "Building default unit group rules for #{project_scope.count} projects..."

      unit_type_names = ASSESSMENT_RESPONSE_TO_UNIT_TYPES.values.flatten.uniq
      raise 'invalid unit types, some unit types not found' unless Hmis::UnitType.where(description: unit_type_names).size == unit_type_names.size

      rules_to_import = []

      unit_types_by_name = Hmis::UnitType.where(description: ASSESSMENT_RESPONSE_TO_UNIT_TYPES.values.flatten).index_by(&:description)

      ASSESSMENT_RESPONSE_TO_UNIT_TYPES.each do |referred_bedroom_type, accepted_unit_type_names|
        included = 0
        skipped = 0
        accepted_unit_types = accepted_unit_type_names.map { |name| unit_types_by_name[name] }

        Hmis::UnitGroup.where(project: project_scope, unit_type: accepted_unit_types).find_each do |unit_group|
          rule_name = "Must be referred to #{referred_bedroom_type}"
          rule_expression = "INCLUDES(`cde.custom_assessment.housing_needs_preferred_bedroom_size`, \"#{referred_bedroom_type}\")"

          rule = Hmis::Ce::Match::Rule.eligibility_requirement.find_or_initialize_by(
            owner: unit_group,
            name: rule_name,
            expression: rule_expression,
            applicability_config: {},
          )
          if rule.persisted?
            skipped += 1
          else
            included += 1
            rules_to_import << rule
          end
        end
        puts "Initialized #{included} rules for '#{referred_bedroom_type}', skipped #{skipped} existing rules"
      end
      rules_to_import
    end

    def print_summary
      puts "\n" + '=' * 50
      puts 'IMPORT SUMMARY'
      puts '=' * 50
      puts "Successfully imported: #{@success_count} rules"
      puts "Skipped: #{@skipped_count} rules"
      puts "Errors: #{@errors.length} rules"

      if @errors.any?
        puts "\nERRORS:"
        @errors.each { |error| puts "  - #{error}" }
      end

      puts "\nImport completed!"
    end
  end
end

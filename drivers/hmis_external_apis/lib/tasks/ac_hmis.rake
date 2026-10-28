###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :ac_hmis do
  # rails driver:hmis_external_apis:ac_hmis:import_housing_assessments[bucket_name,s3_key,<ce_project_id>,<form_definition_identifier>]
  task :import_housing_assessments, [:bucket_name, :s3_key, :project_id, :form_definition_identifier] => :environment do |_task, args|
    next unless HmisEnforcement.hmis_enabled?
    next unless Rails.env.development? || HmisExternalApis::AcHmis::Mci.enabled?

    # Download the file from S3 to a tempfile, then invoke the importer
    aws = AwsS3.new(bucket_name: args.bucket_name)

    require 'tempfile'
    raise ArgumentError, 's3_key is required' if args.s3_key.blank?
    raise ArgumentError, 's3 bucket is required' if args.bucket_name.blank?

    Tempfile.create(['housing_waitlist.xlsx']) do |tmp|
      aws.fetch(file_name: args.s3_key, target_path: tmp.path)
      HmisExternalApis::AcHmis::Importers::HousingAssessmentImporter.call(tmp.path, ce_project_id: args.project_id&.to_i, form_definition_identifier: args.form_definition_identifier, dry_run: false)
    end
  end

  # Replaces the version 2 Alt-AHA scoring rules for one form identifier with Allegheny's scorecard CSVs.
  # Safe to run at any time: the rules are unused until ac_hmis/alt_aha_model_version is set to 2.
  # rails "driver:hmis_external_apis:ac_hmis:import_alt_aha_v2_scorecards[housing_needs_assessment]" SCORECARD_CSVS=/path/one.csv,/path/two.csv,/path/three.csv,/path/four.csv
  task :import_alt_aha_v2_scorecards, [:form_definition_identifier] => :environment do |_task, args|
    paths = ENV.fetch('SCORECARD_CSVS', '').split(',').map(&:strip).compact_blank
    raise ArgumentError, 'SCORECARD_CSVS must list the scorecard CSV paths, separated by commas' if paths.empty?

    missing = paths.reject { |path| File.exist?(path) }
    raise ArgumentError, "Scorecard CSVs not found: #{missing.join(', ')}" if missing.any?

    result = HmisExternalApis::AcHmis::Importers::AltAhaV2ScorecardImporter.call(
      form_definition_identifier: args.form_definition_identifier,
      paths: paths,
    )
    puts "Replaced #{result[:deleted]} model version 2 rules for #{args.form_definition_identifier} with #{result[:created]} rules"
  end

  # Reports every Alt-AHA scoring rule for a model version and form identifier that does not fit the form:
  # questions the form lacks, and matched answers the question cannot store. Read-only.
  # Checks the published version of the form unless a definition id is given, e.g. to check a draft.
  # rails "driver:hmis_external_apis:ac_hmis:validate_alt_aha_rules[2,housing_needs_assessment]"
  # rails "driver:hmis_external_apis:ac_hmis:validate_alt_aha_rules[2,housing_needs_assessment,123]"
  task :validate_alt_aha_rules, [:model_version, :form_definition_identifier, :definition_id] => :environment do |_task, args|
    model_version = Integer(args.model_version.to_s, exception: false)
    raise ArgumentError, 'model_version must be 1 or 2' unless model_version.in?([1, 2])
    raise ArgumentError, 'form_definition_identifier is required' if args.form_definition_identifier.blank?

    definitions = Hmis::Form::Definition.where(identifier: args.form_definition_identifier)
    definition = if args.definition_id.present?
      definitions.find(args.definition_id)
    else
      published = definitions.published.to_a
      raise ArgumentError, "Expected one published #{args.form_definition_identifier}, found #{published.size}; pass a definition id" unless published.one?

      published.first
    end

    validator = HmisExternalApis::AcHmis::AltAhaCalculatorFactory.rule_validator(model_version, definition)
    rule_count = Hmis::Scoring::Rule.for_form(definition.identifier).where(model_version: model_version).count
    puts "Checking #{rule_count} model version #{model_version} rules against #{definition.identifier} definition #{definition.id} (version #{definition.version}, #{definition.status})"

    validator.issues.each { |issue| puts "PROBLEM: #{issue.message} (rules #{issue.rule_ids.join(', ')})" }
    validator.unchecked.each { |issue| puts "NOT CHECKED: #{issue.message} (rules #{issue.rule_ids.join(', ')})" }

    abort "#{validator.issues.size} problems found" unless validator.valid?

    puts 'All rules fit the form'
  end
end

# frozen_string_literal: true

namespace :ac_hmis do
  # rails driver:hmis_external_apis:ac_hmis:update_unit_availability
  # or to force an update
  # rails driver:hmis_external_apis:ac_hmis:update_unit_availability[force]
  task :update_unit_availability, [:force] => :environment do |_task, args|
    next unless HmisEnforcement.hmis_enabled? && HmisExternalApis::AcHmis::Mper.enabled?

    force = args.force == 'force'
    HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now(force: force)
  end

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

  task update_ce_project_configs: [:environment] do
    CreateCeProjectConfigs20250922.new(dry_run: false).perform
  end
end

# One-off import for Coordinated Entry (CE) project configs.
# Usage: CreateCeProjectConfigs20250922.new(dry_run: true).perform
class CreateCeProjectConfigs20250922
  attr_reader :dry_run

  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  # Project 'ProjectID' keys that are stable across environments
  PSH_EXCLUDE_IDS = [561, 692, 656, 1196].freeze
  PSH_DIRECT_ONLY_IDS = [656].freeze
  RRH_EXCLUDE_IDS = [1099].freeze
  TH_BOTH_IDS = [1154, 502, 587, 640].freeze
  TH_DIRECT_ONLY_IDS = [1389, 1398].freeze
  HP_BOTH_IDS = [708].freeze
  HP_DIRECT_ONLY_IDS = [1278, 1325].freeze
  EE_PROJECT_IDS = [506, 583, 1223, 1292, 624, 628, 771, 955, 987].freeze
  SSO_PROJECT_IDS = [1390, 1386, 1403, 530, 1428, 1168].freeze

  def perform
    Hmis::Hud::Base.transaction do
      update_all_configs
    end
  end

  private

  def update_all_configs
    # Most PSH (excluding some) support both waitlist and direct
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 3).where.not(project_id: PSH_EXCLUDE_IDS),
      waitlists: true, direct_referrals: true, label: 'PSH (both)', dry_run: dry_run,
    )
    # Some PSH support direct only
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_id: PSH_DIRECT_ONLY_IDS),
      waitlists: false, direct_referrals: true, label: 'PSH (direct only)', dry_run: dry_run,
    )
    # Most RRH (excluding some) support both waitlist and direct
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 13).where.not(project_id: RRH_EXCLUDE_IDS),
      waitlists: true, direct_referrals: true, label: 'RRH (both)', dry_run: dry_run,
    )
    # Some TH support both waitlist and direct
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 2).where(project_id: TH_BOTH_IDS),
      waitlists: true, direct_referrals: true, label: 'TH (both)', dry_run: dry_run,
    )
    # Some TH support direct only
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 2).where(project_id: TH_DIRECT_ONLY_IDS),
      waitlists: false, direct_referrals: true, label: 'TH (direct only)', dry_run: dry_run,
    )
    # Some HP support both waitlist and direct
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 12).where(project_id: HP_BOTH_IDS),
      waitlists: true, direct_referrals: true, label: 'HP (both)', dry_run: dry_run,
    )
    # Some HP support direct only
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 12).where(project_id: HP_DIRECT_ONLY_IDS),
      waitlists: false, direct_referrals: true, label: 'HP (direct only)', dry_run: dry_run,
    )
    # Some ES Entry/Exit support direct referrals
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 0).where(project_id: EE_PROJECT_IDS),
      waitlists: false, direct_referrals: true, label: 'Entry/Exit', dry_run: dry_run,
    )
    # Some Services Only support direct referrals
    update_configs(
      Hmis::Hud::Project.hmis.open_on_date.where(project_type: 8).where(project_id: SSO_PROJECT_IDS),
      waitlists: false, direct_referrals: true, label: 'Services Only', dry_run: dry_run,
    )
  end

  def update_configs(scope, waitlists:, direct_referrals:, label: nil, dry_run: false)
    ce_project = Hmis::Hud::Project.hmis.where(project_name: 'HMIS Coordinated Entry').sole
    unless waitlists || direct_referrals
      warn "[#{label}] Skipped: Must support waitlists or direct referrals."
      return
    end
    scope.each do |project|
      record = Hmis::ProjectCeConfig.find_or_initialize_by(project_id: project.id)
      record.supports_waitlist_referrals = waitlists
      record.receives_direct_referrals = direct_referrals
      record.receives_direct_referrals_from = [ce_project.id]
      unless record.changed?
        puts "[#{label}] No change to project ##{project.id} (#{project.project_name})"
        next
      end

      if dry_run
        puts "[DRY RUN][#{label}] Would update project ##{project.id} (#{project.project_name})"
        next
      end

      puts "[#{label}] Updating project ##{project.id} (#{project.project_name})"
      record.save!
    end
  end
end

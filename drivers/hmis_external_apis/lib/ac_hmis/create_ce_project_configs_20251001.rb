###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One-off import for Coordinated Entry (CE) project configs.
# Usage: AcHmis::CreateCeProjectConfigs20251001.new(dry_run: true).perform
module AcHmis
  class CreateCeProjectConfigs20251001
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
      # raise if any of the ProjectIDs are not found:
      all_expected_project_ids = [*PSH_EXCLUDE_IDS, *PSH_DIRECT_ONLY_IDS, *RRH_EXCLUDE_IDS, *TH_BOTH_IDS, *TH_DIRECT_ONLY_IDS, *HP_BOTH_IDS, *HP_DIRECT_ONLY_IDS, *EE_PROJECT_IDS, *SSO_PROJECT_IDS]
      found_project_ids = Hmis::Hud::Project.hmis.where(project_id: all_expected_project_ids).pluck(:project_id)
      missing_ids = all_expected_project_ids.map(&:to_s) - found_project_ids
      raise "Missing expected ProjectIDs: #{missing_ids.sort.join(', ')}" unless missing_ids.empty?

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
        Hmis::Hud::Project.hmis.open_on_date.where(project_id: TH_BOTH_IDS),
        waitlists: true, direct_referrals: true, label: 'TH (both)', dry_run: dry_run,
      )
      # Some TH support direct only
      update_configs(
        Hmis::Hud::Project.hmis.open_on_date.where(project_id: TH_DIRECT_ONLY_IDS),
        waitlists: false, direct_referrals: true, label: 'TH (direct only)', dry_run: dry_run,
      )
      # Some HP support both waitlist and direct
      update_configs(
        Hmis::Hud::Project.hmis.open_on_date.where(project_id: HP_BOTH_IDS),
        waitlists: true, direct_referrals: true, label: 'HP (both)', dry_run: dry_run,
      )
      # Some HP support direct only
      update_configs(
        Hmis::Hud::Project.hmis.open_on_date.where(project_id: HP_DIRECT_ONLY_IDS),
        waitlists: false, direct_referrals: true, label: 'HP (direct only)', dry_run: dry_run,
      )
      # Some ES Entry/Exit support direct referrals
      update_configs(
        Hmis::Hud::Project.hmis.open_on_date.where(project_id: EE_PROJECT_IDS),
        waitlists: false, direct_referrals: true, label: 'Entry/Exit', dry_run: dry_run,
      )
      # Some Services Only support direct referrals
      update_configs(
        Hmis::Hud::Project.hmis.open_on_date.where(project_id: SSO_PROJECT_IDS),
        waitlists: false, direct_referrals: true, label: 'Services Only', dry_run: dry_run,
      )
    end

    def update_configs(scope, waitlists:, direct_referrals:, label: nil, dry_run: false)
      ce_project = Hmis::Hud::Project.hmis.where(project_name: 'HMIS Coordinated Entry').sole
      unless waitlists || direct_referrals
        warn "[#{label}] Skipped: Must support waitlists or direct referrals."
        return
      end
      # Create or update ProjectCeConfig for the projects in scope
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

      # Ensure UnitGroups are set to the correct workflows based on whether the project
      # supports waitlists or not. Projects with waitlists always use the "housing workflow".
      workflow_template = waitlists ? :housing_workflow_v1 : :admin_assign_workflow
      scope.preload(:unit_groups).each do |project|
        unit_groups = project.unit_groups
        next unless unit_groups.any?

        unit_groups.each { |ug| ug.workflow_template_identifier = workflow_template }

        if unit_groups.any?(&:changed?)
          if dry_run
            puts "[DRY RUN][#{label}] Would set unit groups to use #{workflow_template} for project ##{project.id} (#{project.project_name})"
            next
          end

          puts "[#{label}] Updating unit groups to use #{workflow_template} for project ##{project.id} (#{project.project_name})"
          unit_groups.each { |ug| ug.save(validate: false) }
        else
          puts "[#{label}] No change to unit groups for project ##{project.id} (#{project.project_name})"
        end
      end
    end
  end
end

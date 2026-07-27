###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'

module HmisUtil
  # Imports project-level Hmis::ProjectConfig records from a CSV for initial customer setup.
  #
  # Prefer org-level or project-type-level rules when possible — project-level configs
  # multiply quickly and are harder to maintain. Use this importer only when projects
  # truly need distinct rules.
  #
  # When a flag cell is false, that config type is skipped (existing records are left alone).
  # Only true flags create/update configs. Absent CSV headers skip that config type entirely.
  # Exception: AutoExit and AutoExitDays must appear together.
  #
  # Usage:
  #   rails driver:hmis:import_project_configs[/path/to/file.csv,true]          # dry run
  #   rails driver:hmis:import_project_configs[/path/to/file.csv,false]         # apply
  #   rails driver:hmis:import_project_configs[/path/to/file.csv,false,123]     # with data source id
  #   rails driver:hmis:import_project_configs[/path/to/file.csv,false,123,true] # skip missing projects
  #
  #   HmisUtil::HmisProjectConfigImporter.new(csv_path: "var/project_settings_2.csv", dry_run: true, skip_projects_not_found: true).run!
  class HmisProjectConfigImporter
    REQUIRED_HEADER = 'ProjectID'
    KNOWN_HEADERS = [
      REQUIRED_HEADER,
      'ProjectName',
      'AutoExit',
      'AutoExitDays',
      'AutoEnter',
      'CE_SendsReferrals',
      'CE_ReceivesDirectReferrals',
      'CE_ReceivesDirectReferralsFrom_ProjectIDs',
      'CE_SupportsWaitlists',
    ].freeze

    class ImportError < StandardError; end

    def initialize(csv_path:, data_source_id: nil, dry_run: false, skip_projects_not_found: false)
      @csv_path = csv_path
      @data_source_id = data_source_id
      @dry_run = dry_run
      @skip_projects_not_found = skip_projects_not_found
      @errors = []
      @skipped_projects = []
    end

    def run!
      rows = load_csv
      validate_headers!(rows.headers)

      # { ProjectID => Project } for all projects in the data source
      projects_by_hud_id = data_source.projects.index_by { |project| project.ProjectID.to_s }

      validated = validate_rows(rows, projects_by_hud_id)

      if @errors.any?
        @errors.each { |msg| puts "ERROR: #{msg}" }
        raise ImportError, "Import aborted with #{@errors.size} error(s). No changes were made."
      end

      @skipped_projects.each { |msg| puts "SKIPPED: #{msg}" }

      Hmis::Hud::Base.transaction do
        apply_rows(validated)
      end

      puts @dry_run ? 'Dry run complete. No changes were saved.' : 'Import complete.'
      puts "Skipped #{@skipped_projects.size} row(s) with ProjectID not found." if @skipped_projects.any?
    end

    private

    def data_source
      @data_source ||= if @data_source_id.present?
        ds = GrdaWarehouse::DataSource.find_by(id: @data_source_id)
        raise ImportError, "Data source ##{@data_source_id} not found" unless ds
        raise ImportError, "Data source ##{@data_source_id} is not an HMIS data source" if ds.hmis.blank?

        ds
      else
        GrdaWarehouse::DataSource.hmis.sole
      end
    end

    def load_csv
      raise ImportError, "CSV file not found: #{@csv_path}" unless File.exist?(@csv_path)

      CSV.read(@csv_path, headers: true)
    end

    def validate_headers!(headers)
      raise ImportError, "CSV is missing required header: #{REQUIRED_HEADER}" unless headers.include?(REQUIRED_HEADER)

      unknown = headers.compact - KNOWN_HEADERS
      raise ImportError, "Unknown CSV headers: #{unknown.join(', ')}" if unknown.any?

      has_auto_exit = headers.include?('AutoExit')
      has_auto_exit_days = headers.include?('AutoExitDays')
      return if has_auto_exit == has_auto_exit_days

      raise ImportError, 'AutoExit and AutoExitDays must both be present (or both omitted)'
    end

    def validate_rows(rows, projects_by_hud_id)
      seen_project_ids = {}
      validated = []

      rows.each_with_index do |row, index|
        row_num = index + 2 # header is row 1
        hud_project_id = row[REQUIRED_HEADER].to_s.strip
        if hud_project_id.blank?
          @errors << "Row #{row_num}: ProjectID is required"
          next
        end

        if seen_project_ids[hud_project_id]
          @errors << "Row #{row_num}: duplicate ProjectID #{hud_project_id} (also on row #{seen_project_ids[hud_project_id]})"
          next
        end
        seen_project_ids[hud_project_id] = row_num

        project = projects_by_hud_id[hud_project_id]
        unless project
          message = "Row #{row_num}: ProjectID #{hud_project_id} (#{row['ProjectName'] || 'name not provided'}) not found in data source ##{data_source.id}"
          if @skip_projects_not_found
            @skipped_projects << message
          else
            @errors << message
          end
          next
        end

        parsed = { row_num: row_num, project: project }
        parsed.merge!(parse_auto_exit(row, row_num)) if row.headers.include?('AutoExit')
        parsed[:auto_enter] = parse_boolean(row['AutoEnter'], 'AutoEnter', row_num) if row.headers.include?('AutoEnter')
        parsed[:ce_sends] = parse_boolean(row['CE_SendsReferrals'], 'CE_SendsReferrals', row_num) if row.headers.include?('CE_SendsReferrals')
        parsed.merge!(parse_ce(row, row_num, projects_by_hud_id)) if ce_headers?(row.headers)

        validated << parsed
      end

      validated
    end

    def ce_headers?(headers)
      headers.include?('CE_ReceivesDirectReferrals') ||
        headers.include?('CE_SupportsWaitlists') ||
        headers.include?('CE_ReceivesDirectReferralsFrom_ProjectIDs')
    end

    def parse_auto_exit(row, row_num)
      auto_exit = parse_boolean(row['AutoExit'], 'AutoExit', row_num)
      days_raw = row['AutoExitDays'].to_s.strip

      days = nil
      if auto_exit
        if days_raw.blank?
          @errors << "Row #{row_num}: AutoExitDays is required when AutoExit is true"
        elsif days_raw !~ /\A\d+\z/
          @errors << "Row #{row_num}: AutoExitDays must be an integer, got #{days_raw.inspect}"
        else
          days = days_raw.to_i
          @errors << "Row #{row_num}: AutoExitDays must be >= 30, got #{days}" if days < 30
        end
      end

      { auto_exit: auto_exit, auto_exit_days: days }
    end

    def parse_ce(row, row_num, projects_by_hud_id)
      result = {}

      result[:ce_receives_direct] = parse_boolean(row['CE_ReceivesDirectReferrals'], 'CE_ReceivesDirectReferrals', row_num) if row.headers.include?('CE_ReceivesDirectReferrals')
      result[:ce_supports_waitlists] = parse_boolean(row['CE_SupportsWaitlists'], 'CE_SupportsWaitlists', row_num) if row.headers.include?('CE_SupportsWaitlists')

      if row.headers.include?('CE_ReceivesDirectReferralsFrom_ProjectIDs')
        primary_keys = parse_from_project_ids(row['CE_ReceivesDirectReferralsFrom_ProjectIDs'], row_num, projects_by_hud_id)
        result[:ce_from_project_ids] = primary_keys if primary_keys.present?
        result[:ce_from_present] = primary_keys.present?
      end

      result
    end

    def parse_from_project_ids(raw, row_num, projects_by_hud_id)
      value = raw.to_s.strip
      return nil if value.blank?

      hud_ids = value.split(',').map(&:strip).reject(&:blank?)
      pks = []
      hud_ids.each do |hud_id|
        project = projects_by_hud_id[hud_id]
        if project
          pks << project.id
        else
          @errors << "Row #{row_num}: CE_ReceivesDirectReferralsFrom_ProjectIDs includes unknown ProjectID #{hud_id}"
        end
      end
      pks
    end

    def parse_boolean(raw, field, row_num)
      value = raw.to_s.strip
      case value.downcase
      when 'true', 'yes' then true
      when 'false', 'no', '' then false
      else
        @errors << "Row #{row_num}: #{field} must be true or false, got #{raw.inspect}"
        nil
      end
    end

    def apply_rows(validated)
      validated.each do |row|
        apply_auto_exit(row) if row.key?(:auto_exit)
        apply_auto_enter(row) if row.key?(:auto_enter)
        apply_ce_sends(row) if row.key?(:ce_sends)
        apply_ce(row) if row.key?(:ce_receives_direct) || row.key?(:ce_supports_waitlists)
      end
    end

    def apply_auto_exit(row)
      return unless row[:auto_exit]

      record = Hmis::ProjectAutoExitConfig.find_or_initialize_by(
        project_id: row[:project].id,
        data_source_id: data_source.id,
      )
      record.enabled = true
      record.length_of_absence_days = row[:auto_exit_days]
      save_config(record, row, 'AutoExit')
    end

    def apply_auto_enter(row)
      return unless row[:auto_enter]

      record = Hmis::ProjectAutoEnterConfig.find_or_initialize_by(
        project_id: row[:project].id,
        data_source_id: data_source.id,
      )
      record.enabled = true
      save_config(record, row, 'AutoEnter')
    end

    def apply_ce_sends(row)
      return unless row[:ce_sends]

      record = Hmis::ProjectSendsDirectCeReferralsConfig.find_or_initialize_by(
        project_id: row[:project].id,
        data_source_id: data_source.id,
      )
      record.enabled = true
      save_config(record, row, 'CE_SendsReferrals')
    end

    def apply_ce(row)
      receives = row[:ce_receives_direct]
      waitlists = row[:ce_supports_waitlists]
      return unless receives == true || waitlists == true

      record = Hmis::ProjectCeConfig.find_or_initialize_by(
        project_id: row[:project].id,
        data_source_id: data_source.id,
      )
      record.enabled = true
      record.receives_direct_referrals = receives unless receives.nil?
      record.supports_waitlist_referrals = waitlists unless waitlists.nil?
      record.receives_direct_referrals_from = row[:ce_from_project_ids] if row[:ce_from_present]
      save_config(record, row, 'CE')
    end

    def save_config(record, row, label)
      project = row[:project]
      prefix = @dry_run ? '[DRY RUN] ' : ''
      project_label = "ProjectID=#{project.ProjectID} (#{project.project_name})"

      if record.new_record?
        puts "#{prefix}CREATE #{label} for #{project_label}"
      elsif record.changed?
        puts "#{prefix}UPDATE #{label} for #{project_label}: #{record.changes.keys.join(', ')}"
      else
        puts "#{prefix}NO CHANGE #{label} for #{project_label}"
        return
      end

      return if @dry_run

      record.save!
    end
  end
end

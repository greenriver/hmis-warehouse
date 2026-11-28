# frozen_string_literal: true

# Copies HMIS form definitions and the configuration they depend on between installations.
# See docs/features/hmis/hmis-form-transfer.md for what's included and how records are matched.
namespace :form_transfer do
  data_source_id = -> { ENV['DATA_SOURCE_ID'].presence&.to_i || HmisUtil::FormTransfer.default_data_source_id }
  list = ->(name) { ENV[name].to_s.split(',').map(&:strip).compact_blank }

  # rails driver:hmis:form_transfer:export[tmp/hmis_forms.json]
  # Optional: IDENTIFIERS=a,b ROLES=SERVICE,CUSTOM_ASSESSMENT PROJECT_IDS=hud_id,... INCLUDE_PROJECTS=false INCLUDE_CE=false DATA_SOURCE_ID=n
  desc 'Export HMIS form definitions and the configuration they depend on to a JSON file'
  task :export, [:filename] => :environment do |_task, args|
    raise ArgumentError, 'Usage: rails driver:hmis:form_transfer:export[FILENAME]' if args.filename.blank?

    HmisUtil::FormTransfer::Exporter.new(
      data_source_id: data_source_id.call,
      identifiers: list.call('IDENTIFIERS'),
      roles: list.call('ROLES'),
      extra_project_ids: list.call('PROJECT_IDS'),
      include_projects: ENV['INCLUDE_PROJECTS'] != 'false',
      include_ce: ENV['INCLUDE_CE'] != 'false',
      source_host: ENV['FQDN'].presence || ENV['HOSTNAME'],
    ).write(args.filename)
  end

  # rails driver:hmis:form_transfer:import[tmp/hmis_forms.json]
  # Optional: DRY_RUN=true DATA_SOURCE_ID=n. Outside development, CONFIRM_IMPORT_INTO must name the Rails environment.
  desc 'Import a file written by form_transfer:export'
  task :import, [:filename] => :environment do |_task, args|
    raise ArgumentError, 'Usage: rails driver:hmis:form_transfer:import[FILENAME]' if args.filename.blank?

    HmisUtil::FormTransfer::Importer.from_file(
      args.filename,
      data_source_id: data_source_id.call,
      dry_run: ENV['DRY_RUN'] == 'true',
      confirm_environment: ENV[HmisUtil::FormTransfer::Importer::CONFIRMATION_ENV_VAR],
    ).run
  end
end

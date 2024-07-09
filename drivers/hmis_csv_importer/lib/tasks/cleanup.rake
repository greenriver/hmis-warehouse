###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :cleanup do
  # rails driver:hmis_csv_importer:cleanup:expire_and_delete
  task :expire_and_delete, [] => [:environment] do
    # Remove any we expired previously
    # HmisCsvImporter::Cleanup::ExpireImportersJob.DeleteExpiredJob.perform_now

    # Determine if we should expire any new data
    HmisCsvImporter::Cleanup::ExpireLoadersJob.perform_later
    HmisCsvImporter::Cleanup::ExpireImportersJob.perform_later
  end

  def check_client_expiration(client:, model:, log_model:, log_id_field:)
    active_ids = model.
      where(data_source_id: client.data_source_id, PersonalID: client.PersonalID).
      where(expired: [nil, false]).
      distinct.
      pluck(log_id_field)
    return if active_ids.empty?

    raise "#{client.id} has too many active ids in #{model.table_name}" if active_ids.size > 500

    max_id = model.
      where(data_source_id: client.data_source_id, PersonalID: client.PersonalID).
      maximum(log_id_field)

    timestamps = log_model.
      where(data_source_id: client.data_source_id).
      where(id: active_ids).order(:id).
      map(&:completed_at).compact.sort.map(&:to_date).uniq

    [
      client.id,
      model.table_name,
      timestamps.join('|'),
      active_ids.join('|'),
      max_id,
      max_id ? (max_id == active_ids.max) : nil,
    ]
  end

  # prints csv
  # sample [50] clients, optional data source. Check that the most recent row in the data/importer table is not expired.
  # also print timestamps and ids of unexpired records
  # rails driver:hmis_csv_importer:cleanup:spot_check_clients[8]
  task :spot_check_clients, [:data_source_id, :limit] => [:environment] do |_task, args|
    # sample some clients
    clients = GrdaWarehouse::Hud::Client.with_deleted
    clients = clients.where(data_source_id: args.data_source_id) if args.data_source_id
    clients = clients.order('RANDOM()').limit(args.limit || 50)
    report = []
    clients.each do |client|
      # puts "Client #{client.data_source_id}:#{client.personal_id}"
      [
        HmisCsvTwentyTwentyFour::Importer::Client,
        HmisCsvTwentyTwentyTwo::Importer::Client,
        HmisCsvTwentyTwenty::Importer::Client,
      ].each do |model|
        row = check_client_expiration(
          client: client,
          model: model,
          log_model: HmisCsvImporter::Importer::ImporterLog,
          log_id_field: :importer_log_id,
        )
        report.push(row) if row
      end

      [
        HmisCsvTwentyTwentyFour::Loader::Client,
        HmisCsvTwentyTwentyTwo::Loader::Client,
        HmisCsvTwentyTwenty::Loader::Client,
      ].each do |model|
        row = check_client_expiration(
          client: client,
          model: model,
          log_model: HmisCsvImporter::Loader::LoaderLog,
          log_id_field: :loader_id,
        )
        report.push(row) if row
      end
    end

    CSV($stdout) do |csv|
      csv << [
        'client_id',
        'table_name',
        'timestamps',
        'active_ids',
        'max_id',
        'valid',
      ]
      report.each { |row| csv << row }
    end
  end

  # prints csv
  # check if a hud record is referenced by an importer/loader table, it should have unexpired rows in that table
  # rails driver:hmis_csv_importer:cleanup:validate_expired_records
  task :validate_expired_records, [] => [:environment] do
    report = []
    [
      [
        HmisCsvTwentyTwentyFour::Importer,
        HmisCsvTwentyTwentyTwo::Importer,
        HmisCsvTwentyTwenty::Importer,
      ],
      [
        HmisCsvTwentyTwentyFour::Loader,
        HmisCsvTwentyTwentyTwo::Loader,
        HmisCsvTwentyTwenty::Loader,
      ],
    ].each do |namespaces|
      [
        GrdaWarehouse::Hud::Affiliation,
        GrdaWarehouse::Hud::Assessment,
        GrdaWarehouse::Hud::AssessmentQuestion,
        GrdaWarehouse::Hud::AssessmentResult,
        GrdaWarehouse::Hud::CeParticipation,
        GrdaWarehouse::Hud::Client,
        GrdaWarehouse::Hud::CurrentLivingSituation,
        # checking this seems expensive since there's so many records
        # GrdaWarehouse::Hud::Disability,
        GrdaWarehouse::Hud::EmploymentEducation,
        GrdaWarehouse::Hud::Enrollment,
        GrdaWarehouse::Hud::Event,
        GrdaWarehouse::Hud::Exit,
        GrdaWarehouse::Hud::Funder,
        GrdaWarehouse::Hud::HealthAndDv,
        GrdaWarehouse::Hud::HmisParticipation,
        GrdaWarehouse::Hud::IncomeBenefit,
        GrdaWarehouse::Hud::Inventory,
        GrdaWarehouse::Hud::Organization,
        # projects are not expired
        # GrdaWarehouse::Hud::Project,
        GrdaWarehouse::Hud::ProjectCoc,
        # checking this seems expensive since there's so many records
        # GrdaWarehouse::Hud::Service,
        GrdaWarehouse::Hud::User,
        GrdaWarehouse::Hud::YouthEducationStatus,
      ].each do |hud_model|
        hud_base_name = hud_model.name.demodulize
        hud_key = hud_model.hud_key
        hud_table_name = hud_model.quoted_table_name

        namespaces.each do |ns|
          next unless ns.const_defined?(hud_base_name)

          table_name = ns.const_get(hud_base_name).quoted_table_name
          join_sql = <<~SQL
            JOIN #{table_name}
              ON #{table_name}.data_source_id = #{hud_table_name}.data_source_id
              AND #{table_name}."#{hud_key}" = #{hud_table_name}."#{hud_key}"
          SQL

          total = hud_model.with_deleted.
            joins(join_sql).
            count("distinct #{hud_table_name}.id")
          active = hud_model.with_deleted.
            joins(join_sql).
            where(%(#{table_name}.expired IS NULL OR #{table_name}.expired = false )).
            count("distinct #{hud_table_name}.id")
          report.push([
                        ns.const_get(hud_base_name).table_name,
                        total,
                        active,
                        (total - active).zero?,
                      ])
        end
      end
    end

    # we expect delta to be zero
    CSV($stdout) do |csv|
      csv << ['table', 'total', 'active', 'valid']
      report.each { |row| csv << row }
    end
  end
end

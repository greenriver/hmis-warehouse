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

  task :spot_check_client, [:id] => [:environment] do |_task, args|
    client = GrdaWarehouse::Hud::Client.with_deleted.find(args.id)

    puts "Client #{client.data_source_id}:#{client.personal_id}"

    max_importer_id = 0
    importer_ids = []
    [
      HmisCsvTwentyTwentyFour::Importer::Client,
      HmisCsvTwentyTwentyTwo::Importer::Client,
      HmisCsvTwentyTwenty::Importer::Client,
    ].each do |model|
      importer_ids += model.
        where(data_source_id: client.data_source_id, PersonalID: client.PersonalID).
        where(expired: [nil, false]).
        pluck('distinct importer_log_id')

      local_max_id = model.
        where(data_source_id: client.data_source_id, PersonalID: client.PersonalID).
        maximum('importer_log_id')
      max_importer_id = [local_max_id, max_importer_id].compact.max
    end
    importer_ids = importer_ids.uniq.sort

    puts 'Importers: '
    puts "  ids: #{importer_ids.join(',')}"
    timestamps = HmisCsvImporter::Importer::ImporterLog.where(data_source_id: client.data_source_id, id: importer_ids).order(:id).map(&:completed_at)
    puts "  Timestamps: #{timestamps.map(&:to_date).join(',')}"

    puts "  UNEXPECTED: #{importer_ids.max} < #{max_importer_id}" if importer_ids.max < max_importer_id

    max_loader_id = 0
    loader_ids = []
    [
      HmisCsvTwentyTwentyFour::Loader::Client,
      HmisCsvTwentyTwentyTwo::Loader::Client,
      HmisCsvTwentyTwenty::Loader::Client,
    ].each do |model|
      loader_ids += model.
        where(data_source_id: client.data_source_id, PersonalID: client.PersonalID).
        where(expired: [nil, false]).
        pluck('distinct loader_id')

      local_max_id = model.
        where(data_source_id: client.data_source_id, PersonalID: client.PersonalID).
        maximum('loader_id')
      max_importer_id = [local_max_id, max_loader_id].compact.max
    end
    loader_ids = loader_ids.uniq.sort

    puts 'Loaders: '
    puts "  ids: #{loader_ids.join(',')}"
    timestamps = HmisCsvImporter::Loader::LoaderLog.where(data_source_id: client.data_source_id, id: loader_ids).order(:id).map(&:completed_at)
    puts "  Timestamps: #{timestamps.map(&:to_date).join(',')}"
    puts "  UNEXPECTED: #{loader_ids.max} < #{max_loader_id}" if loader_ids.max < max_loader_id
  end

  task :validate_expired_records, [] => [:environment] do
    [
      [
        'importer',
        [
          HmisCsvTwentyTwentyFour::Importer,
          HmisCsvTwentyTwentyTwo::Importer,
          HmisCsvTwentyTwenty::Importer,
        ],
      ],
      [
        'loader',
        [
          HmisCsvTwentyTwentyFour::Loader,
          HmisCsvTwentyTwentyTwo::Loader,
          HmisCsvTwentyTwenty::Loader,
        ],
      ],
    ].each do |ns_type, namespaces|
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

        total = 0
        active = 0

        namespaces.each do |ns|
          next unless ns.const_defined?(hud_base_name)

          table_name = ns.const_get(hud_base_name).quoted_table_name
          join_sql = <<~SQL
            JOIN #{table_name}
              ON #{table_name}.data_source_id = #{hud_table_name}.data_source_id
              AND #{table_name}."#{hud_key}" = #{hud_table_name}."#{hud_key}"
          SQL
          total += hud_model.with_deleted.
            joins(join_sql).
            count("distinct #{hud_table_name}.id")
          active += hud_model.with_deleted.
            joins(join_sql).
            where(%(#{table_name}.expired IS NULL OR #{table_name}.expired = false )).
            count("distinct #{hud_table_name}.id")
        end

        # ensure that every record in the hud/importer tables have unexpired records
        if total == active
          puts "OKAY: #{hud_base_name} #{ns_type}, #{total} records referenced"
        else
          puts "ERROR: #{hud_base_name} #{ns_type}, missing #{total - active} out of #{total} records referenced"
        end
      end
    end
  end
end

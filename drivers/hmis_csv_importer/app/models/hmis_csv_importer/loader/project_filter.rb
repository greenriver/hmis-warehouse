###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  class ProjectFilter
    def self.filter(source_dir, data_source_id, post_processor = nil)
      remove_disallowed_client_data(source_dir, calculate_allowed_personal_ids(source_dir, data_source_id))
      post_processor.call(source_dir) if post_processor.present?
    end

    def self.calculate_allowed_personal_ids(source_dir, data_source_id)
      allowed_project_ids = GrdaWarehouse::WhitelistedProjectsForClients.
        where(data_source_id: data_source_id).
        pluck(:ProjectID).
        to_set

      # 1. See if we have you in the database already (which would mean you were in one of those projects previously)
      allowed_personal_ids = GrdaWarehouse::Hud::Client.
        where(data_source_id: data_source_id).
        pluck(:PersonalID).
        to_set

      # 2. See if you have an enrollment in one of the allowed projects in the incoming file.
      file = File.join(source_dir, HmisCsvImporter.enrollment_file_name)

      CSV.foreach(file, headers: true) do |row|
        allowed_personal_ids.add(row['PersonalID']) if allowed_project_ids.include?(row['ProjectID'])
      end
      log "Found #{allowed_personal_ids.size} allowed Personal IDs"

      allowed_personal_ids
    end

    def self.remove_disallowed_client_data(source_dir, allowed_personal_ids)
      HmisCsvImporter.client_related_file_names.each do |filename|
        log "Removing all but allowed rows from #{filename}"
        file = File.join(source_dir, filename)
        next unless File.exist?(file)

        Tempfile.create do |clean_file|
          begin
            CSV.open(clean_file, 'wb') do |csv|
              line = File.open(file).readline
              # Make sure header is in our format
              csv << CSV.parse(line)[0].map { |k| k.downcase.to_sym }
              CSV.foreach(file, headers: true) do |row|
                # only keep row if PersonalID is in allowed clients
                csv << row if allowed_personal_ids.include?(row['PersonalID'])
              end
            end
          rescue CSV::MalformedCSVError => e
            raise e unless CSV.read(clean_file).count == 1
          end
          FileUtils.mv(clean_file, file)
        end
      end
    end

    def self.log(message)
      Rails.logger.info(message)
    end
  end
end

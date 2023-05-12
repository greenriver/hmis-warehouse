###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class Submission < ::HealthBase
    has_one :response
    has_many :submission_external_ids
    has_many :external_ids, through: :submission_external_ids

    def run_and_save!(contact_email, path = nil)
      @timestamp = DateTime.current
      @contact_email = contact_email
      @file_path = path || "var/medicaid_hmis_submission/#{Process.pid}" # Usual Unixism -- create a unique path based on the PID

      FileUtils.mkdir_p(@file_path) unless File.exist?(@file_path)

      submission_file_path, record_count = generate_submission
      metadata_file_path = generate_metadata(record_count)
      zip_path = create_zip_file([submission_file_path, metadata_file_path])

      self.timestamp = generate_timestamp
      self.total_records = record_count
      self.zip_file = File.open(zip_path, 'rb', &:read)
      save!

      zip_path
    end

    def generate_filename(extension: 'txt', prefix: nil, part: nil, suffix: nil)
      "#{prefix}rdc_homeless_#{part}#{timestamp || @timestamp}#{suffix}.#{extension}"
    end

    private def generate_timestamp
      @timestamp.strftime('%Y%m%d%H%M%S')
    end

    private def generate_submission
      file_path = File.join(@file_path, generate_filename)
      count = 0

      GrdaWarehouse::Hud::Client.homeless_on_date.pluck_in_batches(:id) do |batch|
        lines = {}.tap do |results|
          medicaid_ids = ExternalId.where(client_id: batch).
            where.not(valid_id: false).
            group_by(&:client_id).
            transform_values(&:first) # There should only be one MedicaidId

          break unless medicaid_ids.present?

          external_ids << medicaid_ids.values
          GrdaWarehouse::Hud::Client.where(id: medicaid_ids.keys). # X-DB join
            joins(:service_history_enrollments).
            preload(service_history_enrollments: [:enrollment, :service_history_services]).
            merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)).
            find_each do |client|
            homeless_days = 0
            client.service_history_enrollments.each do |enrollment|
              if enrollment.nbn?
                # 30 days for any month w/ service
                months = enrollment.service_history_services.map(&:date).group_by(&:beginning_of_month).keys.count
                homeless_days = [
                  homeless_days,
                  months * 30,
                ].max
              elsif enrollment.so?
                # 30 days for any month w/ CLS
                months = enrollment.enrollment.current_living_situations.map(&:InformationDate).group_by(&:beginning_of_month).keys.count
                homeless_days = [
                  homeless_days,
                  months * 30,
                ].max
              else
                # Days since earliest of entry date or date to street
                lot = (Date.current - [enrollment.enrollment.DateToStreetESSH, enrollment.enrollment.EntryDate].compact.min).to_i
                homeless_days = [
                  homeless_days,
                  lot,
                ].max
              end
            end
            results[medicaid_ids[client.id].identifier] = homeless_days >= 180 ? 'Y' : 'N'
          end
        end
        File.open(file_path, 'a') do |file|
          lines.each do |medicaid_id, homeless_flag|
            file << "#{medicaid_id}|#{homeless_flag}\n"
            count += 1
          end
        end
      end
      [file_path, count]
    end

    private def generate_metadata(record_count)
      file_path = File.join(@file_path, generate_filename(part: 'metadata.'))
      File.open(file_path, 'w') do |file|
        file << "Date Created = \"#{@timestamp.strftime('%Y%m%d')}\"\n"
        file << "RDC_Homeless File Name = \"#{generate_filename}\"\n"
        file << "Total_Records = \"#{record_count}\"\n"
        file << "Return_To = \"#{@contact_email}\"\n"
      end
      file_path
    end

    private def create_zip_file(paths)
      return unless paths.all? { |path| File.exist?(path) }

      zip_path = File.join(@file_path, generate_filename(extension: 'zip'))
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        Array.wrap(paths).each do |file_name|
          zip_file.add(
            File.basename(file_name),
            file_name,
          )
        end
      end
      zip_path
    end

    def remove_export_directory
      FileUtils.rmtree(@file_path) if File.exist?(@file_path)
    end
  end
end

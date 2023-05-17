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

    def submission_filename
      "rdc_homeless_#{timestamp || generate_timestamp}.txt"
    end

    def metadata_filename
      "metadata.#{timestamp || generate_timestamp}.txt"
    end

    def zip_filename
      "rdc_homeless_#{timestamp || generate_timestamp}.zip"
    end

    def response_filename
      "err_rdc_homeless_#{timestamp || generate_timestamp}_details.txt"
    end

    private def generate_timestamp
      @timestamp.strftime('%Y%m%d%H%M%S')
    end

    # Clients are included in the submission if they are enrolled in a homeless project (ES, SH, SO, TH) and not
    # enrolled in PH with a move-in date in the past, on the day the process is run.
    private def generate_submission
      file_path = File.join(@file_path, submission_filename)
      count = 0

      GrdaWarehouse::Hud::Client.homeless_on_date.pluck_in_batches(:id) do |batch|
        lines = {}.tap do |results|
          medicaid_ids = ExternalId.where(client_id: batch).
            where(invalidated_at: nil).
            group_by(&:client_id).
            transform_values(&:first) # There should only be one MedicaidId
          break unless medicaid_ids.present?

          external_ids << medicaid_ids.values
          GrdaWarehouse::Hud::Client.where(id: medicaid_ids.keys). # X-DB join
            joins(service_history_enrollments: :enrollment).
            preload(service_history_enrollments: [:enrollment, :service_history_services]).
            merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)).
            find_each do |client|
            # If a client has more than one enrollment, use the longest duration
            client_homeless_days = 0
            client.service_history_enrollments.each do |enrollment|
              client_homeless_days = [
                client_homeless_days,
                homeless_days(enrollment),
              ].max
            end
            results[medicaid_ids[client.id].identifier] = client_homeless_days >= 180 ? 'Y' : 'N'
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

    # clients in NbN ES are given 30 days for each month they have at least one bed-night record,
    # clients in SO are given 30 days for each month in which they have at least one Current Living Situation record.
    # In addition to the time in shelter, the time between DateToStreetESSH and the start of service is added to the client's time homeless.
    # For entry-exit enrollments, time between DateToStreetESSH (or EntryDate, if none) and the current date is counted toward time homeless.
    private def homeless_days(service_history_enrollment)
      homeless_start_state = [service_history_enrollment.enrollment.DateToStreetESSH, service_history_enrollment.enrollment.EntryDate].compact.min
      if service_history_enrollment.nbn?
        # 30 days for any month w/ service
        service_months = service_history_enrollment.service_history_services.map(&:date).group_by(&:beginning_of_month).keys
        service_days = service_months.count * 30
        # pre-enrollment LOT: earliest of days between date to street or entry date to the earliest of the
        # first service month and entry date (to avoid double counting start of month if first service is
        # in the entry month)
        service_start_date = [service_months.min, service_history_enrollment.enrollment.EntryDate].compact.min
        lot = (service_start_date - homeless_start_state).to_i.
          clamp(0..)

        service_days + lot
      elsif service_history_enrollment.so?
        # 30 days for any month w/ CLS
        service_months = service_history_enrollment.enrollment.current_living_situations.map(&:InformationDate).group_by(&:beginning_of_month).keys
        service_days = service_months.count * 30
        service_start_date = [service_months.min, service_history_enrollment.enrollment.EntryDate].compact.min
        lot = (service_start_date - homeless_start_state).to_i.
          clamp(0..)

        service_days + lot
      else
        # Days since earliest of entry date or date to street
        (Date.current - homeless_start_state).to_i
      end
    end

    private def generate_metadata(record_count)
      file_path = File.join(@file_path, metadata_filename)
      File.open(file_path, 'w') do |file|
        file << "Date Created = \"#{@timestamp.strftime('%Y%m%d')}\"\n"
        file << "RDC_Homeless File Name = \"#{submission_filename}\"\n"
        file << "Total_Records = \"#{record_count}\"\n"
        file << "Return_To = \"#{@contact_email}\"\n"
      end
      file_path
    end

    private def create_zip_file(paths)
      return unless paths.all? { |path| File.exist?(path) }

      zip_path = File.join(@file_path, zip_filename)
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

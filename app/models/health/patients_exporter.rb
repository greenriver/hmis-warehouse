###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class PatientsExporter
    attr_reader :uploaded, :upload_errors

    def initialize(
      patients:,
      configs: nil,
      path: 'tmp/health_export',
      destination: 'carehub_export',
      user: User.system_user
    )
      @patients = patients
      @config = configs.presence&.first || Health::ImportConfig.epic_data.first
      @path = path

      # Enforce today's date in the destination path so we don't overwrite previous exports
      @destination = File.join(@config.path, destination, Date.current.strftime('%Y-%m-%d'))

      @user = user
      @uploaded = []
      @upload_errors = []
      @exported = []
    end

    def export
      @uploaded = []
      @upload_errors = []

      @patients.find_in_batches(batch_size: 100) do |batch|
        batch.each do |patient|
          result = Health::ExportPatient.new(patient: patient, user: @user).export(path: @path)
          @exported << result
          upload_to_sftp(result[:exported])
          cleanup_local_files(result[:exported])
        end
      end

      { uploaded: @uploaded, upload_errors: @upload_errors, exported: @exported }
    end

    private

    def upload_to_sftp(files)
      files.each do |local_path|
        relative_path = local_path.delete_prefix("#{@path}/")
        remote_path = File.join(@destination, relative_path)
        begin
          @config.put_with_mkdir_p(local_path, remote_path)
          @uploaded << relative_path
        rescue StandardError => e
          @upload_errors << { file: relative_path, error: e.message }
        end
      end
    end

    def cleanup_local_files(files)
      files.each do |local_path|
        FileUtils.rm_f(local_path)
      end
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
module GrdaWarehouse::Youth
  class ZipExporter
    def initialize(intakes:, referrals:, dfas:, case_managements:, follow_ups:, housing_resolution_plans:, controller:, file_path: 'var/yya_export')
      @intakes = intakes
      @referrals = referrals
      @dfas = dfas
      @case_managements = case_managements
      @follow_ups = follow_ups
      @housing_resolution_plans = housing_resolution_plans
      @controller = controller
      @file_path = "#{file_path}/#{Process.pid}" # Usual Unixism -- create a unique path based on the PID
    end

    def export!
      create_export_directory
      begin
        @intakes.each do |intake|
          locals = {
            client_intake: intake,
            client_referrals: @referrals.select { |referral| referral.client_id == intake.client_id },
            client_dfas: @dfas.select { |dfa| dfa.client_id == intake.client_id },
            client_case_managements: @case_managements.select { |case_management| case_management.client_id == intake.client_id },
            client_follow_ups: @follow_ups.select { |follow_up| follow_up.client_id == intake.client_id },
            housing_resolution_plans: @housing_resolution_plans.select { |hrp| hrp.client_id == intake.client_id },
          }
          contents = @controller.render_to_string(:per_client, locals: locals)
          name = "Client #{intake.client_id} - #{intake.id}"
          name += ' (HMIS)' if intake.hmis_client?
          name += '.xlsx'
          filename = File.join(@file_path, name)
          File.open(filename, 'w') { |file| file.write(contents) }
        end
        file = create_zip_file
      ensure
        remove_export_directory
      end
      file
    end

    def create_export_directory
      # Remove any old export
      FileUtils.rmtree(@file_path) if File.exist?(@file_path)
      FileUtils.mkdir_p(@file_path)
    end

    def zip_path
      File.join(@file_path, 'yya_export') + '.zip'
    end

    def create_zip_file
      files = Dir.glob(File.join(@file_path, '*')).map { |path| File.basename(path) }
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        files.each do |file_name|
          zip_file.add(
            file_name,
            File.join(@file_path, file_name),
          )
        end
      end
      File.open(zip_path, 'rb', &:read)
    end

    def remove_export_directory
      FileUtils.rmtree(@file_path) if File.exist?(@file_path)
    end
  end
end

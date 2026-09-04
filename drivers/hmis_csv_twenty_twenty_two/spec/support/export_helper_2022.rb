###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ExportHelper2022
  class << self
    attr_reader :data_source, :user, :projects, :enrollments, :clients, :client_class

    def setup_data
      @data_source = FactoryBot.create :source_data_source
      @user = FactoryBot.create :user
      @projects = FactoryBot.create_list :hud_project, 5, data_source_id: @data_source.id

      @enrollments = FactoryBot.create_list :hud_enrollment, 5, data_source_id: @data_source.id, EntryDate: 2.weeks.ago, EnrollmentCoC: 'XX-500'

      @clients = FactoryBot.create_list(
        :hud_client,
        5,
        data_source_id: @data_source.id,
        FirstName: 'abcde' * 12,
        LastName: 'xyz' * 50,
        MiddleName: 'M',
        SSN: Faker::Number.number(digits: 9),
      )

      destination_data_source = FactoryBot.create :grda_warehouse_data_source
      @clients.each do |client|
        attributes = client.attributes
        attributes['data_source_id'] = destination_data_source.id
        attributes['id'] = nil
        dest_client = GrdaWarehouse::Hud::Client.create(attributes)
        GrdaWarehouse::WarehouseClient.create(
          id_in_source: client.PersonalID,
          data_source_id: client.data_source_id,
          source_id: client.id,
          destination_id: dest_client.id,
        )
      end

      @client_class = HmisCsvTwentyTwentyTwo::Exporter::Client
    end

    def cleanup
      @exporter&.remove_export_files
      cleanup_test_environment
    end

    def csv_file_path(klass, exporter:)
      File.join(exporter.file_path, exporter.hmis_class_for(klass).hud_csv_file_name(version: '2022'))
    end
  end
end

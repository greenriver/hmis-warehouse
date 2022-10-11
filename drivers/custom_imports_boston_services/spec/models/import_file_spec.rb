###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe CustomImportsBostonServices::ImportFile, type: :model do
  let!(:warehouse_ds) { create :destination_data_source }
  let!(:ds1) { create :source_data_source }
  let!(:o1) { create :hud_organization, data_source_id: ds1.id }
  let!(:p1) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID, ProjectID: 'P-1' }
  let!(:p2) { create :hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID, ProjectID: 'P-2' }
  let!(:c1) { create :grda_warehouse_hud_client,  data_source_id: ds1.id, PersonalID: 'C-1' }
  let!(:c2) { create :grda_warehouse_hud_client,  data_source_id: ds1.id, PersonalID: 'C-2' }
  let!(:c3) { create :grda_warehouse_hud_client,  data_source_id: ds1.id, PersonalID: 'C-3' }
  let!(:c4) { create :grda_warehouse_hud_client,  data_source_id: ds1.id, PersonalID: 'C-4' }
  let!(:e1) { create :grda_warehouse_hud_enrollment,  data_source_id: ds1.id, PersonalID: 'C-1', EnrollmentID: 'E-1', ProjectID: 'P-1' }
  let!(:e2) { create :grda_warehouse_hud_enrollment,  data_source_id: ds1.id, PersonalID: 'C-2', EnrollmentID: 'E-2', ProjectID: 'P-1' }
  let!(:e3) { create :grda_warehouse_hud_enrollment,  data_source_id: ds1.id, PersonalID: 'C-2', EnrollmentID: 'E-3', ProjectID: 'P-2' }
  let!(:e4) { create :grda_warehouse_hud_enrollment,  data_source_id: ds1.id, PersonalID: 'C-3', EnrollmentID: 'E-4', ProjectID: 'P-2' }
  let!(:e5) { create :grda_warehouse_hud_enrollment,  data_source_id: ds1.id, PersonalID: 'C-4', EnrollmentID: 'E-5', ProjectID: 'P-2' }
  let!(:config) do
    config = GrdaWarehouse::CustomImports::Config.find_by(data_source_id: ds1.id)
    if config.blank?
      config = GrdaWarehouse::CustomImports::Config.create(
        user_id: User.system_user.id,
        data_source_id: ds1.id,
      )
    end
    config
  end

  after(:all) do
    cleanup_test_environment
  end
  after(:each) do
    GrdaWarehouse::CustomImports::Config.delete_all
    CustomImportsBostonServices::ImportFile.delete_all
    CustomImportsBostonServices::Row.delete_all
    GrdaWarehouse::Synthetic::Event.delete_all
    GrdaWarehouse::Generic::Service.delete_all
    GrdaWarehouse::Hud::Event.delete_all
  end
  describe 'after initial import' do
    before(:each) do
      CustomImportsBostonServices::ImportFile.delete_all
      CustomImportsBostonServices::Row.delete_all
      GrdaWarehouse::Synthetic::Event.delete_all
      GrdaWarehouse::Generic::Service.delete_all
      GrdaWarehouse::Hud::Event.delete_all
      import_custom_service('drivers/custom_imports_boston_services/spec/fixtures/first_service_export.csv', config, ds1)
    end
    it 'inserts 6 rows' do
      expect(CustomImportsBostonServices::Row.count).to eq(6)
    end

    it 'creates 6 custom services' do
      expect(GrdaWarehouse::Generic::Service.count).to eq(6)
    end

    it 'creates 0 synthetic events' do
      expect(GrdaWarehouse::Synthetic::Event.count).to eq(0)
    end

    describe 'after hud processing' do
      before do
        GrdaWarehouse::Synthetic::Event.hud_sync
      end

      it 'creates 4 synthetic events' do
        expect(GrdaWarehouse::Synthetic::Event.count).to eq(4)
      end

      it 'creates 4 HUD events' do
        expect(GrdaWarehouse::Hud::Event.count).to eq(4)
        expect(GrdaWarehouse::Hud::Event.where(Event: 4).count).to eq(2)
        expect(GrdaWarehouse::Hud::Event.where(Event: 9).count).to eq(1)
        expect(GrdaWarehouse::Hud::Event.where(Event: 10).count).to eq(1)
      end
    end

    describe 'after second import' do
      before(:each) do
        CustomImportsBostonServices::ImportFile.delete_all
        CustomImportsBostonServices::Row.delete_all
        GrdaWarehouse::Synthetic::Event.delete_all
        GrdaWarehouse::Generic::Service.delete_all
        GrdaWarehouse::Hud::Event.delete_all
        import_custom_service('drivers/custom_imports_boston_services/spec/fixtures/first_service_export.csv', config, ds1)
        import_custom_service('drivers/custom_imports_boston_services/spec/fixtures/second_service_export.csv', config, ds1)
      end

      it 'adds 12 rows' do
        expect(CustomImportsBostonServices::Row.count).to eq(12)
      end

      describe 'after hud processing' do
        before(:each) do
          GrdaWarehouse::Synthetic::Event.hud_sync
        end

        it 'adds and removes 1 synthetic event' do
          expect(GrdaWarehouse::Synthetic::Event.count).to eq(4)
          expect(CustomImportsBostonServices::Synthetic::Event.where(source_id: CustomImportsBostonServices::Row.where(service_id: 'S-1').select(:id)).count).to eq(0)
          expect(CustomImportsBostonServices::Synthetic::Event.where(source_id: CustomImportsBostonServices::Row.where(service_id: 'S-7').select(:id)).count).to eq(1)
        end

        it 'creates 4 HUD events' do
          expect(GrdaWarehouse::Synthetic::Event.count).to eq(4)
          expect(GrdaWarehouse::Hud::Event.count).to eq(4)
          expect(GrdaWarehouse::Hud::Event.where(Event: 4).count).to eq(3)
          expect(GrdaWarehouse::Hud::Event.where(Event: 9).count).to eq(0)
          expect(GrdaWarehouse::Hud::Event.where(Event: 10).count).to eq(1)
        end
      end
    end
  end

  def import_custom_service(file, config, data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    contents = File.read(file)
    import_file = CustomImportsBostonServices::ImportFile.create(
      config_id: config.id,
      data_source_id: data_source.id,
      file: file,
      content: contents,
      content_type: 'text/csv',
      status: 'loading',
    )
    import_file.start_import
    sheet = ::Roo::CSV.new(StringIO.new(contents))
    sheet.parse(headers: true).drop(1)
    import_file.load_csv(sheet)
    import_file.post_process
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing clients' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/client_processing'
      import(file_path, @data_source)
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'the database will have the expected number of source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
    end

    it 'the database will have the expected number of enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
    end

    it 'all clients have a non-nil source_hash' do
      expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
    end

    it 'all enrollments have a non-nil source_hash' do
      expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
    end

    describe 'when re-importing again after nulling source_hash' do
      before(:all) do
        # Force an update
        GrdaWarehouse::Hud::Client.source.update(source_hash: nil)
        file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/client_processing'
        import(file_path, @data_source)
      end

      after(:all) do
        cleanup_files
      end

      it 'all clients have a non-nil source_hash' do
        expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
      end

      it 'all enrollments have a non-nil source_hash' do
        expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
      end

      describe 'when re-importing and the source hash doesn\'t match' do
        before(:all) do
          GrdaWarehouse::Hud::Client.source.update(source_hash: 'aaa')
          file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/client_processing'
          import(file_path, @data_source)
        end

        after(:all) do
          cleanup_files
        end

        it 'all clients have a non-nil source_hash' do
          expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.source.where(source_hash: 'aaa').count).to eq(0)
        end

        it 'all enrollments have a non-nil source_hash' do
          expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
        end

        describe 'when re-importing with changed enrollment' do
          before(:all) do
            file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/client_processing_2'
            import(file_path, @data_source)
          end

          after(:all) do
            cleanup_files
          end

          it 'all clients have a non-nil source_hash' do
            expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
          end

          it 'all enrollments have a non-nil source_hash' do
            expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
          end
        end
      end
    end
  end

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    Importers::HmisAutoDetect::Local.new(
      data_source_id: @data_source.id,
      deidentified: true,
      file_path: import_path,
    ).import!
    Delayed::Worker.new.work_off(2)
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end

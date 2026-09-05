###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RecurringHmisExport, type: :model do
  let(:user) { create(:user) }

  describe '#should_run?' do
    context 'when export has never run' do
      it 'returns true if the record was last updated before today' do
        export = create(:recurring_hmis_export, user: user, updated_at: 2.days.ago)
        expect(export.should_run?).to be true
      end

      it 'returns false when updated today' do
        export = create(:recurring_hmis_export, user: user, updated_at: Time.current)
        expect(export.should_run?).to be false
      end
    end

    context 'when export has prior runs' do
      it 'returns true when the last run is outside the cadence window' do
        export = create(:recurring_hmis_export, :with_history, user: user, every_n_days: 5)
        expect(export.should_run?).to be true
      end

      it 'returns false when the last run is within the cadence window' do
        export = create(:recurring_hmis_export, user: user, every_n_days: 30)
        create(:recurring_hmis_export_link, recurring_hmis_export: export, exported_at: 2.days.ago.to_date)

        expect(export.should_run?).to be false
      end
    end
  end

  describe '#filter_hash' do
    it 'includes the stored options merged with recurrence attributes' do
      export = create(
        :recurring_hmis_export,
        user: user,
        reporting_range: 'month',
        reporting_range_days: 15,
        options: {
          start_date: '2024-01-01',
          end_date: '2024-01-31',
          project_ids: [1, 2],
          version: '2024',
        },
      )

      expect(export.filter_hash).to include(
        reporting_range: 'month',
        reporting_range_days: 15,
        recurring_hmis_export_id: export.id,
        version: '2024',
        user_id: user.id,
      )
    end

    it 'defaults the version to 2026 when not specified' do
      allow(HudHelper).to receive(:current_version).and_return('2026')

      export = create(
        :recurring_hmis_export,
        user: user,
        reporting_range: 'fixed',
        options: {
          start_date: '2024-01-01',
          end_date: '2024-01-31',
        },
      )

      hash = export.filter_hash
      expect(hash[:version]).to eq('2026')
    end
  end

  describe '#run' do
    it 'builds a filter and schedules the job using a real filter instance' do
      export = create(
        :recurring_hmis_export,
        user: user,
        options: {
          start_date: 2.weeks.ago.to_date,
          end_date: 1.week.ago.to_date,
        },
      )

      expect_any_instance_of(Filters::HmisExport).to receive(:adjust_reporting_period)
      expect_any_instance_of(Filters::HmisExport).to receive(:schedule_job).with(report_url: nil)

      export.run
    end
  end

  describe '#s3_valid?' do
    it 'returns false when S3 details are missing' do
      export = build(:recurring_hmis_export, user: user)
      expect(export.s3_valid?).to be false
    end

    it 'validates presence of S3 client when configured' do
      export = build(:recurring_hmis_export, :with_s3_settings, user: user)
      fake_client = instance_double(AwsS3)
      allow(export).to receive(:aws_s3).and_return(fake_client)

      expect(export.s3_valid?).to be true
    end
  end

  describe '#object_name' do
    it 'reflects the export version to match the target standard' do
      export = create(:recurring_hmis_export, :with_s3_settings, user: user, options: { version: '2026' }, s3_prefix: 'nightly')
      allow(export).to receive(:id).and_return(123)
      allow(export).to receive(:encryption_type).and_return(nil)
      report = double(export_id: 999, hmis_zip: double(download: 'zip data'))

      expect(export.object_name(report)).to match(/nightly-.*-999\.zip/)
    end
  end

  # encrypt_seven_zip unzips the export into a scratch directory beside its own
  # Tempfile and then re-archives "#{destination_path}/*.csv" with the 7z
  # binary, so the CSVs having made it into the returned archive is the proof
  # that entry.extract honored destination_directory:. rubyzip 3 joins the
  # entry path onto destination_directory (default '.'), so dropping that
  # argument sends the CSVs to Dir.pwd, leaves the glob matching nothing, and
  # fails both examples.
  describe '#encrypt_seven_zip' do
    include_context 'a zip file to extract'

    let(:export) { create(:recurring_hmis_export, :with_zip_encryption, user: user, encryption_type: '7z') }

    after(:each) do
      extracted_names.each { |name| FileUtils.rm_f(File.join(Dir.pwd, name)) }
    end

    it 'returns 7z content holding every CSV from the source zip' do
      encrypted_path = File.join(scratch_dir, 'encrypted.7z')
      File.binwrite(encrypted_path, export.send(:encrypt_seven_zip, File.binread(zip_source)))

      listing = `7z l -p#{export.zip_password} #{encrypted_path}`
      extracted_names.each { |name| expect(listing).to include(name) }
    end

    it 'writes nothing into the working directory' do
      export.send(:encrypt_seven_zip, File.binread(zip_source))

      extracted_names.each do |name|
        expect(File.exist?(File.join(Dir.pwd, name))).to be(false),
                                                         "#{name} leaked into #{Dir.pwd}; the call site is missing destination_directory:"
      end
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  it 'supports .matches API' do
    [
      'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/enrollment_test_files/source',
    ].each do |path|
      assert HmisCsvTwentyTwenty.matches(path)
    end
  end

  it 'supports .import! API' do
    [
      'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/enrollment_test_files/source',
    ].each do |path|
      file = Tempfile.new('foo')
      data_source = GrdaWarehouse::DataSource.create!(
        name: 'Green River',
        short_name: 'GR',
        source_type: :sftp,
      )
      tmp_path = path.gsub('source', data_source.id.to_s)
      FileUtils.cp_r(path, tmp_path)
      upload = GrdaWarehouse::Upload.create!(
        user_id: User.first,
        data_source_id: data_source.id,
        percent_complete: 0.0,
        file: file,
      )
      log = HmisCsvTwentyTwenty.import!(
        tmp_path,
        data_source.id,
        upload,
        deidentified: false,
      )
      assert log
    ensure
      file&.unlink
      log&.destroy
      upload&.destroy
      data_source&.destroy
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MedicaidHmisInterchange::Health::Submission, type: :model do
  describe '#create_zip_file' do
    include_context 'a directory of files to archive'

    let(:timestamp) { DateTime.current }
    # An unsaved record is enough, given the timestamp run_and_save! would
    # have set.
    let(:submission) do
      described_class.new.tap do |instance|
        instance.instance_variable_set(:@file_path, zip_directory)
        instance.instance_variable_set(:@timestamp, timestamp)
      end
    end
    let(:archive_path) do
      File.join(zip_directory, "rdc_homeless_#{timestamp.strftime(described_class::TIMESTAMP_FORMAT)}.zip")
    end

    def archive!
      submission.send(:create_zip_file, archive_entries.keys.map { |name| File.join(zip_directory, name) })
    end

    include_examples 'creates a zip archive of a directory of files'
  end
end

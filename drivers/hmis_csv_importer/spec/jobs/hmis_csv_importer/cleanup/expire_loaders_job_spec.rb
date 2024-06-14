###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'shared_contexts'

RSpec.describe HmisCsvImporter::Cleanup::ExpireLoadersJob, type: :model do
  include_context 'HmisCsvImporter cleanup context'

  def records
    HmisCsvTwentyTwentyFour::Loader::Organization
  end

  def run_job(retain_after_date:, retain_log_count:)
    HmisCsvImporter::Cleanup::ExpireLoadersJob.new.perform(
      data_source_id: data_source.id,
      retain_log_count: retain_log_count,
      retain_after_date: retain_after_date,
    )
  end

  describe 'with 3 daily imports' do
    let(:run_times) do
      time = now - 1.minute
      [time - 2.days, time - 1.days, time]
    end

    before(:each) do
      run_times.each { |run_time| import_csv_records(run_at: run_time) }
    end

    it 'retains records within period' do
      expect do
        run_job(retain_after_date: run_times[1] - 1.minute, retain_log_count: 1)
      end.to change { records.where(expired: true).count }.from(0).to(1).
      and change { records.where(expired: false).count }.from(0).to(2)
    end

    it 'retains only the last X records' do
      expect do
        run_job(retain_after_date: now, retain_log_count: 1)
      end.to change { records.where(expired: true).count }.from(0).to(2).
      and change { records.where(expired: false).count }.from(0).to(1)
    end
  end
end

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::ActivityLogProcessorJob, type: :model do
  subject(:job) { Hmis::ActivityLogProcessorJob }

  let!(:ds1) { create(:hmis_data_source) }

  let!(:p1) { create :hmis_hud_project, data_source: ds1 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:assessment1) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e1) }

  record_permutations = [
    ['with non-deleted', nil],
    ['with deleted', ->(record) { record.destroy! }],
  ]
  [
    { 'Enrollment/%{enrollment_id}' => [] },
    { 'EnrollmentSummary/%{enrollment_id}' => [] },
    { 'Assessment/%{assessment_id}' => [] },
  ].each do |resolved_fields_template|
    record_permutations.each do |label, transformer|
      describe "#{label} enrollment-related access log #{resolved_fields_template.inspect}}" do
        before(:each) do
          resolved_fields = resolved_fields_template.transform_keys do |key|
            format(key, enrollment_id: e1.id, assessment_id: assessment1.id)
          end
          create :hmis_activity_log, resolved_fields: resolved_fields, data_source: ds1
          transformer&.call(e1.destroy)
        end

        it 'should link to enrollment and client' do
          expect do
            job.perform_now
          end.to change(Hmis::EnrollmentAccessSummary.where(enrollment_id: e1.id), :count).by(1).
            and change(Hmis::ClientAccessSummary.where(client_id: c1.id), :count).by(1).
            and change(Hmis::ActivityLog.unprocessed, :count).by(-1)
        end
      end
    end
  end

  record_permutations.each do |label, transformer|
    describe "#{label} client-related access log" do
      before(:each) do
        create :hmis_activity_log, resolved_fields: { "Client/#{c1.id}" => [] }
        transformer&.call(e1.destroy)
      end

      it 'should link to client' do
        expect do
          job.perform_now
        end.to not_change(Hmis::EnrollmentAccessSummary, :count).
          and change(Hmis::ClientAccessSummary.where(client_id: c1.id), :count).by(1).
          and change(Hmis::ActivityLog.unprocessed, :count).by(-1)

        # also check for idempotent behavior
        expect do
          job.perform_now
        end.to not_change(Hmis::EnrollmentAccessSummary, :count).
          and not_change(Hmis::ClientAccessSummary, :count).
          and not_change(Hmis::ActivityLog.unprocessed, :count)
      end
    end
  end
end

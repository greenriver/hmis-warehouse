# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../app/services/hmis/merge_enrollments' # https://github.com/greenriver/rails_drivers/blob/master/lib/rails_drivers/setup.rb#L5-L15
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::MergeEnrollments, type: :service do
  include_context 'hmis base setup'

  let!(:e_retain) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1) }
  let!(:e_destroy) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1) }
  let!(:service_on_destroy) do
    create(:hmis_hud_service, data_source: ds1, client: c1, enrollment: e_destroy)
  end

  def run_merge(dry_run: false)
    Hmis::MergeEnrollments.new(enrollment_to_retain: e_retain.id, enrollment_to_destroy: e_destroy.id).run!(dry_run: dry_run)
  end

  describe 'validation' do
    it 'raises if trying to merge enrollments belonging to different clients' do
      c2 = create(:hmis_hud_client, data_source: ds1)
      e_other_client = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c2)

      merge = Hmis::MergeEnrollments.new(enrollment_to_retain: e_retain.id, enrollment_to_destroy: e_other_client.id)
      expect(merge).not_to be_valid
      expect(merge.errors).to include(match(/same client/))

      expect { merge.run!(dry_run: false) }.to raise_error(StandardError, /same client/)
    end

    it 'raises if trying to merge enrollments belonging to different projects' do
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
      e_other_project = create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: c1)

      merge = Hmis::MergeEnrollments.new(enrollment_to_retain: e_retain.id, enrollment_to_destroy: e_other_project.id)
      expect(merge).not_to be_valid
      expect(merge.errors).to include(match(/same HMIS project/))

      expect { merge.run!(dry_run: false) }.to raise_error(StandardError, /same HMIS project/)
    end
  end

  describe '#run!(dry_run: true)' do
    it 'does not change any records' do
      retain_id = e_retain.id
      destroy_id = e_destroy.id
      service_enrollment_id_before = service_on_destroy.reload.enrollment_id
      enrollment_count_before = Hmis::Hud::Enrollment.count

      run_merge(dry_run: true)

      expect(Hmis::Hud::Enrollment.count).to eq(enrollment_count_before)
      expect(Hmis::Hud::Enrollment.exists?(retain_id)).to be true
      expect(Hmis::Hud::Enrollment.exists?(destroy_id)).to be true
      expect(service_on_destroy.reload.enrollment_id).to eq(service_enrollment_id_before)
      expect(service_on_destroy.enrollment_id).to eq(destroy_id)
    end
  end

  describe 'merge scenarios' do
    it 'is able to merge exited enrollments' do
      e_retain_exited = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, exit_date: 1.week.ago)
      e_destroy_exited = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, exit_date: 5.days.ago)

      expect do
        Hmis::MergeEnrollments.new(enrollment_to_retain: e_retain_exited.id, enrollment_to_destroy: e_destroy_exited.id).run!(dry_run: false)
      end.to change(Hmis::Hud::Enrollment, :count).by(-1)

      expect(Hmis::Hud::Enrollment.exists?(e_destroy_exited.id)).to be false
      expect(e_retain_exited.reload).to be_persisted
    end

    it 'is able to merge WIP enrollments' do
      e_retain_wip = create(:hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1)
      e_destroy_wip = create(:hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1)

      expect do
        Hmis::MergeEnrollments.new(enrollment_to_retain: e_retain_wip.id, enrollment_to_destroy: e_destroy_wip.id).run!(dry_run: false)
      end.to change(Hmis::Hud::Enrollment, :count).by(-1)

      expect(Hmis::Hud::Enrollment.exists?(e_destroy_wip.id)).to be false
      expect(e_retain_wip.reload).to be_persisted
    end
  end

  describe 'related records merge (or not) correctly' do
    let!(:intake_on_destroy) do
      create(:hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e_destroy, data_collection_stage: 1)
    end
    let!(:update_assessment_on_destroy) do
      create(:hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e_destroy, data_collection_stage: 2)
    end
    let!(:health_and_dv_on_destroy) do
      create(:hmis_health_and_dv, data_source: ds1, client: c1, enrollment: e_destroy)
    end
    let!(:case_note_on_destroy) do
      create(:hmis_hud_custom_case_note, data_source: ds1, client: c1, enrollment: e_destroy, user: u1)
    end

    before do
      run_merge(dry_run: false)
    end

    it 'does not move intake assessment (it is destroyed with enrollment_to_destroy)' do
      # Intake assessments are not moved; enrollment_to_destroy is destroyed so intake is gone
      expect(Hmis::Hud::CustomAssessment.exists?(intake_on_destroy.id)).to be false
      expect(e_retain.reload.custom_assessments.where(data_collection_stage: 1)).not_to include(intake_on_destroy)
    end

    it 'moves update assessment to retained enrollment' do
      update_assessment_on_destroy.reload
      expect(update_assessment_on_destroy.enrollment.id).to eq(e_retain.id)
      expect(update_assessment_on_destroy.enrollment_id).to eq(e_retain.enrollment_id)
      expect(e_retain.custom_assessments.where.not(data_collection_stage: [1, 3])).to include(update_assessment_on_destroy)
    end

    it 'moves health_and_dv to retained enrollment' do
      health_and_dv_on_destroy.reload
      expect(health_and_dv_on_destroy.enrollment.id).to eq(e_retain.id)
      expect(health_and_dv_on_destroy.enrollment_id).to eq(e_retain.enrollment_id)
    end

    it 'moves service to retained enrollment' do
      service_on_destroy.reload
      expect(service_on_destroy.enrollment.id).to eq(e_retain.id)
      expect(service_on_destroy.enrollment_id).to eq(e_retain.enrollment_id)
    end

    it 'moves case note to retained enrollment' do
      case_note_on_destroy.reload
      expect(case_note_on_destroy.enrollment.id).to eq(e_retain.id)
      expect(case_note_on_destroy.enrollment_id).to eq(e_retain.enrollment_id)
    end

    context 'with a CE referral referencing enrollment_to_destroy' do
      let!(:target_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
      let!(:target_unit) { create(:hmis_unit, project: target_project) }
      let!(:target_opportunity) { create(:hmis_ce_opportunity, unit: target_unit) }
      let!(:referral_with_source_enrollment) do
        create(:hmis_ce_referral, data_source: ds1, opportunity: target_opportunity, source_enrollment: e_destroy, client: c1)
      end

      it 'moves referral source_enrollment_id to retained enrollment' do
        referral_with_source_enrollment.reload
        expect(referral_with_source_enrollment.source_enrollment_id).to eq(e_retain.id)
        expect(referral_with_source_enrollment.source_enrollment).to eq(e_retain)
      end
    end
  end
end

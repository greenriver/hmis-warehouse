###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MigrateAssessmentsJob, type: :model do
  context 'builds simple assesssment' do
    let!(:ds1) { create(:hmis_data_source) }
    let!(:u1) { create :hmis_hud_user, data_source: ds1 }
    let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let(:time_fmt) { '%Y-%m-%d %T.%3N'.freeze }

    # Full record set for Entry and Annual
    let!(:records_by_data_collaction_stage) do
      result = {}
      [
        [1, 1.month.ago], # Entry
        [2, 1.week.ago], # Update
        [3, 1.day.ago], # Exit
      ].each do |dcs, date|
        records = []
        shared_attributes = {
          data_source: ds1,
          enrollment: e1,
          client: c1,
          data_collection_stage: dcs,
          information_date: date,
          date_created: date,
          date_updated: date,
        }
        # If this is entry or exit, offset the date for one record to ensure that it still gets grouped into one assessment
        records << create(:hmis_income_benefit, **shared_attributes, information_date: [1, 3].include?(dcs) ? date - 2.days : date)
        # Offset some of the date_created values to ensure earliest is chosen
        records << create(:hmis_health_and_dv, **shared_attributes, date_created: date - 1.day)
        records << create(:hmis_youth_education_status, **shared_attributes, date_created: date - 2.days)
        # Offset some of the date_updated values to ensure latest is chosen
        records << create(:hmis_employment_education, **shared_attributes, date_updated: date - 7.days)

        # create 1 record per disability type
        HudUtility2024.disability_types.keys.each do |typ|
          records << create(:hmis_disability, disability_type: typ, **shared_attributes)
        end

        if dcs == 3
          records << create(
            :hmis_hud_exit,
            exit_date: date,
            **shared_attributes.except(:data_collection_stage, :information_date),
          )
        end
        result[dcs] = records
      end
      result
    end

    describe 'happy path' do
      it 'creates new assessments correctly when all records are available' do
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)

        expect(e1.custom_assessments.count).to eq(3)
        expect(e1.custom_assessments.map(&:data_collection_stage).sort).to eq([1, 2, 3])
        [1, 2, 3].each do |dcs|
          assessment = e1.custom_assessments.where(data_collection_stage: dcs).first!
          expected_records = records_by_data_collaction_stage[dcs]
          # Assessment Date should be MIN from records
          expected_assmt_date = expected_records.map { |r| r.respond_to?(:information_date) ? r.information_date : r.exit_date }.min
          expect(assessment.assessment_date).to eq(expected_assmt_date)
          # User should be the most recent updated
          expect(assessment.user).to eq(expected_records.max_by(&:date_updated).user)
          # Date created should be MIN from records
          expect(assessment.date_created.strftime(time_fmt)).to eq(expected_records.map(&:date_created).min.strftime(time_fmt))
          # Date updated should be MAX from records
          expect(assessment.date_updated.strftime(time_fmt)).to eq(expected_records.map(&:date_updated).max.strftime(time_fmt))

          related_records = [
            :health_and_dv,
            :income_benefit,
            :physical_disability,
            :developmental_disability,
            :chronic_health_condition,
            :hiv_aids,
            :mental_health_disorder,
            :substance_use_disorder,
            :exit,
            :youth_education_status,
            :employment_education,
            :current_living_situation,
          ].map do |rec|
            assessment.send(rec)
          end.uniq.compact

          expect(related_records.size).to eq(expected_records.size), "Data collection stage #{dcs}"
          expect(related_records).to include(*expected_records), "Data collection stage #{dcs}"
        end
      end

      it 'creates assessments only in specified projects' do
        p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
        e2 = create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: c1)
        create(:hmis_income_benefit, data_source: ds1, enrollment: e2, client: c1, data_collection_stage: 1)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, project_ids: [p2.id])

        expect(e1.custom_assessments).to be_empty # didn't create assessment for p1 enrollment
        expect(e2.intake_assessment).to be_present
      end

      it 'creates assessments only in specified enrollment scope' do
        e2 = create(:hmis_hud_enrollment, data_source: ds1, client: c1)

        enrollments = Hmis::Hud::Enrollment.where(id: e2.id)
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, enrollments: enrollments, generate_empty_intakes: true)

        expect(e1.custom_assessments).to be_empty # didn't create assessment for p1 enrollment
        expect(e2.intake_assessment).to be_present
      end

      it 'creates assessments only in specified projects (no assessments to create)' do
        p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
        num = Hmis::Hud::CustomAssessment.all.size
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, project_ids: [p2.id])
        expect(Hmis::Hud::CustomAssessment.all.size).to eq(num)
      end

      it 'does nothing if assessment exists' do
        entry_assessment = create(:hmis_custom_assessment, data_collection_stage: 1, assessment_date: 1.month.ago, enrollment: e1, data_source: ds1, client: c1)
        old_form_processor = entry_assessment.form_processor
        expect(e1.custom_assessments.intakes.size).to eq(1)
        expect(e1.intake_assessment.form_processor).to eq(old_form_processor)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)

        expect(e1.custom_assessments.intakes.size).to eq(1)
        expect(e1.intake_assessment).to eq(entry_assessment)
        expect(e1.intake_assessment.form_processor).to eq(old_form_processor)
      end

      it 'ignores records tied to wip enrollments' do
        e1.save_in_progress
        expect do
          Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)
        end.to change(e1.custom_assessments, :count).by(0)
      end

      it 'clobbers existing HUD assessments without clobbering fully custom assessments' do
        intake_assessment = create(:hmis_custom_assessment, data_collection_stage: 1, assessment_date: 1.month.ago, enrollment: e1, data_source: ds1, client: c1)
        annual_assessment = create(:hmis_custom_assessment, data_collection_stage: 5, assessment_date: 1.day.ago, enrollment: e1, data_source: ds1, client: c1)
        fully_custom_assessment = create(:hmis_custom_assessment, data_collection_stage: 99, assessment_date: 2.days.ago, enrollment: e1, data_source: ds1, client: c1)
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, clobber: true)
        expect { intake_assessment.reload }.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find Hmis::Hud::CustomAssessment/)
        expect { annual_assessment.reload }.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find Hmis::Hud::CustomAssessment/)
        fully_custom_assessment.reload
        expect(fully_custom_assessment.enrollment).to eq(e1)
      end
    end

    describe 'when generate_empty_intakes: true' do
      it 'generates a synthetic intake for a non-wip enrollment with no records' do
        e2 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1)
        expect(e2.intake_assessment).to be_nil
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, generate_empty_intakes: true)
        e2.reload
        expect(e2.intake_assessment).not_to be_nil
        expect(e2.intake_assessment.in_progress?).to eq(false)
        expect(e2.intake_assessment.assessment_date).to eq(e2.entry_date)
        expect(e2.intake_assessment.form_processor).not_to be_nil

        # e1 should still only have 1 intake assessment, with the records present
        expect(e1.custom_assessments.where(data_collection_stage: 1).count).to eq(1)
        expect(e1.intake_assessment.form_processor.health_and_dv).to be_present
      end

      it 'works even if enrollment has a bad UserID' do
        enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, UserID: 'a-non-existent-user-id')

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, generate_empty_intakes: true)
        expect(enrollment.reload.intake_assessment).to be_present
      end

      it 'works even if enrollment is missing UserID' do
        enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1)
        enrollment.UserID = nil
        enrollment.save!(validate: false)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, generate_empty_intakes: true)
        expect(enrollment.reload.intake_assessment).to be_present
      end

      it 'does not generate for wip enrollment' do
        enrollment = create(:hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, generate_empty_intakes: true)
        expect(enrollment.reload.intake_assessment).to be_nil
      end
    end

    describe 'bad data' do
      it 'doesnt create a second intake assessment' do
        # Create a second IncomeBenefit record at Entry that has a different information date
        create(:hmis_income_benefit, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 1, information_date: 1.week.ago)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)

        expect(e1.custom_assessments.intakes.count).to eq(1)
      end

      it 'deletes dangling records if specified (duplicates)' do
        dup1 = create(:hmis_income_benefit, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 1, information_date: 1.week.ago, date_created: 2.month.ago, date_updated: 2.months.ago)
        dup2 = create(:hmis_income_benefit, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 1, information_date: 1.week.ago, date_created: 3.months.ago, date_updated: 3.months.ago)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, delete_dangling_records: true)

        expect(e1.custom_assessments.intakes.count).to eq(1)

        [dup1, dup2].each(&:reload)
        expect(dup1.date_deleted).to be_present
        expect(dup2.date_deleted).to be_present
      end

      it 'deletes dangling records if specified (exit dcs on open en)' do
        # Remove exit for e1
        e1.exit.destroy

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, delete_dangling_records: true)

        expect(e1.custom_assessments.intakes.count).to eq(1)
        expect(e1.custom_assessments.exits.count).to eq(0) # no exit assessment created

        # Exit-related records should all be deleted
        records_by_data_collaction_stage[3].each(&:reload).each do |record|
          expect(record.date_deleted).to be_present, record.class.name
        end
      end

      it 'prefers specific source hash for duplicate records' do
        education_status1 = records_by_data_collaction_stage[1].find { |record| record.instance_of?(Hmis::Hud::YouthEducationStatus) }
        # create a duplicate record that is older, but has the preferred hash
        education_status2 = create(:hmis_youth_education_status, source_hash: 'PREFERRED_HASH', date_created: education_status1.date_updated - 1.day, **education_status1.slice(:data_source, :enrollment, :client, :data_collection_stage, :information_date, :date_created))

        # without hash preference, it should choose education_status1
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)
        expect(e1.custom_assessments.intakes.first.form_processor.youth_education_status).to eq(education_status1)

        # with hash preference, it should choose education_status2
        e1.custom_assessments.intakes.first.destroy!
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, delete_dangling_records: true, preferred_source_hash: 'PREFERRED_HASH')

        expect(e1.custom_assessments.intakes.count).to eq(1)
        expect(e1.custom_assessments.intakes.first.form_processor.youth_education_status).to eq(education_status2)

        education_status1.reload
        expect(education_status1.date_deleted).to be_present
      end

      it 'attaches record to exit assessment even if the information date is null' do
        health_and_dv = records_by_data_collaction_stage[3].find { |record| record.instance_of?(Hmis::Hud::HealthAndDv) }
        health_and_dv.update(information_date: nil)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)

        expect(e1.custom_assessments.exits.count).to eq(1)
        expect(e1.custom_assessments.exits.first.form_processor.health_and_dv).to eq(health_and_dv)
      end

      it 'does not generate an empty intake assessment if there is an existing, invalid one' do
        e2 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 1.week.from_now)
        expect(e2.intake_assessment).to be_nil
        create(:hmis_income_benefit, data_source: ds1, enrollment: e2, client: c1, data_collection_stage: 1, information_date: 1.week.ago)
        c1.destroy! # Deleting the client causes this assessment to be invalid
        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id, generate_empty_intakes: true)
        e2.reload
        expect(e2.intake_assessment).to be_nil, 'An empty intake assessment should not be generated if the assessment is invalid'
      end
    end
  end
end

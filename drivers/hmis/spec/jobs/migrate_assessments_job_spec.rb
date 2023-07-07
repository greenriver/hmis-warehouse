###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        records << create(:hmis_enrollment_coc, **shared_attributes, date_updated: date - 3.days)

        # create 1 record per disability type
        HudLists.disability_type_map.keys.each do |typ|
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
            :enrollment_coc,
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

      it 'does nothing if assessment exists' do
        entry_assessment = create(:hmis_custom_assessment, data_collection_stage: 1, assessment_date: 1.month.ago, enrollment: e1, data_source: ds1, client: c1)
        old_form_processor = entry_assessment.form_processor
        expect(e1.custom_assessments.count).to eq(1)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)

        expect(e1.custom_assessments.count).to eq(3)
        expect(e1.custom_assessments).to include(entry_assessment)
        expect(e1.custom_assessments.intakes.first.form_processor).to eq(old_form_processor)
      end
    end

    describe 'bad data' do
      # Not handled yet, job should probably be made more robust in dealing with bad data
      xit 'doesnt create a second intake assessment' do
        # Create a second IncomeBenefit record at Entry that has a different information date
        create(:hmis_income_benefit, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 1, information_date: 1.week.ago)

        Hmis::MigrateAssessmentsJob.perform_now(data_source_id: ds1.id)

        expect(e1.custom_assessments.intakes.count).to eq(1)
      end
    end
  end
end

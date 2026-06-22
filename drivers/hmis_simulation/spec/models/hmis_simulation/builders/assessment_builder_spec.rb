###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::AssessmentBuilder do
  include_context 'hmis simulation builder setup'

  let(:date)    { Date.new(2026, 4, 1) }
  let(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }

  def build(rng_seed: 42)
    described_class.new(
      enrollment: enrollment,
      date: date,
      data_source: data_source,
      user_id: user_id,
      rng_seed: rng_seed,
    ).build!
  end

  describe '#build!' do
    it 'creates one Assessment record' do
      expect { build }.to change { Hmis::Hud::Assessment.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE AssessmentID' do
      expect(build.AssessmentID).to start_with('FAKE')
    end

    it 'sets AssessmentDate to the provided date' do
      expect(build.AssessmentDate).to eq(date)
    end

    it 'sets AssessmentType to a valid code (1-3)' do
      expect([1, 2, 3]).to include(build.AssessmentType)
    end

    it 'sets AssessmentLevel to 1 or 2' do
      expect([1, 2]).to include(build.AssessmentLevel)
    end

    it 'sets PrioritizationStatus to 1 or 2' do
      expect([1, 2]).to include(build.PrioritizationStatus)
    end

    it 'links to the correct enrollment' do
      assessment = build
      expect(assessment.EnrollmentID).to eq(enrollment.EnrollmentID)
      expect(assessment.PersonalID).to eq(enrollment.PersonalID)
    end

    it 'creates 3 to 5 AssessmentResult records' do
      assessment = build
      result_count = Hmis::Hud::AssessmentResult.where(
        data_source: data_source,
        AssessmentID: assessment.AssessmentID,
      ).count
      expect(result_count).to be_between(3, 5)
    end

    it 'links AssessmentResults to the assessment via AssessmentID' do
      assessment = build
      results = Hmis::Hud::AssessmentResult.where(
        data_source: data_source,
        AssessmentID: assessment.AssessmentID,
      )
      results.each do |r|
        expect(r.EnrollmentID).to eq(enrollment.EnrollmentID)
        expect(r.PersonalID).to eq(enrollment.PersonalID)
        expect(r.AssessmentResultType).to be_present
        expect(r.AssessmentResult).to be_present
      end
    end

    it 'produces varied result counts across different seeds' do
      counts = 10.times.map { |i| build(rng_seed: i) }.map do |assessment|
        Hmis::Hud::AssessmentResult.where(
          data_source: data_source,
          AssessmentID: assessment.AssessmentID,
        ).count
      end
      expect(counts.uniq.length).to be > 1
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'Participation overlap validation', type: :model do
  include_context 'hmis base setup'

  # Run the same overlap scenarios for HMIS and CE Participation.
  shared_examples 'participation overlap validation' do |factory_name:, start_attribute:, end_attribute:, unrelated_attribute:, unrelated_value:|
    # Default setup: one closed range followed by one adjacent open range.
    let(:existing_start_date) { Date.new(2020, 1, 1) }
    let(:existing_end_date) { Date.new(2020, 12, 31) }
    let(:candidate_start_date) { Date.new(2021, 1, 1) }
    let(:candidate_end_date) { nil }
    let(:candidate_project) { p1 }
    let(:candidate_data_source) { candidate_project.data_source }

    let!(:existing) do
      create(
        factory_name,
        data_source: ds1,
        project: p1,
        user: u1,
        start_attribute => existing_start_date,
        end_attribute => existing_end_date,
      )
    end

    subject(:candidate) do
      build(
        factory_name,
        data_source: candidate_data_source,
        project: candidate_project,
        user: candidate_project.user,
        start_attribute => candidate_start_date,
        end_attribute => candidate_end_date,
      )
    end

    # Check that validation fails on each expected field.
    def expect_overlap_error(record, *attributes)
      expect(record).not_to be_valid
      attributes.each do |attribute|
        expect(record.errors[attribute]).to include(Hmis::Hud::Validators::ParticipationValidator::OVERLAP_MESSAGE)
      end
    end

    context 'when creating a record' do
      # The new range starts on the existing range's final included date.
      context 'with a boundary date included by an existing record' do
        let(:candidate_start_date) { existing_end_date }

        it 'rejects the inclusive boundary overlap' do
          expect_overlap_error(candidate, start_attribute, end_attribute)
        end
      end

      # The new range is fully inside the existing range.
      context 'with a range contained by an existing record' do
        let(:candidate_start_date) { Date.new(2020, 3, 1) }
        let(:candidate_end_date) { Date.new(2020, 6, 30) }

        it 'rejects the contained range' do
          expect_overlap_error(candidate, start_attribute, end_attribute)
        end
      end

      # The new range starts before and ends after the existing range.
      context 'with a range containing an existing record' do
        let(:candidate_start_date) { Date.new(2019, 1, 1) }
        let(:candidate_end_date) { Date.new(2021, 1, 1) }

        it 'rejects the containing range' do
          expect_overlap_error(candidate, start_attribute, end_attribute)
        end
      end

      # An existing range with no end date overlaps every later range.
      context 'when the existing record is open-ended' do
        let(:existing_end_date) { nil }

        it 'rejects a later range' do
          expect_overlap_error(candidate, start_attribute, end_attribute)
        end
      end

      # Two ranges with no end date overlap.
      context 'when both records are open-ended' do
        let(:existing_end_date) { nil }
        let(:candidate_end_date) { nil }

        it 'rejects the second open-ended record' do
          expect_overlap_error(candidate, start_attribute, end_attribute)
        end
      end

      # The new range starts one day after the existing range ends.
      context 'with an adjacent range' do
        it 'allows the day after the existing range ends' do
          expect(candidate).to be_valid
        end
      end

      # A period with no participation separates the two ranges.
      context 'with a gap between ranges' do
        let(:candidate_start_date) { Date.new(2021, 2, 1) }

        it 'allows the range' do
          expect(candidate).to be_valid
        end
      end

      # Matching dates do not conflict across projects.
      context 'when matching dates belong to another project' do
        let(:candidate_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
        let(:candidate_start_date) { existing_start_date }
        let(:candidate_end_date) { existing_end_date }

        it 'allows the range' do
          expect(candidate).to be_valid
        end
      end

      # Matching dates and ProjectID do not conflict across data sources.
      context 'when matching dates and ProjectID belong to another data source' do
        let(:other_data_source) { create(:hmis_data_source) }
        let(:candidate_project) do
          create(
            :hmis_hud_project,
            data_source: other_data_source,
            ProjectID: p1.ProjectID,
          )
        end
        let(:candidate_start_date) { existing_start_date }
        let(:candidate_end_date) { existing_end_date }

        it 'allows the range' do
          expect(candidate).to be_valid
        end
      end

      # Soft-deleted records are not part of the sibling lookup.
      context 'when the overlapping sibling is soft-deleted' do
        before { existing.destroy! }

        let(:candidate_start_date) { existing_start_date }
        let(:candidate_end_date) { existing_end_date }

        it 'ignores the deleted record' do
          expect(candidate).to be_valid
        end
      end
    end

    context 'when updating a record' do
      # A persisted record must not conflict with its own saved row.
      it 'excludes the record itself from overlap checks' do
        existing.assign_attributes(end_attribute => Date.new(2021, 1, 31))

        expect(existing).to be_valid
      end

      # Extending a saved range into another saved range must fail.
      it 'rejects a date change that introduces an overlap' do
        later_record = create(
          factory_name,
          data_source: ds1,
          project: p1,
          user: u1,
          start_attribute => Date.new(2021, 2, 1),
          end_attribute => nil,
        )

        existing.assign_attributes(end_attribute => later_record.public_send(start_attribute))

        expect_overlap_error(existing, start_attribute, end_attribute)
      end

      context 'with a pre-existing overlap' do
        # Simulate invalid legacy data created before this validation existed.
        let!(:overlapping_record) do
          build(
            factory_name,
            data_source: ds1,
            project: p1,
            user: u1,
            start_attribute => Date.new(2020, 6, 1),
            end_attribute => nil,
          ).tap { |record| record.save!(validate: false) }
        end

        # Changing a date without removing the existing overlap must fail.
        it 'rejects a date change that retains the overlap' do
          overlapping_record.assign_attributes(start_attribute => Date.new(2020, 7, 1))

          expect_overlap_error(overlapping_record, start_attribute, end_attribute)
        end

        # Changing a date so the ranges become adjacent must pass.
        it 'allows a date change that resolves the overlap' do
          existing.assign_attributes(end_attribute => overlapping_record.public_send(start_attribute) - 1.day)

          expect(existing).to be_valid
        end

        # Any update that leaves the existing overlap must fail.
        it 'rejects an unrelated update' do
          overlapping_record.assign_attributes(unrelated_attribute => unrelated_value)

          expect_overlap_error(overlapping_record, start_attribute, end_attribute)
        end
      end
    end
  end

  # Apply the shared scenarios to HMIS Participation date columns.
  it_behaves_like(
    'participation overlap validation',
    factory_name: :hmis_hud_hmis_participation,
    start_attribute: :HMISParticipationStatusStartDate,
    end_attribute: :HMISParticipationStatusEndDate,
    unrelated_attribute: :HMISParticipationType,
    unrelated_value: 0,
  )

  # Apply the shared scenarios to CE Participation date columns.
  it_behaves_like(
    'participation overlap validation',
    factory_name: :hmis_hud_ce_participation,
    start_attribute: :CEParticipationStatusStartDate,
    end_attribute: :CEParticipationStatusEndDate,
    unrelated_attribute: :AccessPoint,
    unrelated_value: 1,
  )
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared SubmitForm coverage for HMIS and CE Participation overlaps.
# Required lets: input, hud_values, ds1, p1, u1, and the named existing record.
RSpec.shared_examples 'submit form validates participation overlaps' do |factory_name:, existing_record_name:, start_attribute:, end_attribute:, unrelated_attribute:|
  let(:participation_record) { public_send(existing_record_name) }
  let(:participation_start_field) { start_attribute.to_s.underscore.camelize(:lower) }
  let(:participation_end_field) { end_attribute.to_s.underscore.camelize(:lower) }
  let(:overlap_message) { Hmis::Hud::Validators::ParticipationValidator::OVERLAP_MESSAGE }

  def expect_date_range_overlap_errors(input, start_field:, end_field:, message:)
    _, errors = submit_form(input, expect_validation_errors: true)
    expect(errors).to include(
      include({ attribute: start_field, message: message }.stringify_keys),
      include({ attribute: end_field, message: message }.stringify_keys),
    )
  end

  # The submitted start date is the existing range's final included date.
  context 'when creating an overlapping participation' do
    let(:hud_values) do
      super().merge(
        participation_start_field => participation_record.public_send(end_attribute).to_s,
      )
    end

    it 'returns a validation error and does not persist the record' do
      expect do
        expect_date_range_overlap_errors(
          input,
          start_field: participation_start_field,
          end_field: participation_end_field,
          message: overlap_message,
        )
      end.not_to change(participation_record.class, :count)
    end
  end

  # The update changes a valid closed range into one that reaches a later row.
  context 'when updating a participation to overlap another record' do
    let!(:later_participation) do
      create(
        factory_name,
        start_attribute => '2021-01-01',
        end_attribute => nil,
        data_source: ds1,
        project: p1,
        user: u1,
      )
    end

    let(:hud_values) do
      super().merge(
        participation_start_field => participation_record.public_send(start_attribute).to_s,
        participation_end_field => later_participation.public_send(start_attribute).to_s,
      )
    end

    it 'returns a validation error and leaves the saved dates unchanged' do
      original_start_date = participation_record.public_send(start_attribute)
      original_end_date = participation_record.public_send(end_attribute)

      expect_date_range_overlap_errors(
        input.merge(record_id: participation_record.id),
        start_field: participation_start_field,
        end_field: participation_end_field,
        message: overlap_message,
      )

      participation_record.reload
      expect(participation_record.public_send(start_attribute)).to eq(original_start_date)
      expect(participation_record.public_send(end_attribute)).to eq(original_end_date)
    end
  end

  # The saved dates already overlap, and the submission changes only a non-date field.
  context 'when making an unrelated update to a historical overlap' do
    let!(:legacy_overlap) do
      build(
        factory_name,
        start_attribute => participation_record.public_send(end_attribute),
        end_attribute => nil,
        data_source: ds1,
        project: p1,
        user: u1,
      ).tap { |record| record.save!(validate: false) }
    end

    let(:hud_values) do
      super().merge(
        participation_start_field => participation_record.public_send(start_attribute).to_s,
        participation_end_field => participation_record.public_send(end_attribute)&.to_s,
      )
    end

    it 'returns a validation error and does not persist the unrelated change' do
      original_value = participation_record.public_send(unrelated_attribute)

      expect_date_range_overlap_errors(
        input.merge(record_id: participation_record.id),
        start_field: participation_start_field,
        end_field: participation_end_field,
        message: overlap_message,
      )

      expect(participation_record.reload.public_send(unrelated_attribute)).to eq(original_value)
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Config, type: :model do
  describe 'timestamps' do
    it 'sets created_at and updated_at on creation' do
      config = create(:config)
      expect(config.created_at).to be_present
      expect(config.updated_at).to be_present
    end

    it 'bumps updated_at on save' do
      config = create(:config)
      original_updated_at = config.updated_at
      travel_to(original_updated_at + 1.day) do
        config.update!(family_calculation_method: 'multiple_people')
      end
      expect(config.updated_at).to be > original_updated_at
    end
  end

  describe 'dob_selection_method' do
    it 'is a known config so it can be set from the admin form' do
      expect(described_class.known_configs).to include(:dob_selection_method)
    end

    it 'defaults to legacy, preserving the previous DOB selection' do
      config = create(:config)
      expect(config.dob_selection_method).to eq('legacy')
    end

    it 'offers a legacy option plus one per sort direction' do
      expect(described_class.available_dob_selection_methods.values).
        to contain_exactly(:legacy, :demote_oldest, :demote_newest)
    end
  end

  describe 'PaperTrail' do
    it 'creates a version on update' do
      PaperTrailHelper.with_paper_trail do
        config = create(:config)
        expect do
          config.update!(family_calculation_method: 'multiple_people')
        end.to change(config.versions, :count).by(1)
        expect(config.versions.last.changeset.keys).to include('family_calculation_method')
      end
    end
  end
end

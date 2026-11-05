###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Assessment::Overrides, type: :model do
  describe '.apply_overrides' do
    it 'leaves a blank assessment location blank' do
      assessment = GrdaWarehouse::Hud::Assessment.new(AssessmentLocation: nil)

      expect(described_class.apply_overrides(assessment).AssessmentLocation).to be_nil
    end
  end
end

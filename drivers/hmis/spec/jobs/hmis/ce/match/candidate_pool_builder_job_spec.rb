###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilderJob, type: :job do
  let(:builder_class) { Hmis::Ce::Match::CandidatePoolBuilder }

  describe '#perform' do
    it 'forwards args to the builder' do
      expect(builder_class).to receive(:call).with(force_reprocessing: true)
      described_class.new.perform(force_reprocessing: true)
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::ExternalForms::FormSubmission, type: :model do
  describe 'spam scopes' do
    let(:definition) { create(:hmis_external_form_definition) }
    let!(:submissions) do
      [0.1, 0.49, 0.5, 0.9, nil].index_with { |score| create(:hmis_external_form_submission, definition: definition, spam_score: score) }
    end

    it 'splits scores at the threshold with no overlap' do
      expect(described_class.spam).to contain_exactly(submissions[0.1], submissions[0.49])
      expect(described_class.not_spam).to contain_exactly(submissions[0.5], submissions[0.9], submissions[nil])
    end

    it 'agrees with #spam' do
      expect(described_class.spam).to all(have_attributes(spam: true))
      expect(described_class.not_spam.map(&:spam)).to all(be_falsey)
    end
  end
end

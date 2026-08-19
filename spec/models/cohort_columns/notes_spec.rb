###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::Notes, type: :model do
  let(:client) { create(:hud_client) }
  let(:cohort) { create(:cohort) }
  let(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let(:column) { described_class.new(cohort: cohort, cohort_client: cohort_client) }
  let(:user) { create(:user) }

  describe '#comments' do
    it 'is not html_safe' do
      GrdaWarehouse::CohortClientNote.create!(cohort_client: cohort_client, note: '<script>alert(1)</script>', user: user)

      expect(column.comments).not_to be_html_safe
    end

    it 'returns the note text verbatim' do
      GrdaWarehouse::CohortClientNote.create!(cohort_client: cohort_client, note: 'Called client', user: user)

      expect(column.comments).to include('Called client')
    end
  end
end

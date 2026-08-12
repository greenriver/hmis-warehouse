###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::HealthPrioritized, type: :model do
  let(:client) { create(:hud_client) }
  let(:cohort) { create(:cohort) }
  let(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let(:column) { described_class.new(cohort: cohort, cohort_client: cohort_client) }

  describe '#value' do
    it 'escapes stored markup instead of rendering it verbatim into the html cell' do
      client.update_column(:health_prioritized, '<script>alert(1)</script>')
      html = column.value(cohort_client)
      expect(html).not_to include('<script>')
      expect(html).to include('&lt;script&gt;')
    end

    it 'is html_safe' do
      client.update_column(:health_prioritized, 'Yes')
      expect(column.value(cohort_client)).to be_html_safe
    end

    it "displays 'Yes'" do
      client.update_column(:health_prioritized, 'Yes')
      expect(column.value(cohort_client)).to include('Yes')
    end

    it "displays 'No'" do
      client.update_column(:health_prioritized, 'No')
      expect(column.value(cohort_client)).to include('No')
    end

    it 'displays blank for an unset value' do
      client.update_column(:health_prioritized, nil)
      expect(column.text_value(cohort_client)).to be_nil
    end
  end

  describe '#analytics_value' do
    it 'returns the plain stored value rather than the escaped html cell markup' do
      client.update_column(:health_prioritized, 'Yes')
      expect(column.analytics_value).to eq('Yes')
      expect(column.analytics_value).not_to include('<span')
    end
  end
end

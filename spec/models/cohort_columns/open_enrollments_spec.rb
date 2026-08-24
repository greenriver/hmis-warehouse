###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::OpenEnrollments, type: :model do
  let(:client) { create(:hud_client) }
  let(:cohort) { create(:cohort) }
  let(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let(:column) { described_class.new(cohort: cohort, cohort_client: cohort_client) }

  describe '#display_read_only' do
    before do
      create(
        :grda_warehouse_warehouse_clients_processed,
        client: client,
        open_enrollments: [[1, 'ES'], [3, 'PH']],
      )
    end

    it 'returns an html_safe string' do
      expect(column.display_read_only(nil)).to be_html_safe
    end

    it 'joins each project type into its own tagged div, space-separated, matching the pre-safe_join markup' do
      expected = '<div class="enrollment__project_type client__service_type_1">' \
        '<em class="service-type__program-type">ES</em></div> ' \
        '<div class="enrollment__project_type client__service_type_3">' \
        '<em class="service-type__program-type">PH</em></div>'

      expect(column.display_read_only(nil)).to eq(expected)
    end
  end

  describe '#display_read_only without a processed service history' do
    it 'returns nil' do
      expect(column.display_read_only(nil)).to be_nil
    end
  end
end

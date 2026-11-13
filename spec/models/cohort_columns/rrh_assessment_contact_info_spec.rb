###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::RrhAssessmentContactInfo, type: :model do
  let(:client) { create(:hud_client, rrh_assessment_contact_info: nil) }
  let(:cohort) { create(:cohort) }
  let(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let(:column) { described_class.new(cohort: cohort, cohort_client: cohort_client) }

  before do
    allow(client).to receive(:consent_form_valid?).and_return(true)
  end

  describe '#value' do
    it 'returns the client contact text byte-for-byte, unescaped, for the CAS push contract' do
      client.update!(rrh_assessment_contact_info: '<script>alert(1)</script>')
      expect(column.value(cohort_client)).to eq('<script>alert(1)</script>')
    end

    it 'is nil when consent is not valid' do
      allow(client).to receive(:consent_form_valid?).and_return(false)
      client.update!(rrh_assessment_contact_info: 'Jane Doe, 555-1234')
      expect(column.value(cohort_client)).to be_nil
    end
  end

  describe '#display_read_only' do
    it 'escapes html in the contact text' do
      client.update!(rrh_assessment_contact_info: '<script>alert(1)</script>')
      html = column.display_read_only(nil)
      expect(html).not_to include('<script')
      expect(html).to include('&lt;script&gt;')
    end

    it 'is html_safe' do
      client.update!(rrh_assessment_contact_info: 'Jane Doe, 555-1234')
      expect(column.display_read_only(nil)).to be_html_safe
    end

    it 'is nil when the contact text is blank' do
      client.update!(rrh_assessment_contact_info: nil)
      expect(column.display_read_only(nil)).to be_nil
    end

    it 'collapses multi-line, multi-contact text onto one line and keeps the full text in the title' do
      raw = "Jane Doe\nCase Manager\nPhone: 555-1111\n\nJohn Smith\nCase Manager\nPhone: 555-2222"
      client.update!(rrh_assessment_contact_info: raw)
      html = column.display_read_only(nil)
      expect(html).to include('Jane Doe, Case Manager, Phone: 555-1111')
      expect(html).to include('John Smith, Case Manager, Phone: 555-2222')
      expect(html).to include(' | ')
      expect(html).to include(%(title="#{raw}"))
    end
  end

  describe '#text_value' do
    it 'strips tags for the Excel export' do
      client.update!(rrh_assessment_contact_info: '<b>Jane Doe</b>')
      expect(column.text_value(cohort_client)).to eq('Jane Doe')
    end
  end

  describe '#analytics_value' do
    it 'matches text_value and contains no markup' do
      client.update!(rrh_assessment_contact_info: '<script>alert(1)</script>')
      expect(column.analytics_value).to eq(column.text_value(cohort_client))
      expect(column.analytics_value).not_to include('<script')
    end
  end
end

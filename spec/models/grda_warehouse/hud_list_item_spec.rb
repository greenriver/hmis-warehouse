# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HudListItem do
  describe '.maintain!' do
    let(:year) { described_class::KNOWN_YEARS.first }
    let(:payload) do
      [
        {
          'name' => 'Sample Integer List',
          'method_name' => 'sample_integer_list',
          'code' => '1.1',
          'values' => [
            { 'key' => 1, 'description' => 'Integer One' },
            { 'key' => 'A1', 'description' => 'Alpha Option' },
          ],
        },
        {
          'name' => 'Sample Mixed List',
          'method_name' => 'sample_mixed_list',
          'code' => '2.2',
          'values' => [
            { 'key' => 7, 'description' => 'Lucky Seven' },
            { 'key' => 'BETA', 'description' => 'Beta Option' },
          ],
        },
      ]
    end

    before do
      allow(HudCodeGen).to receive(:lists_with_method_names).with(year).and_return(payload)
    end

    it "replaces records for #{described_class::KNOWN_YEARS.first} without touching other fiscal years" do
      legacy_record = described_class.create!(
        list_name: 'Legacy List',
        method_name: 'legacy_method',
        list_number: '9.9',
        label: 'Legacy Option',
        code: 'legacy',
        fiscal_year: year.to_i - 1,
        active: false,
      )

      stale_record = described_class.create!(
        list_name: 'Old List',
        method_name: 'old_method',
        list_number: 'old',
        label: 'Outdated',
        code: 'old',
        fiscal_year: year.to_i,
        active: true,
      )

      described_class.maintain!

      expect(described_class.exists?(legacy_record.id)).to be(true)
      expect(described_class.exists?(stale_record.id)).to be(false)
      expect(described_class.where(fiscal_year: year.to_i).count).to eq(payload.sum { _1['values'].size })
    end

    it 'persists integer and string HUD codes with expected attributes' do
      described_class.maintain!

      aggregate_failures 'persisted codes' do
        expect(described_class.find_by(list_number: '1.1', code: '1')).to have_attributes(
          label: 'Integer One',
          method_name: 'sample_integer_list',
          fiscal_year: year.to_i,
          active: true,
        )

        expect(described_class.find_by(list_number: '1.1', code: 'A1')).to have_attributes(
          label: 'Alpha Option',
          method_name: 'sample_integer_list',
          fiscal_year: year.to_i,
          active: true,
        )

        expect(described_class.find_by(list_number: '2.2', code: '7')).to have_attributes(
          label: 'Lucky Seven',
          method_name: 'sample_mixed_list',
          fiscal_year: year.to_i,
          active: true,
        )

        expect(described_class.find_by(list_number: '2.2', code: 'BETA')).to have_attributes(
          label: 'Beta Option',
          method_name: 'sample_mixed_list',
          fiscal_year: year.to_i,
          active: true,
        )
      end
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::ComplianceRules do
  describe '.rules_for' do
    it 'returns nil for an unknown project type' do
      expect(described_class.rules_for(99)).to be_nil
    end

    it 'returns a hash for a known project type' do
      expect(described_class.rules_for(0)).to be_a(Hash)
    end
  end

  describe 'bootstrap requirements' do
    it 'ES-EE (type 0) requires inventory and hmis_participation but not ce_participation' do
      rules = described_class.rules_for(0)
      expect(rules.dig('bootstrap', 'inventory')).to be(true)
      expect(rules.dig('bootstrap', 'hmis_participation')).to be(true)
      expect(rules.dig('bootstrap', 'ce_participation')).to be(false)
    end

    it 'ES-NBN (type 1) requires es_bed_type' do
      expect(described_class.rules_for(1).dig('bootstrap', 'es_bed_type')).to be(true)
    end

    it 'ES-EE (type 0) does not require es_bed_type' do
      expect(described_class.rules_for(0).dig('bootstrap', 'es_bed_type')).to be(false)
    end

    it 'CE (type 14) requires ce_participation but not inventory' do
      rules = described_class.rules_for(14)
      expect(rules.dig('bootstrap', 'ce_participation')).to be(true)
      expect(rules.dig('bootstrap', 'inventory')).to be(false)
    end

    it 'SO (type 4) does not require inventory' do
      expect(described_class.rules_for(4).dig('bootstrap', 'inventory')).to be(false)
    end

    it 'all known project types require hmis_participation' do
      [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14].each do |pt|
        expect(described_class.rules_for(pt).dig('bootstrap', 'hmis_participation')).to(
          be(true),
          "expected hmis_participation=true for type #{pt}",
        )
      end
    end
  end

  describe 'enrollment_entry requirements' do
    it 'ES-EE (type 0) requires employment_education' do
      expect(described_class.rules_for(0).dig('enrollment_entry', 'employment_education_required')).to be(true)
    end

    it 'SO (type 4) requires date_of_engagement' do
      expect(described_class.rules_for(4).dig('enrollment_entry', 'date_of_engagement_required')).to be(true)
    end

    it 'SSO (type 6) does not require employment_education' do
      expect(described_class.rules_for(6).dig('enrollment_entry', 'employment_education_required')).to be(false)
    end

    it 'CE (type 14) does not require employment_education' do
      expect(described_class.rules_for(14).dig('enrollment_entry', 'employment_education_required')).to be(false)
    end
  end

  describe 'during_enrollment requirements' do
    it 'SO (type 4) requires CLS every 30 days with jitter' do
      rules = described_class.rules_for(4)['during_enrollment']
      expect(rules['cls_required']).to be(true)
      expect(rules['cls_frequency_days']).to eq(30)
      expect(rules['cls_jitter_stddev']).to eq(15)
    end

    it 'CE (type 14) requires CLS every 90 days with jitter' do
      rules = described_class.rules_for(14)['during_enrollment']
      expect(rules['cls_required']).to be(true)
      expect(rules['cls_frequency_days']).to eq(90)
      expect(rules['cls_jitter_stddev']).to eq(30)
    end

    it 'PSH (type 3) does not require CLS' do
      expect(described_class.rules_for(3).dig('during_enrollment', 'cls_required')).to be(false)
    end
  end

  describe 'ce requirements' do
    it 'CE (type 14) requires events and assessment' do
      rules = described_class.rules_for(14)['ce']
      expect(rules['events_required']).to be(true)
      expect(rules['assessment_required']).to be(true)
    end

    it 'ES-EE (type 0) does not require ce records' do
      rules = described_class.rules_for(0)['ce']
      expect(rules['events_required']).to be(false)
      expect(rules['assessment_required']).to be(false)
    end
  end

  describe '.employment_education_required?' do
    it 'returns true for residential project types' do
      [0, 1, 2, 3, 8, 9, 10, 13].each do |pt|
        expect(described_class.employment_education_required?(pt)).to(
          be(true),
          "expected true for type #{pt}",
        )
      end
    end

    it 'returns false for non-residential project types' do
      [4, 6, 7, 11, 12, 14].each do |pt|
        expect(described_class.employment_education_required?(pt)).to(
          be(false),
          "expected false for type #{pt}",
        )
      end
    end
  end

  describe '.cls_required?' do
    it 'returns true only for SO and CE' do
      expect(described_class.cls_required?(4)).to be(true)
      expect(described_class.cls_required?(14)).to be(true)
    end

    it 'returns false for all other types' do
      [0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13].each do |pt|
        expect(described_class.cls_required?(pt)).to(
          be(false),
          "expected false for type #{pt}",
        )
      end
    end
  end

  describe '.cls_frequency' do
    it 'returns frequency hash for SO' do
      freq = described_class.cls_frequency(4)
      expect(freq).to eq({ days: 30, jitter_stddev: 15 })
    end

    it 'returns frequency hash for CE' do
      freq = described_class.cls_frequency(14)
      expect(freq).to eq({ days: 90, jitter_stddev: 30 })
    end

    it 'returns nil for types that do not require CLS' do
      expect(described_class.cls_frequency(0)).to be_nil
    end
  end

  describe '.date_of_engagement_required?' do
    it 'returns true only for SO (type 4)' do
      expect(described_class.date_of_engagement_required?(4)).to be(true)
    end

    it 'returns false for all other types' do
      [0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14].each do |pt|
        expect(described_class.date_of_engagement_required?(pt)).to(
          be(false),
          "expected false for type #{pt}",
        )
      end
    end
  end

  describe '.inventory_required?' do
    it 'returns true for types with inventory' do
      [0, 1, 2, 3, 8, 9, 10, 13].each do |pt|
        expect(described_class.inventory_required?(pt)).to(
          be(true),
          "expected true for type #{pt}",
        )
      end
    end

    it 'returns false for types without inventory' do
      [4, 6, 7, 11, 12, 14].each do |pt|
        expect(described_class.inventory_required?(pt)).to(
          be(false),
          "expected false for type #{pt}",
        )
      end
    end
  end

  describe '.ce_participation_required?' do
    it 'returns true only for CE (type 14)' do
      expect(described_class.ce_participation_required?(14)).to be(true)
    end

    it 'returns false for all other types' do
      [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13].each do |pt|
        expect(described_class.ce_participation_required?(pt)).to(
          be(false),
          "expected false for type #{pt}",
        )
      end
    end
  end

  describe '.health_and_dv_required?' do
    it 'returns true for ES-EE (type 0)' do
      expect(described_class.health_and_dv_required?(0)).to be true
    end

    it 'returns true for SO (type 4)' do
      expect(described_class.health_and_dv_required?(4)).to be true
    end

    it 'returns false for Services Only (type 6)' do
      expect(described_class.health_and_dv_required?(6)).to be false
    end

    it 'returns false for CE (type 14)' do
      expect(described_class.health_and_dv_required?(14)).to be false
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Concerns::HudValidationUtil do
  let(:util) { HudHelper.util }
  let(:rules) { Concerns::HudValidationUtil::VALID_SOCIAL_RULES }

  # SSN => the rules it breaks, in rule order; an empty list means it is valid.
  # valid_social? is the gate for client matching and duplicate detection, so these pin
  # its result as well as the reasons.
  let(:cases) do
    {
      '123456780' => [],
      '665123456' => [],
      '899123456' => [],
      # Published example SSN; not one of HUD's rules
      '078051120' => [],
      nil => [:length],
      '' => [:length],
      '12345678' => [:length],
      '1234567890' => [:length],
      '123-45-6789' => [:numeric, :length],
      '12345678a' => [:numeric],
      "12\n345678" => [:numeric],
      '000123456' => [:area],
      '666123456' => [:area],
      '900123456' => [:area],
      '987123456' => [:area],
      '123004567' => [:group],
      '123450000' => [:serial],
      '123456789' => [:pattern],
      '987654321' => [:area, :pattern],
      '234567890' => [:pattern],
      '333333333' => [:pattern],
      '000000000' => [:area, :group, :serial, :pattern],
    }
  end

  it 'reports the rules each SSN breaks' do
    aggregate_failures do
      cases.each do |ssn, failed|
        expect(util.invalid_social_reasons(ssn)).to eq(rules.values_at(*failed)), "for #{ssn.inspect}"
      end
    end
  end

  it 'treats an SSN as valid only when it breaks no rules' do
    aggregate_failures do
      cases.each do |ssn, failed|
        expect(util.valid_social?(ssn)).to eq(failed.empty?), "for #{ssn.inspect}"
      end
    end
  end

  it 'describes the same rules it checks' do
    expect(util.describe_valid_social_rules).to eq(rules.values)
  end
end

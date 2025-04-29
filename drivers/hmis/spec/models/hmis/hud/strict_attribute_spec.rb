###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::Concerns::WithStrictAttributes, type: :feature do
  describe 'decimal attributes' do
    let(:income_benefit) { create(:hmis_income_benefit) }

    [
      ['123.45', 123.45],
      ['0.0', 0.0],
      ['-123.45', -123.45],
      ['500.', 500.0],
      ['.5', 0.5],
      [nil, nil],
    ].each do |input, expected|
      it "accepts #{input} as valid decimal input" do
        income_benefit.unemployment_amount = input
        expect(income_benefit.valid?).to be_truthy
        income_benefit.save!
        expect(income_benefit.unemployment_amount).to eq(expected)
      end
    end

    [
      'abc',
      Object.new,
      { 'foo': 'bar' },
    ].each do |input|
      it "rejects #{input} as invalid decimal input" do
        income_benefit.unemployment_amount = input
        expect(income_benefit.valid?).to be_falsey
        expect(income_benefit.errors[:UnemploymentAmount]).to include('is not a number')
        expect do
          income_benefit.save!
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'integer attributes' do
    let(:disability) { create :hmis_disability }

    [
      ['123', 123],
      ['-123', -123],
      ['500.0', 500],
      ['500.', 500],
      [nil, nil],
      [false, 0],
      [true, 1],
    ].each do |input, expected|
      it "accepts #{input} as valid integer input" do
        disability.viral_load = input
        expect(disability.valid?).to be_truthy
        disability.save!
        expect(disability.viral_load).to eq(expected)
      end
    end

    [
      '123.45',
      'abc',
      Object.new,
      { 'foo': 'bar' },
    ].each do |input|
      it "rejects #{input} as invalid integer input" do
        disability.viral_load = input
        expect(disability.valid?).to be_falsey
        expect(disability.errors[:ViralLoad]).to include('is not a number')
        expect do
          disability.save!
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

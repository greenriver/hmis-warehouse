###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'report_context'

RSpec.describe HomelessSummaryReport::Report, type: :model do
  include_context 'report context'

  before(:all) do
    setup(default_setup_path)
  end

  after(:all) do
    cleanup
  end

  describe 'default_filter tests' do
    before(:all) do
      run!(default_filter)
    end

    [
      # All persons
      {
        slug: :spm_all_persons__all,
        count: 5,
      },
      {
        slug: :spm_all_persons__race_none,
        count: 1,
      },
      {
        slug: :spm_all_persons__asian,
        count: 1,
      },
      {
        slug: :spm_all_persons__hispanic_latinaeo,
        count: 1,
      },
      {
        slug: :spm_all_persons__black_af_american_hispanic_latinaeo,
        count: 1,
      },
      {
        slug: :spm_all_persons__fleeing_dv,
        count: 1,
      },
      {
        slug: :spm_all_persons__multi_racial,
        count: 1,
      },
      {
        slug: :spm_all_persons__veteran,
        count: 1,
      },
      # Adult only
      {
        slug: :spm_without_children__all,
        count: 3,
      },
      {
        slug: :spm_without_children__hispanic_latinaeo,
        count: 1,
      },
      {
        slug: :spm_without_children__race_none,
        count: 1,
      },
      # 55+ without children
      {
        slug: :spm_without_children_and_fifty_five_plus__all,
        count: 2,
      },
      {
        slug: :spm_without_children_and_fifty_five_plus__veteran,
        count: 1,
      },
      {
        slug: :spm_without_children_and_fifty_five_plus__race_none,
        count: 1,
      },
      {
        slug: :spm_without_children_and_fifty_five_plus__asian,
        count: 1,
      },
      # Children only
      {
        slug: :spm_only_children__all,
        count: 2,
      },
      {
        slug: :spm_only_children__fleeing_dv,
        count: 1,
      },
      {
        slug: :spm_only_children__black_af_american_hispanic_latinaeo,
        count: 1,
      },
      {
        slug: :spm_only_children__multi_racial,
        count: 1,
      },
    ].each do |test|
      it "includes #{test[:count]} in #{test[:slug]}" do
        expect(result(:m1a_es_sh_days, test[:slug])).to be == test[:count]
      end
    end

    it "doesn't find data not in the dataset" do
      [
        # All persons
        :spm_all_persons__am_ind_ak_native,
        :spm_all_persons__has_disability,
        :spm_all_persons__has_psh_move_in_date,
        :spm_all_persons__has_rrh_move_in_date,
        :spm_all_persons__native_hi_pacific,
        :spm_all_persons__returned_to_homelessness_from_permanent_destination,
        :spm_all_persons__white,
        # Adult only
        :spm_without_children__am_ind_ak_native,
        :spm_without_children__has_disability,
        :spm_without_children__has_psh_move_in_date,
        :spm_without_children__has_rrh_move_in_date,
        :spm_without_children__native_hi_pacific,
        :spm_without_children__returned_to_homelessness_from_permanent_destination,
        :spm_without_children__white,
        :spm_without_children__fleeing_dv,
        :spm_without_children__multi_racial,
        # Children only
        :spm_only_children__race_none,
        :spm_only_children__asian,
      ].each do |slug|
        expect(result(:m1a_es_sh_days, slug)).to be_zero
      end
    end
  end

  describe 'coc_filter tests' do
    before(:all) do
      run!(coc_filter)
    end

    [
      {
        slug: :spm_all_persons__all,
        count: 1,
      },
      {
        slug: :spm_without_children__all,
        count: 1,
      },
      {
        slug: :spm_without_children__hispanic_latinaeo,
        count: 1,
      },
    ].each do |test|
      it "includes #{test[:count]} in #{test[:slug]}" do
        expect(result(:m1a_es_sh_days, test[:slug])).to be == test[:count]
      end
    end

    it "doesn't find data not in CoC'" do
      [
        :spm_without_children__race_none,
        :spm_only_children__all,
        :spm_only_children__hispanic_latinaeo,
        :spm_only_children__race_none,
      ].each do |slug|
        expect(result(:m1a_es_sh_days, slug)).to be_zero
      end
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        slug: :spm_all_persons__non_hispanic_latino,
        count: 3,
      },
      {
        slug: :spm_all_persons__race_none,
        count: 3,
      },
      {
        slug: :spm_all_persons__a_n_h_l,
        count: 2,
      },
      {
        slug: :spm_all_persons__asian,
        count: 2,
      },
      {
        slug: :spm_all_persons__hispanic_latino,
        count: 2,
      },
      {
        slug: :spm_all_persons__black_african_american,
        count: 1,
      },
      {
        slug: :spm_all_persons__b_n_h_l,
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
        slug: :spm_without_children__hispanic_latino,
        count: 1,
      },
      {
        slug: :spm_without_children__race_none,
        count: 2,
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
        slug: :spm_without_children_and_fifty_five_plus__non_hispanic_latino,
        count: 2,
      },
      {
        slug: :spm_without_children_and_fifty_five_plus__race_none,
        count: 1,
      },
      {
        slug: :spm_without_children_and_fifty_five_plus__asian,
        count: 1,
      },
      {
        slug: :spm_without_children_and_fifty_five_plus__a_n_h_l,
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
        slug: :spm_only_children__hispanic_latino,
        count: 1,
      },
      {
        slug: :spm_only_children__race_none,
        count: 1,
      },
      {
        slug: :spm_only_children__non_hispanic_latino,
        count: 1,
      },
      {
        slug: :spm_only_children__black_african_american,
        count: 1,
      },
      {
        slug: :spm_only_children__asian,
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
        :spm_all_persons__american_indian_alaskan_native,
        :spm_all_persons__has_disability,
        :spm_all_persons__has_psh_move_in_date,
        :spm_all_persons__has_rrh_move_in_date,
        :spm_all_persons__h_n_h_l,
        :spm_all_persons__native_hawaiian_other_pacific_islander,
        :spm_all_persons__n_n_h_l,
        :spm_all_persons__returned_to_homelessness_from_permanent_destination,
        :spm_all_persons__white,
        :spm_all_persons__white_non_hispanic_latino,
        # Adult only
        :spm_without_children__american_indian_alaskan_native,
        :spm_without_children__has_disability,
        :spm_without_children__has_psh_move_in_date,
        :spm_without_children__has_rrh_move_in_date,
        :spm_without_children__h_n_h_l,
        :spm_without_children__native_hawaiian_other_pacific_islander,
        :spm_without_children__n_n_h_l,
        :spm_without_children__returned_to_homelessness_from_permanent_destination,
        :spm_without_children__white,
        :spm_without_children__white_non_hispanic_latino,
        :spm_without_children__fleeing_dv,
        :spm_without_children__b_n_h_l,
        :spm_without_children__multi_racial,
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
        slug: :spm_without_children__hispanic_latino,
        count: 1,
      },
      {
        slug: :spm_without_children__race_none,
        count: 1,
      },
    ].each do |test|
      it "includes #{test[:count]} in #{test[:slug]}" do
        expect(result(:m1a_es_sh_days, test[:slug])).to be == test[:count]
      end
    end

    it "doesn't find data not in CoC'" do
      [
        :spm_only_children__all,
        :spm_only_children__hispanic_latino,
        :spm_only_children__race_none,
      ].each do |slug|
        expect(result(:m1a_es_sh_days, slug)).to be_zero
      end
    end
  end
end

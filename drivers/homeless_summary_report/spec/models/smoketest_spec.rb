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

    it 'includes 5 clients' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__all)).to be == 5
    end

    it 'includes 3 non hispanic/latino' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__non_hispanic_latino)).to be == 3
    end

    it 'includes 3 with no race' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__race_none)).to be == 3
    end

    it 'includes 2 asian non hispanic/latino' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__a_n_h_l)).to be == 2
    end

    it 'includes 2 asian' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__asian)).to be == 2
    end

    it 'includes 2 hispanic/latino' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__hispanic_latino)).to be == 2
    end

    it 'includes 1 black/african american' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__black_african_american)).to be == 1
    end

    it 'includes 1 black/african american non hispanic/latino' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__b_n_h_l)).to be == 1
    end

    it 'includes 1 fleeing DV survivor' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__fleeing_dv)).to be == 1
    end

    it 'includes 1 multi-racial' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__multi_racial)).to be == 1
    end

    it 'includes 1 veteran' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__veteran)).to be == 1
    end

    it "doesn't find data not in the dataset (all persons)" do
      expect(result(:m1a_es_sh_days, :spm_all_persons__american_indian_alaskan_native)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__has_disability)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__has_psh_move_in_date)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__has_rrh_move_in_date)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__h_n_h_l)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__native_hawaiian_other_pacific_islander)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__n_n_h_l)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__returned_to_homelessness_from_permanent_destination)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__white)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_all_persons__white_non_hispanic_latino)).to be_zero
    end

    it 'includes 3 clients (adult only)' do
      expect(result(:m1a_es_sh_days, :spm_without_children__all)).to be == 3
    end

    it 'includes 1 hispanic/latino (adult only)' do
      expect(result(:m1a_es_sh_days, :spm_without_children__hispanic_latino)).to be == 1
    end

    it 'includes 2 with no race (adult only)' do
      expect(result(:m1a_es_sh_days, :spm_without_children__race_none)).to be == 2
    end

    it "doesn't find data not in the dataset (adult only)" do
      expect(result(:m1a_es_sh_days, :spm_without_children__american_indian_alaskan_native)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__has_disability)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__has_psh_move_in_date)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__has_rrh_move_in_date)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__h_n_h_l)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__native_hawaiian_other_pacific_islander)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__n_n_h_l)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__returned_to_homelessness_from_permanent_destination)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__white)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__white_non_hispanic_latino)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__fleeing_dv)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__b_n_h_l)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_without_children__multi_racial)).to be_zero
    end

    it 'includes 2 clients (adult only 55+)' do
      expect(result(:m1a_es_sh_days, :spm_without_children_and_fifty_five_plus__all)).to be == 2
    end

    it 'includes 1 veteran (adult only 55+)' do
      expect(result(:m1a_es_sh_days, :spm_without_children_and_fifty_five_plus__veteran)).to be == 1
    end

    it 'includes 2 non hispanic/latino (adult only 55+)' do
      expect(result(:m1a_es_sh_days, :spm_without_children_and_fifty_five_plus__non_hispanic_latino)).to be == 2
    end

    it 'includes 1 with no race (adult only 55+)' do
      expect(result(:m1a_es_sh_days, :spm_without_children_and_fifty_five_plus__race_none)).to be == 1
    end

    it 'includes 1 asian (adult only 55+)' do
      expect(result(:m1a_es_sh_days, :spm_without_children_and_fifty_five_plus__asian)).to be == 1
    end

    it 'includes 1 asian non-hispanic/latino (adult only 55+)' do
      expect(result(:m1a_es_sh_days, :spm_without_children_and_fifty_five_plus__a_n_h_l)).to be == 1
    end

    it 'includes 2 clients (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__all)).to be == 2
    end

    it 'includes 1 client fleeing dv (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__fleeing_dv)).to be == 1
    end

    it 'includes 1 hispanic/latino (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__hispanic_latino)).to be == 1
    end

    it 'includes 1 with no race (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__race_none)).to be == 1
    end

    it 'includes 1 non-hispanic/latino (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__non_hispanic_latino)).to be == 1
    end

    it 'includes 1 black/african american (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__black_african_american)).to be == 1
    end

    it 'includes 1 asian (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__asian)).to be == 1
    end

    it 'includes 1 multiracial (children only)' do
      expect(result(:m1a_es_sh_days, :spm_only_children__multi_racial)).to be == 1
    end
  end

  describe 'coc_filter tests' do
    before(:all) do
      run!(coc_filter)
    end

    it 'includes 1 client' do
      expect(result(:m1a_es_sh_days, :spm_all_persons__all)).to be == 1
    end

    it 'includes 1 adult' do
      expect(result(:m1a_es_sh_days, :spm_without_children__all)).to be == 1
    end

    it 'includes 1 adult hispanic/latino' do
      expect(result(:m1a_es_sh_days, :spm_without_children__hispanic_latino)).to be == 1
    end

    it 'includes 1 without race' do
      expect(result(:m1a_es_sh_days, :spm_without_children__race_none)).to be == 1
    end

    it "doesn't find data not in CoC'" do
      expect(result(:m1a_es_sh_days, :spm_only_children__all)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_only_children__hispanic_latino)).to be_zero
      expect(result(:m1a_es_sh_days, :spm_only_children__race_none)).to be_zero
    end
  end
end

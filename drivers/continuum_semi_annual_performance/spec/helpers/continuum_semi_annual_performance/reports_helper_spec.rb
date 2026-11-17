###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::ReportsHelper do
  describe '.tab_title' do
    it 'titles each tab from its project type group' do
      titles = [:summary, :es, :hp, :so, :rrh, :ce_tab].map { |tab| described_class.tab_title(tab) }

      expect(titles).to eq(
        [
          'Summary',
          HudHelper.util.project_type_group_titles.fetch(:es),
          HudHelper.util.project_type_group_titles.fetch(:prevention),
          HudHelper.util.project_type_group_titles.fetch(:so),
          HudHelper.util.project_type_group_titles.fetch(:rrh),
          HudHelper.util.project_type_group_titles.fetch(:ce),
        ],
      )
    end
  end
end

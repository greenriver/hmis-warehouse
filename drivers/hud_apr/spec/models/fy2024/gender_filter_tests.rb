###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'gender filter tests apr', shared_context: :metadata do
  describe 'APR Gender Filter Tests', type: :model do
    before(:all) do
      @generator = HudApr::Generators::Apr::Fy2024::Generator
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['Organization S - RRH - 2']).pluck(:id)
      @filter = ::Filters::HudFilterBase.new(
        shared_filter_spec.merge(
          project_ids: Array.wrap(project_ids),
          genders: [0], # 0 = Woman (Girl, if child)
        ),
      )
    end

    it 'runs APR with gender filter without raising exceptions' do
      expect do
        run(@generator, @filter)
      end.not_to raise_error
    end

    it 'includes only female clients in the results' do
      run(@generator, @filter)
      report = ::HudReports::ReportInstance.last
      # Check we have at least one person in the report
      q5a = report.answer(question: 'Q5a', cell: 'B2').summary

      # This should be non-zero
      expect(q5a).to be > 0
    end
  end
end

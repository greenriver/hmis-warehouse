###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative './project_setup'
require_relative './multi_project_tests'
require_relative './enrollment_setup'
require_relative './multi_enrollment_tests'

def project_test_type
  'project group-based'
end

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  include_context '2022 project setup'
  include_context '2022 enrollment setup'

  let(:project_test_type) { 'project group-based' }
  let!(:project_group) { create :project_group, name: 'P Group', projects: projects.first(3) }
  let(:involved_project_ids) { project_group.project_ids }
  let(:exporter) do
    HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: involved_project_ids,
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context '2022 multi-project tests'
  include_context '2022 multi-enrollment tests'
end

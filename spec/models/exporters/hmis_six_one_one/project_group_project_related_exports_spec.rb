require 'rails_helper'
require 'models/exporters/hmis_six_one_one/project_setup'
require 'models/exporters/hmis_six_one_one/multi_project_tests'
require 'models/exporters/hmis_six_one_one/enrollment_setup'
require 'models/exporters/hmis_six_one_one/multi_enrollment_tests'

def project_test_type
  'project group-based'
end

RSpec.describe Exporters::HmisSixOneOne::Base, type: :model do
  include_context 'project setup'
  include_context 'enrollment setup'

  let(:project_test_type) { 'project group-based' }
  let!(:project_group) { create :project_group, name: 'P Group', projects: projects.first(3) }
  let(:involved_project_ids) { project_group.project_ids }
  let(:exporter) do
    Exporters::HmisSixOneOne::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: involved_project_ids,
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context 'multi-project tests'
  include_context 'multi-enrollment tests'
end

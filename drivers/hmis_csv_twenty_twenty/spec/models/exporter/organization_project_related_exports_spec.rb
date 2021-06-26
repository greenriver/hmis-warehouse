require 'rails_helper'
require_relative './project_setup'
require_relative './single_project_tests'
require_relative './enrollment_setup'
require_relative './single_enrollment_tests'

def project_test_type
  'organization-based'
end

RSpec.describe HmisCsvTwentyTwenty::Exporter::Base, type: :model do
  include_context '2020 project setup'
  include_context '2020 enrollment setup'

  let(:project_test_type) { 'organization-based' }
  let(:exporter) do
    HmisCsvTwentyTwenty::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: organizations.first.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context '2020 single-project tests'
  include_context '2020 single-enrollment tests'
end

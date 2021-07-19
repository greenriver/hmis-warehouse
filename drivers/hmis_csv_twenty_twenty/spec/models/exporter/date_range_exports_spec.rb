require 'rails_helper'
require_relative './project_setup'
require_relative './enrollment_dates_setup'
require_relative './multi_enrollment_tests'

def project_test_type
  'enrollment date-based'
end

RSpec.describe HmisCsvTwentyTwenty::Exporter::Base, type: :model do
  include_context '2020 project setup'
  include_context '2020 enrollment dates setup'

  let(:involved_project_ids) { projects.map(&:id) }
  let(:exporter) do
    HmisCsvTwentyTwenty::Exporter::Base.new(
      start_date: 3.weeks.ago.to_date,
      end_date: 1.weeks.ago.to_date,
      projects: involved_project_ids,
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context '2020 multi-enrollment tests'
end

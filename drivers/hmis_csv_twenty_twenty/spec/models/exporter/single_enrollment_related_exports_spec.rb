require 'rails_helper'
require_relative './project_setup'
require_relative './enrollment_setup'
require_relative './single_enrollment_tests'

RSpec.describe HmisCsvTwentyTwenty::Exporter::Base, type: :model do
  include_context '2020 project setup'
  include_context '2020 enrollment setup'

  let(:exporter) do
    HmisCsvTwentyTwenty::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context '2020 single-enrollment tests'
end

require 'rails_helper'
require 'models/exporters/hmis_twenty_twenty/project_setup.rb'
require 'models/exporters/hmis_twenty_twenty/single_project_tests.rb'
require 'models/exporters/hmis_twenty_twenty/enrollment_setup.rb'
require 'models/exporters/hmis_twenty_twenty/single_enrollment_tests.rb'

def project_test_type
  'organization-based'
end

RSpec.describe Exporters::HmisTwentyTwenty::Base, type: :model do
  include_context 'project setup'
  include_context 'enrollment setup'

  let(:project_test_type) { 'organization-based' }
  let(:exporter) do
    Exporters::HmisTwentyTwenty::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.today,
      projects: organizations.first.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context 'single-project tests'
  include_context 'single-enrollment tests'
end

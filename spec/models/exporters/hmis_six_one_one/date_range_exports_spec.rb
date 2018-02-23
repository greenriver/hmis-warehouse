require 'rails_helper'
require "models/exporters/hmis_six_one_one/project_setup.rb"
require "models/exporters/hmis_six_one_one/enrollment_dates_setup.rb"
require "models/exporters/hmis_six_one_one/multi_enrollment_tests.rb"

def project_test_type
  'enrollment date-based'
end

RSpec.describe Exporters::HmisSixOneOne::Base, type: :model do
  include_context "project setup"
  include_context "enrollment dates setup"
  
  let(:involved_project_ids) {projects.map(&:id)}
  let(:exporter) {
    Exporters::HmisSixOneOne::Base.new(
      start_date: 3.weeks.ago.to_date, 
      end_date: 1.weeks.ago.to_date, 
      projects: involved_project_ids, 
      period_type: 3,
      directive: 3,
      user_id: user.id
    )
  }
  
  include_context "multi-enrollment tests"

end
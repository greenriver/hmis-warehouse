require 'rails_helper'
require "models/exporters/hmis_six_one_one/project_setup.rb"
require "models/exporters/hmis_six_one_one/multi_project_tests.rb"

RSpec.describe Exporters::HmisSixOneOne::Base, type: :model do
  include_context "project setup"
  
  let!(:project_group) { create :project_group, name: 'P Group', projects: projects }
  let(:exporter) {
    Exporters::HmisSixOneOne::Base.new(
      start_date: 1.week.ago.to_date, 
      end_date: Date.today, 
      projects: project_group.project_ids, 
      period_type: 3,
      directive: 3,
      user_id: user.id
    )
  }
  
  include_context "multi-project tests"

end
require 'rails_helper'
require 'models/exporters/hmis_six_one_one/project_type_override_setup.rb'
require 'models/exporters/hmis_six_one_one/project_type_override_tests.rb'

RSpec.describe Exporters::HmisSixOneOne::Base, type: :model do
  include_context 'project type override setup'

  let(:enrollment_exporter) do
    Exporters::HmisSixOneOne::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  let(:project_exporter) do
    Exporters::HmisSixOneOne::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context 'project type override tests'
end

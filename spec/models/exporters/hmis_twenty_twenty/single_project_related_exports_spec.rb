require 'rails_helper'
require 'models/exporters/hmis_twenty_twenty/project_setup.rb'
require 'models/exporters/hmis_twenty_twenty/single_project_tests.rb'

RSpec.describe Exporters::HmisTwentyTwenty::Base, type: :model do
  include_context 'project setup'

  let(:exporter) do
    Exporters::HmisTwentyTwenty::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context 'single-project tests'
end

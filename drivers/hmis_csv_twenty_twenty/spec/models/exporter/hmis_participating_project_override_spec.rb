require 'rails_helper'
require 'models/exporters/hmis_twenty_twenty/hmis_participating_project_override_setup'
require 'models/exporters/hmis_twenty_twenty/hmis_participating_project_override_tests'

RSpec.describe Exporters::HmisTwentyTwenty::Base, type: :model do
  include_context '2020 HMIS Participating Project override setup'

  let(:enrollment_exporter) do
    Exporters::HmisTwentyTwenty::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  let(:project_exporter) do
    Exporters::HmisTwentyTwenty::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context '2020 HMIS Participating Project override tests'
end

require 'rails_helper'
require 'models/exporters/hmis_twenty_twenty/project_coc_zip_override_setup.rb'
require 'models/exporters/hmis_twenty_twenty/project_coc_zip_override_tests.rb'

RSpec.describe Exporters::HmisTwentyTwenty::Base, type: :model do
  include_context '2020 project coc zip override setup'

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

  include_context '2020 project coc zip override tests'
end

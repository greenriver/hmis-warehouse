require 'rails_helper'
require_relative './project_coc_zip_override_setup'
require_relative './project_coc_zip_override_tests'

RSpec.describe HmisCsvTwentyTwenty::Exporter::Base, type: :model do
  include_context '2020 project coc zip override setup'

  let(:enrollment_exporter) do
    HmisCsvTwentyTwenty::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  let(:project_exporter) do
    HmisCsvTwentyTwenty::Exporter::Base.new(
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

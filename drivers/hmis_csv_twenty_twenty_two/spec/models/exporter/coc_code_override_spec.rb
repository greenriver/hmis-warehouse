###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative './coc_code_override_setup'
require_relative './coc_code_override_tests'
require_relative './project_id_override_tests'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  include_context '2022 coc code override setup'

  let(:enrollment_exporter) do
    HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  let(:project_exporter) do
    HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  include_context '2022 coc code override tests'
  include_context '2022 project id override tests'
end

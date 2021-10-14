###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_caper_context'

RSpec.describe 'Datalab 2021 CAPER - Entry-Exit ES', type: :model do
  include_context 'datalab caper context'

  before(:all) do
    setup
    run(es_ee_filter)
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    compare_results(
      file_path: result_file_prefix + 'es_ee',
      question: 'Q4a',
      skip: [
        'B2', # expected is a name not and ID?
        'L2', # Is the generator name, so not expected to match
      ],
    )
  end
end

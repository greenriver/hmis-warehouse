###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::Hud::AssessmentQuestion, type: :model do
  it_behaves_like 'enrollment related versioned model' do
    let(:build_record) do
      -> { create(:hmis_assessment_question) }
    end

    let(:update_attributes_for_versioning) do
      ->(record) { record.update!(assessment_question_order: 999) }
    end
  end
end

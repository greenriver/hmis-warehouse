# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::Hud::Service, type: :model do
  it_behaves_like 'enrollment related versioned model' do
    let(:build_record) do
      -> { create(:hmis_hud_service) }
    end

    let(:update_attributes_for_versioning) do
      ->(record) { record.update!(date_provided: 1.week.ago) }
    end
  end
end

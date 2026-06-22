###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriorLivingSituation::WarehouseReports::PriorLivingSituationController, type: :request do
  include_context 'details action requires client access' do
    let(:details_path) { details_prior_living_situation_warehouse_reports_prior_living_situation_index_path }
  end
end

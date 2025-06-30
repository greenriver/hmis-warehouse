# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MarkAsDirtyBehavior do
  include_context 'hmis base setup'

  let!(:destination_data_source) { create :destination_data_source }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }

  before do
    # Create warehouse clients to enable dirty marking
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    # Mark everything clean
    GrdaWarehouse::ClientChangeMarker.mark_processed(GrdaWarehouse::ClientChangeMarker.all)
  end

  shared_examples 'marks client as dirty' do |model_factory, model_attrs={}|
    it "marks destination client dirty when #{model_factory} is saved" do
      expect do
        create model_factory, client: c1, data_source: ds1, **model_attrs
      end.to change { GrdaWarehouse::ClientChangeMarker.where(client_id: c1.destination_client.id ).dirty.count }.by(1)
    end
  end

  include_examples 'marks client as dirty', :hmis_custom_assessment
  include_examples 'marks client as dirty', :hmis_disability
  include_examples 'marks client as dirty', :hmis_employment_education
  include_examples 'marks client as dirty', :hmis_hud_assessment
  include_examples 'marks client as dirty', :hmis_hud_enrollment
  include_examples 'marks client as dirty', :hmis_income_benefit
  include_examples 'marks client as dirty', :hmis_youth_education_status
end

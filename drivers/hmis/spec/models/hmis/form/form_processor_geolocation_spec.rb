###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'geolocation processing', type: :model do
  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 7 }

  let(:geolocation_item) do
    {
      "type": 'GEOLOCATION',
      "link_id": 'geolocation',
      "text": 'Current Location',
      "mapping": {
        "record_type": 'GEOLOCATION',
        "field_name": 'coordinates',
      },
    }
  end
  let(:today) { Date.current }

  let!(:definition) do
    create(:custom_assessment_with_custom_fields, data_source: ds1, append_items: geolocation_item, title: 'Custom with Geolocation')
  end

  describe 'when processing new custom assessment values' do
    let(:assessment) { build(:hmis_custom_assessment, client: c1, enrollment: e1, data_source: ds1) }
    let(:form_processor) { assessment.build_form_processor(definition: definition) }

    [
      # should create location records:
      [{ 'latitude': 40.0001, 'longitude': -75.0002 }, true],
      [{ 'latitude': 40.0001, 'longitude': -75.0002 }.to_json, true],
      [{ 'latitude': 40.0001, 'longitude': -75.0002, 'accuracy': 10 }, true],
      # should not create location records:
      [{ 'notCollectedReason': 'error' }.to_json, false],
      [nil, false],
      [{}, false],
      ['', false],
    ].each do |coordinates, should_create|
      it "processes coordinates (#{coordinates})" do
        hud_values = {
          'assessmentDate' => today.strftime('%Y-%m-%d'),
          'Geolocation.coordinates' => coordinates,
        }
        form_processor.hud_values = hud_values
        form_processor.run!(user: hmis_user)
        form_processor.save!

        if should_create
          expect(form_processor.clh_location).to be_persisted
          expect(form_processor.clh_location.lat).to eq(40.0001)
          expect(form_processor.clh_location.lon).to eq(-75.0002)
          expect(form_processor.clh_location.source_type).to eq('GrdaWarehouse::Hud::Enrollment')
          expect(form_processor.clh_location.source_id).to eq(e1.id)
          expect(form_processor.clh_location.client_id).to eq(c1.id)
          expect(form_processor.clh_location.collected_by).to eq(p1.project_name)
          expect(form_processor.clh_location.located_on).to eq(today)
          expect(form_processor.clh_location.processed_at).to be_present
        else
          expect(form_processor.clh_location).to be_nil
        end
      end
    end
  end

  describe 'when re-processing existing assessment with geolocation' do
    # TODO finish:
    # 1) updating location
    # 2) removing location
    let!(:assessment) { create(:hmis_custom_assessment, client: c1, enrollment: e1, data_source: ds1, definition: definition) }
  end
end

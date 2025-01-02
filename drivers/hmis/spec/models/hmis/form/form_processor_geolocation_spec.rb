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

  context 'on CustomAssessment' do
    let!(:definition) do
      create(:custom_assessment_with_custom_fields, data_source: ds1, append_items: geolocation_item, title: 'Custom with Geolocation')
    end

    describe 'when processing new CustomAssessment' do
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
        it "#{should_create ? 'does' : 'does not'} process coordinates (#{coordinates}) into clh_locations" do
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

    describe 'when re-processing existing CustomAssessment' do
      let!(:clh_location) { create(:clh_location, source: e1.as_warehouse, client_id: c1.id, collected_by: p1.project_name, located_on: 1.week.ago) }
      let!(:assessment) do
        assessment = create(:hmis_custom_assessment, client: c1, enrollment: e1, data_source: ds1, definition: definition)
        assessment.form_processor.update!(clh_location: clh_location)
        assessment
      end
      let(:form_processor) { assessment.form_processor }
      let(:today) { Date.today }
      let(:updated_lat) { 40.0001 }
      let(:updated_lon) { -75.0002 }

      context 'when geolocation is updated' do
        it 'updates the location record correctly' do
          form_processor.hud_values = {
            'assessmentDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => { latitude: updated_lat, longitude: updated_lon },
          }

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to change { clh_location.lat }.to(updated_lat).
            and change { clh_location.lon }.to(updated_lon).
            and change { clh_location.located_on }.to(today).
            and change { clh_location.updated_at }.
            and(not_change { ClientLocationHistory::Location.count }).
            and(not_change { clh_location.slice(:source_type, :source_id, :client_id, :collected_by) })
        end
      end

      context 'when geolocation is removed' do
        it 'destroys the location record' do
          form_processor.hud_values = {
            'assessmentDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => nil,
          }

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to change(ClientLocationHistory::Location, :count).by(-1).
            and change { form_processor.clh_location_id }.from(clh_location.id).to(nil)
        end
      end

      context 'when geolocation is created' do
        before(:each) do
          clh_location.destroy!
          form_processor.update!(clh_location_id: nil)
        end
        # similar to context above, but here we're operating on an existing CustomAssessment
        it 'creates the location record' do
          form_processor.hud_values = {
            'assessmentDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => { latitude: updated_lat, longitude: updated_lon },
          }

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to change(ClientLocationHistory::Location, :count).by(1)
        end
      end

      context 'when geolocation remains unchanged' do
        it 'does not update the location record' do
          form_processor.hud_values = {
            'assessmentDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => { latitude: clh_location.lat, longitude: clh_location.lon },
          }

          old_attrs = clh_location.attributes

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to(not_change { ClientLocationHistory::Location.count })

          # The only attribute that should change on resubmission is 'updated_at' (for consistency with other Assessment-related records)
          expect(clh_location.attributes.excluding('updated_at')).to match(old_attrs.excluding('updated_at'))
        end
      end
    end
  end

  context 'on CurrentLivingSituation' do
    let!(:definition) do
      create(:hmis_current_living_situation_form_definition, data_source: ds1, append_items: geolocation_item, title: 'Custom CLS with Geolocation')
    end

    describe 'when processing new CurrentLivingSituation' do
      let(:record) { build(:hmis_current_living_situation, client: c1, enrollment: e1, data_source: ds1) }
      let(:form_processor) { record.build_form_processor(definition: definition) }

      it 'should create location record' do
        hud_values = {
          'informationDate' => today.strftime('%Y-%m-%d'),
          'Geolocation.coordinates' => { 'latitude': 40.0001, 'longitude': -75.0002 },
        }
        form_processor.hud_values = hud_values
        form_processor.run!(user: hmis_user)
        form_processor.save!

        expect(form_processor.clh_location).to be_persisted
        expect(form_processor.clh_location.lat).to eq(40.0001)
        expect(form_processor.clh_location.lon).to eq(-75.0002)
        expect(form_processor.clh_location.source_type).to eq('GrdaWarehouse::Hud::Enrollment')
        expect(form_processor.clh_location.source_id).to eq(e1.id)
        expect(form_processor.clh_location.client_id).to eq(c1.id)
        expect(form_processor.clh_location.collected_by).to eq(p1.project_name)
        expect(form_processor.clh_location.located_on).to eq(today)
        expect(form_processor.clh_location.processed_at).to be_present
        expect(record.clh_location).to be_present
      end

      it 'location should not be deleted during clean-up' do
        hud_values = {
          'informationDate' => today.strftime('%Y-%m-%d'),
          'Geolocation.coordinates' => { 'latitude': 40.0001, 'longitude': -75.0002 },
        }
        form_processor.hud_values = hud_values
        form_processor.run!(user: hmis_user)
        expect do
          form_processor.save!
        end.to change(ClientLocationHistory::Location, :count).by(1)

        expect do
          GrdaWarehouse::Hud::Enrollment.maintain_location_histories
        end.not_to change(ClientLocationHistory::Location, :count)
      end
    end

    describe 'when re-processing existing CurrentLivingSituation' do
      let!(:clh_location) { create(:clh_location, source: e1.as_warehouse, client_id: c1.id, collected_by: p1.project_name, located_on: 1.week.ago) }
      let(:record) { build(:hmis_current_living_situation, client: c1, enrollment: e1, data_source: ds1) }
      let(:form_processor) { create(:hmis_form_processor, owner: record, definition: definition, clh_location: clh_location) }
      let(:today) { Date.today }
      let(:updated_lat) { 40.0001 }
      let(:updated_lon) { -75.0002 }

      context 'when geolocation is updated' do
        it 'updates the location record correctly' do
          form_processor.hud_values = {
            'informationDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => { latitude: updated_lat, longitude: updated_lon },
          }

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to change { clh_location.lat }.to(updated_lat).
            and change { clh_location.lon }.to(updated_lon).
            and change { clh_location.located_on }.to(today).
            and change { clh_location.updated_at }.
            and(not_change { record.clh_location.id }).
            and(not_change { ClientLocationHistory::Location.count }).
            and(not_change { clh_location.slice(:source_type, :source_id, :client_id, :collected_by) })
        end
      end

      context 'when geolocation is removed' do
        it 'destroys the location record' do
          form_processor.hud_values = {
            'informationDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => nil,
          }

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to change(ClientLocationHistory::Location, :count).by(-1).
            and change { form_processor.clh_location_id }.from(clh_location.id).to(nil)
        end
      end

      context 'when geolocation is created' do
        before(:each) do
          clh_location.destroy!
          form_processor.update!(clh_location_id: nil)
        end
        # similar to context above, but here we're operating on an existing CurrentLivingSituation
        it 'creates the location record' do
          form_processor.hud_values = {
            'informationDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => { latitude: updated_lat, longitude: updated_lon },
          }

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to change(ClientLocationHistory::Location, :count).by(1).
            and change(form_processor, :clh_location_id).from(nil)
        end
      end

      context 'when geolocation remains unchanged' do
        it 'does not update the location record' do
          form_processor.hud_values = {
            'informationDate' => today.strftime('%Y-%m-%d'),
            'Geolocation.coordinates' => { latitude: clh_location.lat, longitude: clh_location.lon },
          }

          old_attrs = clh_location.attributes

          expect do
            form_processor.run!(user: hmis_user)
            form_processor.save!
          end.to(not_change { ClientLocationHistory::Location.count })

          # The only attribute that should change on resubmission is 'updated_at' (for consistency with other Assessment-related records)
          expect(clh_location.attributes.excluding('updated_at')).to match(old_attrs.excluding('updated_at'))
        end
      end
    end
  end
end

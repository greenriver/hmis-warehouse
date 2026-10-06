###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::MarkClientAsDirtyBehavior do
  include_context 'hmis base setup'

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  let!(:destination_data_source) { create :destination_data_source }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:destination_client) do
    GrdaWarehouse::Hud::Client.find(c1.destination_client.id)
  end

  before do
    # Create warehouse clients to enable dirty marking
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    # Mark everything clean
    Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)
  end

  shared_examples 'marks client as dirty' do |model_factory, model_attrs = {}|
    it "marks destination client dirty when #{model_factory} is saved" do
      expect do
        create model_factory, client: c1, data_source: ds1, **model_attrs
      end.to change { Hmis::Ce::ChangeMarker.where(trackable: destination_client).dirty.count }.by(1)
    end

    it "marks destination client dirty when #{model_factory} is destroyed" do
      model = create model_factory, client: c1, data_source: ds1, **model_attrs
      Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)

      expect do
        model.destroy!
      end.to change { Hmis::Ce::ChangeMarker.where(trackable: destination_client).dirty.count }.by(1)
    end
  end

  include_examples 'marks client as dirty', :hmis_custom_assessment
  include_examples 'marks client as dirty', :hmis_hud_assessment
  include_examples 'marks client as dirty', :hmis_hud_enrollment
  include_examples 'marks client as dirty', :hmis_hud_exit

  describe 'household member propagation' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Ada', last_name: 'Lovelace', dob: 30.years.ago.to_date }
    let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Alan', last_name: 'Turing', dob: 50.years.ago.to_date }
    let!(:c1_enrollment) { create :hmis_hud_enrollment, client: c1, data_source: ds1, household_id: 'HH1' }
    let!(:c3_enrollment) { create :hmis_hud_enrollment, client: c3, data_source: ds1, household_id: 'HH2' }

    before do
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)
    end

    def dirty?(client)
      Hmis::Ce::ChangeMarker.where(trackable_id: client.reload.destination_client.id).dirty.exists?
    end

    it 'marks household members dirty when a member joins' do
      create :hmis_hud_enrollment, client: c2, data_source: ds1, household_id: 'HH1'
      expect(dirty?(c1)).to be true
      expect(dirty?(c3)).to be false
    end

    context 'with a second member' do
      let!(:c2_enrollment) { create :hmis_hud_enrollment, client: c2, data_source: ds1, household_id: 'HH1' }

      before { Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all) }

      it 'marks household members dirty when a member exits' do
        create :hmis_hud_exit, enrollment: c2_enrollment, client: c2, data_source: ds1
        expect(dirty?(c1)).to be true
      end

      it 'marks old and new household members dirty when a member moves households' do
        c2_enrollment.update!(household_id: 'HH2')
        expect(dirty?(c1)).to be true
        expect(dirty?(c3)).to be true
      end

      # Member ages read the destination DOB, so propagation happens when ClientCleanup copies a source DOB change to it
      it 'marks household members dirty when ClientCleanup updates a member destination DOB' do
        c2.update!(dob: 5.years.ago.to_date)
        Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)

        GrdaWarehouse::Tasks::ClientCleanup.new(destination_ids: [c2.reload.destination_client.id]).update_client_demographics_based_on_sources
        expect(dirty?(c2)).to be true
        expect(dirty?(c1)).to be true
        expect(dirty?(c3)).to be false
      end

      it 'marks household members dirty when a member enrollment is deleted' do
        c2_enrollment.destroy!
        expect(dirty?(c1)).to be true
      end

      it 'marks household members dirty when a member exit is deleted' do
        exit = create :hmis_hud_exit, enrollment: c2_enrollment, client: c2, data_source: ds1
        Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)
        exit.destroy!
        expect(dirty?(c1)).to be true
      end

      it 'does not mark household members dirty for unrelated enrollment or exit changes' do
        exit = create :hmis_hud_exit, enrollment: c2_enrollment, client: c2, data_source: ds1
        Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)
        c2_enrollment.update!(date_of_engagement: Date.current)
        exit.update!(counseling_received: 1)
        expect(dirty?(c1)).to be false
      end
    end
  end
end

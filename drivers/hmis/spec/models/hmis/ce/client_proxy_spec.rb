###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::ClientProxy, type: :model do
  let!(:destination_client) { create :grda_warehouse_hud_client }
  let!(:source_client) { create :hmis_hud_client }

  describe 'ClientProxy model validations' do
    it 'expects a destination client' do
      proxy = build(:hmis_ce_client_proxy, client: destination_client)
      expect(proxy.valid?).to be_truthy
      expect do
        proxy.save!
      end.to change(Hmis::Ce::ClientProxy, :count).from(0).to(1)
    end

    it 'raises for source client' do
      proxy = build(:hmis_ce_client_proxy, client: source_client)
      expect(proxy.valid?).to be_falsy
      expect do
        proxy.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /must be destination client/)
    end
  end

  describe 'Client deletion behavior' do
    let!(:proxy) { create(:hmis_ce_client_proxy, client: destination_client) }
    let!(:candidate) { create(:hmis_ce_match_candidate, client_proxy: proxy) }

    it 'deletes associated proxies and candidates' do
      expect do
        destination_client.destroy!
      end.to change(Hmis::Ce::Match::Candidate, :count).by(-1).
        and change(Hmis::Ce::ClientProxy, :count).by(-1)

      expect(Hmis::Ce::ClientProxy.find_by(id: proxy.id)).to be_nil
      expect(Hmis::Ce::Match::Candidate.find_by(id: candidate.id)).to be_nil
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ChronicallyHomeless, type: :model do
  describe '#homeless_reset' do
    let(:data_source) { create :grda_warehouse_data_source }
    let(:organization) { create :hud_organization, data_source: data_source }
    let(:client) { create :grda_warehouse_hud_client }
    let(:task) { described_class.new(date: Date.current) }

    def stay(project_type:, last_date:, rrh_sub_type: nil, move_in_date: nil)
      project = create(
        :hud_project,
        data_source: data_source,
        OrganizationID: organization.OrganizationID,
        ProjectType: project_type,
        RRHSubType: rrh_sub_type,
      )
      create(
        :grda_warehouse_service_history,
        :service_history_entry,
        client_id: client.id,
        data_source: data_source,
        project_id: project.ProjectID,
        organization_id: project.OrganizationID,
        project_type: project_type,
        first_date_in_program: last_date - 120.days,
        last_date_in_program: last_date,
        move_in_date: move_in_date,
      )
    end

    it 'ends at the last 90+ day RRH: Services Only stay with a move-in date' do
      stay(project_type: 13, rrh_sub_type: 1, last_date: Date.current - 20.days, move_in_date: Date.current - 130.days)
      stay(project_type: 13, rrh_sub_type: 1, last_date: Date.current - 10.days)
      stay(project_type: 0, last_date: Date.current - 5.days)

      expect(task.homeless_reset(client_id: client.id)).to eq(Date.current - 20.days)
    end

    it 'ends at the last 90+ day RRH with housing stay with a move-in date' do
      stay(project_type: 13, rrh_sub_type: 2, last_date: Date.current - 20.days, move_in_date: Date.current - 130.days)
      stay(project_type: 0, last_date: Date.current - 5.days)

      expect(task.homeless_reset(client_id: client.id)).to eq(Date.current - 20.days)
    end

    it 'ignores RRH stays without a move-in date, for either sub-type' do
      stay(project_type: 13, rrh_sub_type: 2, last_date: Date.current - 20.days)
      stay(project_type: 13, rrh_sub_type: 1, last_date: Date.current - 10.days)

      expect(task.homeless_reset(client_id: client.id)).to be_nil
    end
  end
end

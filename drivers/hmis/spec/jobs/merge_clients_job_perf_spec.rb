###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MergeClientsJob, type: :model do
  context 'performance with larger client sets' do
    let(:data_source) { create(:hmis_data_source) }
    let!(:user) { create(:hmis_hud_user, data_source: data_source) }
    let!(:actor) { create(:user) }
    let(:cded_lang) { create(:hmis_custom_data_element_definition_for_primary_language, data_source: data_source) }
    let(:cded_color) { create(:hmis_custom_data_element_definition_for_color, data_source: data_source) }
    let(:now) { Time.current }

    let!(:projects) do
      3.times.map { create(:hmis_hud_project, data_source: data_source) }
    end

    # Create clients with associated records
    let!(:clients) do
      20.times.map do |i|
        client = create(:hmis_hud_client_complete,
                        pronouns: "they-#{i}",
                        date_created: now - i.days,
                        data_source: data_source)

        # Create associated records for each client
        create(:hmis_hud_custom_client_name, client: client, data_source: data_source)
        create(:hmis_hud_custom_client_contact_point, client: client, data_source: data_source)
        create(:hmis_hud_custom_client_address, client: client, data_source: data_source)

        # Create enrollment and file records
        create(:hmis_hud_enrollment, client: client, data_source: data_source)
        create(:client_file, client_id: client.id, data_source: data_source)

        # Create custom data elements
        create(:hmis_custom_data_element,
               owner: client,
               value_string: "Language-#{i}",
               data_element_definition: cded_lang,
               data_source: data_source)

        create(:hmis_custom_data_element,
               owner: client,
               value_string: "Color-#{i}",
               data_element_definition: cded_color,
               data_source: data_source)

        create :hmis_scan_card_code, client: client

        projects.each do |project|
          create(:hmis_hud_wip_enrollment, client: client, project: project, data_source: data_source)
        end

        client
      end
    end

    let(:client_ids) { clients.map(&:id) }

    it 'completes merge operation within reasonable time' do
      expect do
        Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      end.to perform_under(500).ms.sample(1).times.warmup(0)
    end

    it 'performs a reasonable number of database queries' do
      expect do
        Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      end.to make_database_queries(count: 100..160)
    end
  end
end

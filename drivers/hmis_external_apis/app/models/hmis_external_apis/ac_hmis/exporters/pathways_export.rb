###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Exporters
  class PathwaysExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter
    include ::Hmis::Concerns::HmisArelHelper

    PATHWAY_KEYS = [
      'client_pathway_1',
      'client_pathway_2',
      'client_pathway_3',
      'client_pathway_1_date',
      'client_pathway_2_date',
      'client_pathway_3_date',
      'client_pathway_1_narrative',
      'client_pathway_2_narrative',
      'client_pathway_3_narrative',
    ].freeze

    def run!
      Rails.logger.info 'Generating content of pathways export'

      write_row(columns)
      total = pathway_client_warehouse_id_to_client_ids.count
      Rails.logger.info "There are #{total} clients with pathways to export"

      pathway_client_warehouse_id_to_client_ids.each do |warehouse_id, client_ids|
        # Find the pathway CDE that was most recently updated for this destination client
        most_recent_pathway_cde = client_ids.map { |id| pathways_by_client_id[id] }.flatten.max_by(&:date_updated)

        # Collect all pathways for the source client that most recently had any pathway updated.
        # This makes it so that we don't mix-and-match pathways values from different source clients.
        pathways = pathways_by_client_id[most_recent_pathway_cde.owner_id]

        values = [
          warehouse_id, # Matches PersonalID in HMIS CSV export
          find_pathway(pathways, 'client_pathway_1'),
          find_pathway(pathways, 'client_pathway_1_date'),
          find_pathway(pathways, 'client_pathway_1_narrative'),
          find_pathway(pathways, 'client_pathway_1', date_updated: true),

          find_pathway(pathways, 'client_pathway_2'),
          find_pathway(pathways, 'client_pathway_2_date'),
          find_pathway(pathways, 'client_pathway_2_narrative'),
          find_pathway(pathways, 'client_pathway_2', date_updated: true),

          find_pathway(pathways, 'client_pathway_3'),
          find_pathway(pathways, 'client_pathway_3_date'),
          find_pathway(pathways, 'client_pathway_3_narrative'),
          find_pathway(pathways, 'client_pathway_3', date_updated: true),
        ]
        write_row(values)
      end
    end

    private def find_pathway(pathways, key, date_updated: false)
      raise "unrecognized data element key: #{key}" unless pathway_cded_key_to_id[key]

      cde = pathways.find { |elem| elem.data_element_definition_id == pathway_cded_key_to_id[key] }
      return unless cde

      case key
      when 'client_pathway_1', 'client_pathway_2', 'client_pathway_3'
        date_updated ? cde.date_updated : cde.value_string
      when 'client_pathway_1_date', 'client_pathway_2_date', 'client_pathway_3_date'
        cde.value_date
      when 'client_pathway_1_narrative', 'client_pathway_2_narrative', 'client_pathway_3_narrative'
        cde.value_text&.first(500)
      end
    end

    def columns
      [
        'PersonalID',
        'Pathway1',
        'Pathway1_Date',
        'Pathway1_Narrative',
        'Pathway1_DateUpdated',
        'Pathway2',
        'Pathway2_Date',
        'Pathway2_Narrative',
        'Pathway2_DateUpdated',
        'Pathway3',
        'Pathway3_Date',
        'Pathway3_Narrative',
        'Pathway3_DateUpdated',
      ]
    end

    private def pathway_cded_key_to_id
      @pathway_cded_key_to_id ||= Hmis::Hud::CustomDataElementDefinition.where(key: PATHWAY_KEYS).pluck(:key, :id).to_h
    end

    private def pathways_by_client_id
      @pathways_by_client_id ||= Hmis::Hud::CustomDataElement.
        where(data_element_definition_id: pathway_cded_key_to_id.values). # All Pathway-related definitions
        group_by(&:owner_id) # By Client ID
    end

    # { source client id => warehouse destination client id }
    # This drops the source client id if there are multiple source clients with pathways,
    # so that the resulting CSV does not have duplicated destination client IDs.
    private def pathway_client_warehouse_id_to_client_ids
      @pathway_client_warehouse_id_to_client_ids ||= Hmis::WarehouseClient.joins(:source).
        where(data_source_id: data_source.id).
        where(source_id: pathways_by_client_id.keys). # Only include clients that have Pathways
        group(:destination_id).
        select('"destination_id", array_agg("source_id") as source_ids').
        map { |r| [r.destination_id, r.source_ids] }.to_h
    end
  end
end

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Exporters
  class PathwaysExport
    attr_accessor :output

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

    def initialize(output = StringIO.new)
      require 'csv'
      self.output = output
    end

    def run!
      Rails.logger.info 'Generating content of pathways export'

      write_row(columns)
      total = clients_with_pathways.count
      Rails.logger.info "There are #{total} clients with pathways to export"

      clients_with_pathways.find_each.with_index do |client, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?
        next unless client.warehouse_id.present?

        pathways = pathways_by_client_id[client.id]
        values = [
          client.warehouse_id, # Matches PersonalID in HMIS CSV export
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

    private def write_row(row)
      output << CSV.generate_line(row, **csv_config)
    end

    private def csv_config
      {
        write_converters: ->(value, _) {
          if value.instance_of?(Date)
            value.strftime('%Y-%m-%d')
          elsif value.respond_to?(:strftime)
            value.strftime('%Y-%m-%d %H:%M:%S')
          else
            value
          end
        },
      }
    end

    private def pathway_cded_key_to_id
      @pathway_cded_key_to_id ||= Hmis::Hud::CustomDataElementDefinition.where(key: PATHWAY_KEYS).pluck(:key, :id).to_h
    end

    private def pathways_by_client_id
      @pathways_by_client_id ||= Hmis::Hud::CustomDataElement.
        where(data_element_definition_id: pathway_cded_key_to_id.values). # All Pathway-related definitions
        group_by(&:owner_id) # By Client ID
    end

    private def clients_with_pathways
      @clients_with_pathways ||= Hmis::Hud::Client.where(id: pathways_by_client_id.keys).preload(:warehouse_client_source)
    end

    private def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end
  end
end

module GrdaWarehouse::HMIS
  class ClientAttributeDefinedText <  Base
    dub 'client_attributes_defined_text'

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name, foreign_key: :data_source_id, primary_key: GrdaWarehouse::DataSource.primary_key
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :client_attributes_defined_text

    
  end
end
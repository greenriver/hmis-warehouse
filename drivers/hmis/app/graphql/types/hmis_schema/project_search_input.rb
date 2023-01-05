module Types
  class HmisSchema::ProjectSearchInput < BaseInputObject
    description 'HMIS Project search input'

    argument :id, ID, 'Project primary key', required: false
    argument :text_search, String, 'Omnisearch string', required: false

    def to_params
      OpenStruct.new(to_h.deep_dup)
    end
  end
end

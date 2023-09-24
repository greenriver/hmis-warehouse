###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# CustomDataElementDefinitions.find(key)
module HmisExternalApis::ShHmis::Importers::Loaders
  class CustomDataElementDefinitions
    attr_accessor :data_source_id, :system_user_id
    def initialize(data_source_id:, system_user_id:)
      self.data_source_id = data_source_id
      self.system_user_id = system_user_id
    end

    def find_or_create(owner_type:, key:)
      config = configs.detect { |i| owner_type == i.fetch(:owner_type) && key.to_sym == i.fetch(:key) }
      raise "CDE definition not found #{owner_type}:#{key.inspect}" unless config

      Hmis::Hud::CustomDataElementDefinition
        .where(config.merge(data_source_id: data_source_id))
        .first_or_create! { |r| r.user_id = system_user_id }
    end

    protected

    def configs
      [
        { owner_type: 'Hmis::Hud::Client', field_type: :string, key: :zipcode, label: 'Zip Code' },
        { owner_type: 'Hmis::Hud::CustomService', field_type: :string, key: :flex_funds_types, repeats: true, label: :flex_funds_types.to_s.humanize },
        { owner_type: 'Hmis::Hud::CustomService', field_type: :string, key: :flex_funds_other_details, label: :flex_funds_other_details.to_s.humanize },
        { owner_type: 'Hmis::Hud::CurrentLivingSituation', field_type: :text, key: :current_living_sitution_note, label: 'Notes' },
      ]
    end
  end
end

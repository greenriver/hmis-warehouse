###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisSupplemental
  class CustomDataElementHelper
    attr_accessor :data_set, :user, :today

    def initialize(data_set:, user:, today:)
      self.data_set = data_set
      self.user = user
      self.today = today
      @cache = {}
    end

    def new_cde_record(value:, owner_id:, definition:, date_created: today)
      {
        owner_type: definition.owner_type,
        owner_id: owner_id,
        data_element_definition_id: definition.id,
        DateCreated: date_created,
        DateUpdated: date_created,
        data_source_id: definition.data_source_id,
        UserID: user.id,
      }.merge(cde_value_fields(definition, value))
    end

    protected

    VALUE_FIELDS = [
      'float',
      'integer',
      'boolean',
      'string',
      'text',
      'date',
      'json',
    ].map { |v| [v, "value_#{v}"] }

    # note, we need to set all fields- bulk insert becomes unhappy if the columns are not uniform
    def cde_value_fields(definition, value)
      result = {}
      VALUE_FIELDS.map do |field_type, field_name|
        result[field_name] = field_type == definition.field_type ? value : nil
      end
      result
    end
  end
end

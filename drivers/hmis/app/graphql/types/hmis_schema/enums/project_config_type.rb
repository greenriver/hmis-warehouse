# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class HmisSchema::Enums::ProjectConfigType < Types::BaseEnum
    graphql_name 'HmisProjectConfigType'

    def self.get_project_config_type(cls_name)
      stripped_string = cls_name.gsub(/Hmis::Project/, '').gsub(/Config/, '') # Hmis::ProjectExampleOneConfig -> ExampleOne
      enum_value = stripped_string.underscore.upcase # ExampleOne -> EXAMPLE_ONE
      human_readable = stripped_string.underscore.humanize.titlecase # ExampleOne -> Example One
      value enum_value, value: cls_name, description: human_readable
    end

    def self.mapped_project_config_types = Hmis::ProjectConfig::TYPE_OPTIONS.map do |x|
      [x, get_project_config_type(x)]
    end.to_h

    mapped_project_config_types.values
  end
end

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class FileProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::File
    end

    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      if attribute_name == 'tags'
        @processor.send(factory_name).tag_list = Array(attribute_value)
      elsif attribute_name == 'file_blob_id'
        return if attribute_value.nil?

        blob = ActiveStorage::Blob.find_by(id: attribute_value)
        @processor.send(factory_name).name ||= blob.filename
        @processor.send(factory_name).client_file.attach(blob)
      else
        @processor.send(factory_name).assign_attributes(attribute_name => attribute_value)
      end
    end

    def assign_metadata
      file = @processor.send(factory_name)
      file.assign_attributes(updated_by: @processor.current_user)
      # 'user' is the uploader, so only set it if this is a new file record
      file.assign_attributes(user: @processor.current_user) unless file.persisted?
    end

    def information_date(_)
    end
  end
end

require 'json_schemer'
require 'pathname'

# validate a document (hash) against a json schema
module HmisExternalApis
  class JsonValidator
    def self.perform(...)
      new.perform(...)
    end

    # @param data [Hash] document to validate
    # @param schema_path [String] file path to validation schema
    # @return [Array<String>] validation failure messages
    def perform(data, schema_path)
      schemer = load_schemer(schema_path)

      errors = []
      schemer.validate(data).each do |error|
        errors.push(JSONSchemer::Errors.pretty(error))
      end
      errors
    end

    private

    def load_schemer(path)
      schema = Pathname.new(path)
      JSONSchemer.schema(schema)
    end

    def error_message(error)
      property_name = error['data_pointer'].blank? ? error['data'] : error['data_pointer']&.delete_prefix('/')
      "#{property_name} is invalid"
    end
  end
end

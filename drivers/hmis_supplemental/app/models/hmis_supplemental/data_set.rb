###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisSupplemental
  class DataSet < GrdaWarehouseBase
    self.table_name = 'hmis_supplemental_data_sets'
    has_paper_trail

    belongs_to :remote_credential, class_name: 'GrdaWarehouse::RemoteCredentials::S3'
    accepts_nested_attributes_for :remote_credential

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    validates :owner_type, inclusion: { in: ['enrollment', 'client'] }
    has_many :field_values,
             class_name: 'HmisSupplemental::FieldValue',
             foreign_key: 'data_set_id',
             dependent: :restrict_with_exception
    validates :name, presence: true
    validates :slug, uniqueness: true, presence: true

    scope :viewable_by, ->(user) do
      # FIXME
      current_scope
    end

    serialize :fields, type: Array

    validate :field_configs_validation
    def field_configs_validation
      schema_path = Rails.root.join('drivers/hmis_supplemental/schemas/data_set_fields.json')
      HmisExternalApis::JsonValidator.perform(field_configs, schema_path).each do |error|
        errors.add(:field_configs_string, error)
      end
      dupes = field_configs.group_by { |f| f['key'] }.filter { |_, v| v.many? }.keys
      errors.add(:field_configs_string, "Field keys must be unique. Duplicates: #{dupes.inspect}") if dupes.any?
    end

    def fields
      field_configs.map do |config|
        config = config.transform_keys(&:underscore)
        config[:data_set] = self
        Field.new(**config)
      end
    end

    # accessor for form input
    def field_configs_string
      JSON.pretty_generate(field_configs || []).html_safe
    end

    # accessor for form input
    def field_configs_string=(value)
      self.field_configs = JSON.parse(value)
    rescue JSON::ParserError => e
      errors.add(:field_configs_string, e.message)
    end

    def object_key
      [remote_credential.s3_prefix, "#{slug}.csv"].compact.join('/')
    end
  end
end

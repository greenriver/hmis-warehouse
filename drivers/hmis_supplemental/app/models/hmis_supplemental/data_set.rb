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
             dependent: :delete_all
    validates :name, presence: true
    validates :object_key, presence: true
    has_many :group_viewable_entities,
             class_name: 'GrdaWarehouse::GroupViewableEntity',
             as: :entity,
             dependent: :destroy

    scope :viewable_by, ->(user) do
      # not supporting legacy role base permissions
      return none unless user.using_acls?

      # first ask the WH db for all collections containing this resource type
      gve_scope = GrdaWarehouse::GroupViewableEntity.where(entity_type: sti_name)
      collection_ids = gve_scope.distinct.pluck(:collection_id)

      # go to the App db to filter the collections to just those the user can access with a give permission
      permission = :can_view_supplemental_client_data
      permitted_collection_ids = user.access_controls.joins(:role).where(collection_id: collection_ids).
        merge(Role.where(permission => true)).
        pluck(:collection_id)

      # now go back to the WH db and get the resources that belong to the filtered collections
      scope = where(id: gve_scope.where(collection_id: permitted_collection_ids).select(:entity_id))

      # also restrict by data source
      visible_data_sources_ids = GrdaWarehouse::DataSource.
        viewable_by(user, permission: :can_view_supplemental_client_data).pluck(:id)
      scope.where(data_source: visible_data_sources_ids)
    end

    serialize :fields, type: Array

    validate :field_config_validation
    def field_config_validation
      object = nil
      begin
        object = JSON.parse(field_config)
      rescue JSON::ParserError => e
        errors.add(:field_config, e.message)
        return
      end

      schema_path = Rails.root.join('drivers/hmis_supplemental/schemas/data_set_fields.json')
      HmisExternalApis::JsonValidator.perform(object, schema_path).each do |error|
        errors.add(:field_config, error)
      end
      dupes = object.group_by { |f| f['key'] }.filter { |_, v| v.many? }.keys
      errors.add(:field_config, "Field keys must be unique. Duplicates: #{dupes.inspect}") if dupes.any?
    end

    def fields
      JSON.parse(field_config).map do |config|
        config = config.transform_keys(&:underscore)
        config[:data_set] = self
        Field.new(**config)
      end
    end

    def full_object_key
      [remote_credential.s3_prefix, object_key].compact.join('/')
    end
  end
end

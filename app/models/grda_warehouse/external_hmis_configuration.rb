###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::ExternalHmisConfiguration < GrdaWarehouseBase
  has_paper_trail

  belongs_to :data_source

  ##
  # Constructs a URL for an entity if it belongs to a supported class.
  #
  # @param entity [Object] The entity for which the external HMIS URL should be generated.
  # @return [String, nil] The constructed URL if the entity is supported, otherwise `nil`.
  #
  def url(entity)
    return unless active?

    entity_class_name = entity.class.name
    return unless entity_class_name.in?(known_integrations.keys)

    path = known_integrations[entity_class_name].external_hmis_path(self, entity)
    return unless path

    "#{base_url.chomp('/')}/#{path}"
  end

  def active?
    base_url.present?
  end

  def self.known_params
    [
      :vendor,
      :base_url,
      :path_client,
      :path_enrollment,
      :path_project,
    ]
  end

  # A list of classes with known patterns for linking directly to records in external HMISs.
  # If we learn of new patterns, the `external_hmis_path` method should be updated
  # in the associated class.
  # If we learn of ways to link to new data, add `external_hmis_path` to the appropriate class
  # and add the class to the known classes below
  #
  # @return [Array] An array of warehouse classes with known patterns for linking out to external data
  private def known_integrations
    {
      'GrdaWarehouse::Hud::Client' => ExternalHmis::ClientPath,
    }.freeze
  end

  def known_hmis_vendors
    [
      # 'Open Path', # not including as we currently have a different, native, mechanism
      'WellSky Community Services',
      'ClientTrack',
      'Clarity Human Services',
      'Efforts to Outcomes (ETO)',
      'AWARDS',
      'PlanStreet HMIS',
      'VESTA',
      'Bell Data HMIS',
      'Mission Tracker',
      'CaseWorthy HMIS',
      'Adaptive Enterprise Case Management',
    ]
  end
end

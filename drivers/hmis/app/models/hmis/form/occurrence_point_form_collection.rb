###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Hmis::Form::OccurrencePointFormCollection
#
# This class is responsible for determining which Occurrence Point forms to display on a given Enrollment in HMIS.
# The Occurrence Point forms appear in the "Enrollment Details" card on the HMIS Enrollment dashboard.
#
# These forms collect data elements onto an Enrollment "at occurrence" (a.k.a. when they occur),
# as opposed to data elements that are collected at a specific point in time (e.g. at intake, exit).
###
class Hmis::Form::OccurrencePointFormCollection
  # Struct that backs Types::HmisSchema::OccurrencePointForm
  OccurrencePointForm = Struct.new(:definition, :legacy, :data_collected_about, keyword_init: true)
  private_constant :OccurrencePointForm

  # Occurrence Point forms to display on the Enrollment, including legacy forms to show existing data
  def for_enrollment(enrollment)
    structs = active_for_enrollment(enrollment)
    structs += legacy_for_enrollment(enrollment, active_forms: structs)
    structs
  end

  # Occurrence Point forms that are enabled in the Project. This is only used for purposes of displaying Project configuration.
  def for_project(project)
    occurrence_point_definition_scope.map do |definition|
      # Choose the most specific Instance that enables this FormDefinition for this Project
      best_instance = definition.instances.active.order(updated_at: :desc).detect_best_instance_for_project(project: project)
      next unless best_instance

      create_form_struct(
        definition: definition,
        data_collected_about: best_instance.data_collected_about,
        legacy: false, # not legacy, because there is an active Form Instance enabling it
      )
    end.compact
  end

  private

  # Occurrence Point forms that are enabled for this Enrollment via an active form instance
  def active_for_enrollment(enrollment)
    occurrence_point_definition_scope.map do |definition|
      # Choose the most specific Instance that enables this FormDefinition for this Enrollment
      best_instance = definition.instances.active.order(updated_at: :desc).detect_best_instance_for_enrollment(enrollment: enrollment)
      # If there was no active instance, that means this Occurrence Point form is not enabled. Skip it.
      next unless best_instance

      create_form_struct(
        definition: definition,
        data_collected_about: best_instance.data_collected_about,
        legacy: false, # not legacy, because there is an active Form Instance enabling it
      )
    end.compact
  end

  # Default Occurrence Point forms that collect HUD fields. The system should already enforce that
  # these forms are enabled for the appropriate projects (e.g. Move-in Date collected on HoH in PH).
  # This code ensures that for contexts when the form ISN'T enabled (e.g. Move-in Date on a Child),
  # AND the Enrollment has a value for the primary field it collects (e.g. 'MoveInDate'), we still show the value and the form.
  # This allows users to see the full set of HUD occurrence point data elements, and do data correction.
  HUD_DEFAULT_FORMS = [
    # Note: form_identifier matches the filename of the form, e.g. ../default/occurrence_point_forms/move_in_date.json
    { form_identifier: :move_in_date, field_name: :move_in_date },
    { form_identifier: :date_of_engagement, field_name: :date_of_engagement },
    { form_identifier: :path_status, field_name: :date_of_path_status },
  ].freeze

  def legacy_for_enrollment(enrollment, active_forms:)
    # Add legacy forms to ensure that HUD Data Elements are not hidden.
    # In the event that an Enrollment has a MoveInDate, for example, but there is no active form that collects it,
    # we still need to show it so that user can see the data and perform data correction.
    HUD_DEFAULT_FORMS.map do |config|
      form_identifier, field_name = config.values_at(:form_identifier, :field_name)
      # this enrollment does not have this field (e.g. MoveInDate), skip
      next unless enrollment.send(field_name).present?
      # this field is already collected by an active enable form, skip
      next if active_forms.find { |s| collects_enrollment_field?(s.definition, field_name) }

      definition = occurrence_point_definition_scope.find { |fd| fd.identifier == form_identifier.to_s && fd.managed_in_version_control? }
      raise "Unexpected: #{field_name} present, but default form '#{form_identifier}' not found" unless definition

      create_form_struct(definition: definition, legacy: true)
    end.compact
  end

  def occurrence_point_definition_scope
    @occurrence_point_definition_scope ||= Hmis::Form::Definition.with_role(:OCCURRENCE_POINT).published
  end

  def create_form_struct(definition:, legacy:, data_collected_about: nil)
    OccurrencePointForm.new(
      definition: definition,
      legacy: legacy,
      data_collected_about: data_collected_about || 'ALL_CLIENTS',
    )
  end

  # Check if the given FormDefinition collects the given field from the Enrollment.
  # This is a bit hacky (transforming fieldname to graphql casing) but it works for the known fields (Move-in date, DOE, PATH).
  def collects_enrollment_field?(definition, field_name)
    normalized_field_name = field_name.to_s.camelize(:lower)
    definition.link_id_item_hash.values.any? do |item|
      item.mapping&.record_type == 'ENROLLMENT' && item.mapping&.field_name == normalized_field_name
    end
  end
end

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Client < Types::BaseObject
    include Types::HmisSchema::HasEnrollments
    include Types::HmisSchema::HasServices
    include Types::HmisSchema::HasIncomeBenefits
    include Types::HmisSchema::HasDisabilities
    include Types::HmisSchema::HasHealthAndDvs
    include Types::HmisSchema::HasYouthEducationStatuses
    include Types::HmisSchema::HasEmploymentEducations
    include Types::HmisSchema::HasCurrentLivingSituations
    include Types::HmisSchema::HasAssessments
    include Types::HmisSchema::HasFiles
    include Types::HmisSchema::HasAuditHistory
    include Types::HmisSchema::HasGender
    include Types::HmisSchema::HasCustomDataElements

    def self.configuration
      Hmis::Hud::Client.hmis_configuration(version: '2024')
    end

    available_filter_options do
      arg :project, [ID]
      arg :organization, [ID]
    end

    description 'HUD Client'
    field :id, ID, null: false
    field :external_ids, [Types::HmisSchema::ExternalIdentifier], null: false
    hud_field :personal_id
    hud_field :first_name
    hud_field :middle_name
    hud_field :last_name
    hud_field :name_suffix
    hud_field :name_data_quality, Types::HmisSchema::Enums::Hud::NameDataQuality
    hud_field :dob
    field :age, Int, null: true
    hud_field :dob_data_quality, Types::HmisSchema::Enums::Hud::DOBDataQuality
    hud_field :ssn
    hud_field :ssn_data_quality, Types::HmisSchema::Enums::Hud::SSNDataQuality
    gender_field
    field :race, [Types::HmisSchema::Enums::Race], null: false
    hud_field :veteran_status, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :year_entered_service
    hud_field :year_separated
    hud_field :world_war_ii, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :korean_war, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :vietnam_war, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :desert_storm, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :afghanistan_oef, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :iraq_oif, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :iraq_ond, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :other_theater, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :military_branch, Types::HmisSchema::Enums::Hud::MilitaryBranch
    hud_field :discharge_status, Types::HmisSchema::Enums::Hud::DischargeStatus
    field :pronouns, [String], null: false
    field :names, [HmisSchema::ClientName], null: false
    field :addresses, [HmisSchema::ClientAddress], null: false
    field :contact_points, [HmisSchema::ClientContactPoint], null: false
    field :phone_numbers, [HmisSchema::ClientContactPoint], null: false
    field :email_addresses, [HmisSchema::ClientContactPoint], null: false
    enrollments_field filter_args: { omit: [:search_term, :bed_night_on_date], type_name: 'EnrollmentsForClient' }
    income_benefits_field
    disabilities_field
    health_and_dvs_field
    youth_education_statuses_field
    employment_educations_field
    current_living_situations_field
    assessments_field
    services_field
    files_field
    custom_data_elements_field
    audit_history_field(
      field_permissions: {
        'SSN' => :can_view_full_ssn,
        'DOB' => :can_view_dob,
      },
      transform_changes: ->(version, changes) do
        result = changes
        [
          ['race', Hmis::Hud::Client.race_enum_map, :RaceNone],
          ['gender', Hmis::Hud::Client.gender_enum_map, :GenderNone],
        ].each do |input_field, enum_map, none_field|
          relevant_fields = [*enum_map.base_members.map { |member| member[:key].to_s }, none_field.to_s, input_field]
          next unless changes.slice(*relevant_fields).present?

          result = result.except(*relevant_fields)
          old_client = version.reify

          # Reify the next version to get next values; If no next version, then we're at the latest update and the current object will have the next values
          new_client =  version.next&.reify || version.item

          old_value = { input_field => nil }
          new_value = { input_field => nil }

          old_value = Hmis::Hud::Processors::ClientProcessor.multi_fields_to_input(old_client, input_field, enum_map, none_field) if old_client.present?
          new_value = Hmis::Hud::Processors::ClientProcessor.multi_fields_to_input(new_client, input_field, enum_map, none_field) if new_client.present?

          result = result.merge(input_field => [old_value[input_field], new_value[input_field]])
        end

        # Drop excluded fields
        excluded_fields = ['id', 'DateCreated', 'DateUpdated', 'DateDeleted']
        result.reject! { |k| k.underscore.end_with?('_id') || excluded_fields.include?(k) }

        result
      end,
    )
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
    field :image, HmisSchema::ClientImage, null: true

    access_field do
      can :view_partial_ssn
      can :view_full_ssn
      can :view_dob
      can :view_enrollment_details
      can :edit_enrollments
      can :delete_enrollments
      can :delete_assessments
      can :delete_clients, field_name: :can_delete_client
      can :edit_clients, field_name: :can_edit_client
      can :manage_any_client_files
      can :manage_own_client_files
      can :view_any_nonconfidential_client_files
      can :view_any_confidential_client_files
    end

    def external_ids
      collection = Hmis::Hud::ClientExternalIdentifierCollection.new(
        client: object,
        ac_hmis_mci_ids: load_ar_association(object, :ac_hmis_mci_ids),
        warehouse_client_source: load_ar_association(object, :warehouse_client_source),
      )
      collection.hmis_identifiers + collection.mci_identifiers
    end

    def enrollments(**args)
      resolve_enrollments(**args)
    end

    def income_benefits(**args)
      resolve_income_benefits(**args)
    end

    def disabilities(**args)
      resolve_disabilities(**args)
    end

    def disability_groups(**args)
      resolve_disability_groups(**args)
    end

    def health_and_dvs(**args)
      resolve_health_and_dvs(**args)
    end

    def assessments(**args)
      resolve_assessments(**args)
    end

    def services(**args)
      resolve_services(**args)
    end

    def files(**args)
      resolve_files(**args)
    end

    def pronouns
      object.pronouns&.split('|') || []
    end

    def race
      selected_races = ::HudUtility2024.races.except('RaceNone').keys.select { |f| object.send(f).to_i == 1 }
      selected_races << object.RaceNone if object.RaceNone && selected_races.empty?
      selected_races
    end

    def image
      files = load_ar_association(object, :client_files, scope: GrdaWarehouse::ClientFile.client_photos.newest_first)
      file = files.first&.client_file
      file&.download ? file : nil
    end

    def user
      load_ar_association(object, :user)
    end

    def ssn
      if current_permission?(permission: :can_view_full_ssn, entity: object)
        object.ssn
      elsif current_permission?(permission: :can_view_partial_ssn, entity: object)
        object&.ssn&.sub(/^.*?(\d{4})$/, 'XXXXX\1')
      end
    end

    def dob
      object.dob if current_permission?(permission: :can_view_dob, entity: object)
    end

    def names
      names = load_ar_association(object, :names)
      if names.empty?
        # If client has no CustomClientNames, construct one based on the HUD Client name fields
        return [
          object.names.new(
            id: '0',
            first: object.first_name,
            last: object.last_name,
            middle: object.middle_name,
            suffix: object.name_suffix,
            primary: true,
            **object.slice(:name_data_quality, :user_id, :data_source_id, :date_created, :date_updated),
          ),
        ]
      end

      names
    end

    def contact_points
      load_ar_association(object, :contact_points)
    end

    def phone_numbers
      load_ar_association(object, :contact_points).filter { |r| r.system == 'phone' }
    end

    def email_addresses
      load_ar_association(object, :contact_points).filter { |r| r.system == 'email' }
    end

    def addresses
      load_ar_association(object, :addresses)
    end

    def resolve_audit_history
      address_ids = object.addresses.with_deleted.pluck(:id)
      name_ids = object.names.with_deleted.pluck(:id)
      contact_ids = object.contact_points.with_deleted.pluck(:id)

      v_t = GrPaperTrail::Version.arel_table
      client_changes = v_t[:item_id].eq(object.id).and(v_t[:item_type].in(['Hmis::Hud::Client', 'GrdaWarehouse::Hud::Client']))
      address_changes = v_t[:item_id].in(address_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientAddress'))
      name_changes = v_t[:item_id].in(name_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientName'))
      contact_changes = v_t[:item_id].in(contact_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientContactPoint'))

      GrPaperTrail::Version.where(client_changes.or(address_changes).or(name_changes).or(contact_changes)).
        where.not(object_changes: nil, event: 'update').
        unscope(:order).
        order(created_at: :desc)
    end
  end
end

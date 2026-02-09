###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class ProjectProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      project = @processor.send(factory_name)

      attributes = case attribute_name
      when 'residential_affiliation_project_ids'
        process_residential_affiliations(value)

      # Process 'initial' fields -- CoC, funder, etc. -- if this is a new project.
      # These process_initial_ methods read the values needed from @hud_values,
      # so skip processing if there's already a record (to prevent creating duplicates)
      when 'initial_coc_code', 'initial_geocode'
        project.new_record? && project.project_cocs.none? ? process_initial_coc_fields : {}
      when 'initial_funder', 'initial_other_funder', 'initial_funder_grant_id'
        project.new_record? && project.funders.none? ? process_initial_funder_fields : {}
      when 'initial_ce_access_point', 'initial_ce_prevention_assessment', 'initial_ce_crisis_assessment', 'initial_ce_housing_assessment', 'initial_ce_direct_services', 'initial_ce_receives_referrals'
        project.new_record? && project.ce_participations.none? ? process_initial_ce_participation_fields : {}
      when 'initial_hmis_participation_type'
        # Only one value related to HMIS participation type is collected, so no need to check for duplicates
        project.new_record? ? process_initial_hmis_participation_fields(value) : {}
      else
        { attribute_name => attribute_value }
      end

      project.assign_attributes(attributes)
    end

    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Project
    end

    def information_date(_)
    end

    private

    def process_residential_affiliations(value)
      project = @processor.send(factory_name)

      selected_projects_pks = Array.wrap(value).map(&:to_i)
      selected_projects_hud_ids = Hmis::Hud::Project.where(id: selected_projects_pks).pluck(:ProjectID)

      old_affiliations_by_id = project.affiliations.pluck(:id, :res_project_id).to_h
      old_project_hud_ids = old_affiliations_by_id.values

      # ResProjectIDs that we need new Affiliation records for
      res_projects_to_add = (selected_projects_hud_ids - old_project_hud_ids).uniq

      # Primary keys of Affiliation records that should be removed
      affiliations_to_remove = old_affiliations_by_id.reject do |_affiliation_pk, res_project_id|
        selected_projects_hud_ids.include?(res_project_id)
      end.keys.uniq

      {
        affiliations_attributes: [
          *res_projects_to_add.map do |res_project_id|
            {
              res_project_id: res_project_id,
              user: @processor.hud_user,
              **project.slice(:project_id, :data_source_id),
            }
          end,
          *affiliations_to_remove.map { |id| { id: id, _destroy: 1 } },
        ],
      }
    end

    def related_record_attributes
      project = @processor.send(factory_name)
      {
        user: @processor.hud_user,
        **project.slice(:project_id, :data_source_id),
      }
    end

    def process_initial_coc_fields
      coc_code = @hud_values['initialCocCode']
      geocode = @hud_values['initialGeocode']
      return unless coc_code || geocode

      {
        project_cocs_attributes: [
          related_record_attributes.merge(
            coc_code: coc_code,
            geocode: geocode,
          ),
        ],
      }
    end

    def process_initial_funder_fields
      funder = @hud_values['initialFunder']
      other_funder = @hud_values['initialOtherFunder']
      grant_id = @hud_values['initialFunderGrantId']
      start_date = @hud_values['operatingStartDate']
      return unless funder || other_funder || grant_id

      {
        funders_attributes: [
          related_record_attributes.merge(
            funder: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::FundingSource, funder),
            other_funder: attribute_value_for_enum(nil, other_funder), # _HIDDEN => nil
            grant_id: grant_id,
            start_date: start_date,
          ),
        ],
      }
    end

    def process_initial_hmis_participation_fields(value)
      return {} unless value.present?

      {
        hmis_participations_attributes: [
          related_record_attributes.merge(
            hmis_participation_type: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::HMISParticipationType, value),
            hmis_participation_status_start_date: @hud_values['operatingStartDate'],
          ),
        ],
      }
    end

    def process_initial_ce_participation_fields
      # 'initial_ce_access_point', 'initial_ce_prevention_assessment', 'initial_ce_crisis_assessment', 'initial_ce_housing_assessment', 'initial_ce_direct_services', 'initial_ce_receives_referrals'
      access_point = @hud_values['initialCeAccessPoint']
      prevention_assessment = @hud_values['initialCePreventionAssessment']
      crisis_assessment = @hud_values['initialCeCrisisAssessment']
      housing_assessment = @hud_values['initialCeHousingAssessment']
      direct_services = @hud_values['initialCeDirectServices']
      receives_referrals = @hud_values['initialCeReceivesReferrals']
      return {} unless access_point || prevention_assessment || crisis_assessment || housing_assessment || direct_services || receives_referrals

      {
        ce_participations_attributes: [
          related_record_attributes.merge(
            access_point: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::AdHocYesNo, access_point),
            prevention_assessment: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::AdHocYesNo, prevention_assessment),
            crisis_assessment: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::AdHocYesNo, crisis_assessment),
            housing_assessment: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::AdHocYesNo, housing_assessment),
            direct_services: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::AdHocYesNo, direct_services),
            receives_referrals: attribute_value_for_enum(Types::HmisSchema::Enums::Hud::AdHocYesNo, receives_referrals),
            ce_participation_status_start_date: @hud_values['operatingStartDate'],
          ),
        ],
      }
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HMIS
  class Assessment < Base
    dub 'assessments'
    include RailsDrivers::Extensions

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', foreign_key: :data_source_id, primary_key: GrdaWarehouse::DataSource.primary_key

    has_many :hmis_forms, class_name: 'GrdaWarehouse::HmisForm', primary_key: [:assessment_id, :site_id, :data_source_id], foreign_key: [:assessment_id, :site_id, :data_source_id]

    scope :confidential, -> do
      where(confidential: true)
    end
    scope :non_confidential, -> do
      where(confidential: false)
    end
    scope :window, -> do
      active.where(exclude_from_window: false)
    end
    scope :window_with_details, -> do
      window.where(details_in_window_with_release: true)
    end

    scope :active, -> do
      where(active: true)
    end

    scope :health, -> do
      where(health: true)
    end

    scope :rrh_assessment, -> do
      where(rrh_assessment: true)
    end

    scope :triage_assessment, -> do
      where(triage_assessment: true)
    end

    scope :vispdat, -> do
      where(vispdat: true)
    end

    scope :ssm, -> do
      where(ssm: true)
    end

    scope :health_case_note, -> do
      where(health_case_note: true)
    end

    scope :health_has_qualifying_activities, -> do
      where(health_has_qualifying_activities: true)
    end

    scope :hud_assessment, -> do
      where(hud_assessment: true)
    end

    scope :pathways, -> do
      where(pathways: true)
    end

    scope :covid_19_impact_assessments, -> do
      where(covid_19_impact_assessment: true)
    end

    scope :health_for_user, -> (user) do
      if user.can_administer_health?
        joins(:hmis_forms).merge(GrdaWarehouse::HmisForm.health_touch_points)
      else
        none
      end
    end

    scope :for_user, -> (user) do
      user_scope = all
      # remove confidential if you don't have health access
      if ! user.can_administer_health?
         user_scope = non_confidential
      end
      # limit to the window if you can't edit clients
      if ! user.can_edit_clients?
        user_scope = user_scope.window
      end
      user_scope
    end

    scope :fetch_for_data_source, -> (ds_id) do
      where(data_source_id: ds_id).where(fetch: true)
    end

    def self.update_touch_points
      Rails.logger.info 'Fetching Touch Points'
      touch_points = fetch_touch_points()
      assessments = fetch_assessments()
      add_missing(touch_points: touch_points, assessments: assessments)
      # FIXME: temporarily leave all touch points active
      # deactivate_inactive(touch_points: touch_points, assessments: assessments)
      Rails.logger.info 'Touch Points Fetched'
    end

    def self.add_missing touch_points:, assessments:
      api_configs = EtoApi::Base.api_configs.values.index_by{|m| m['data_source_id']}
      touch_points.each do |key, tp|
        next if assessments[key] == tp
        assessment_id = key[:assessment_id]
        assessment = self.where(
          data_source_id: key[:data_source_id],
          site_id: key[:site_id],
          assessment_id: assessment_id
        ).first_or_create do |assessment|
          assessment.name = tp[:name]
          assessment.active = tp[:active]
        end
        assessment.name = tp[:name]
        assessment.active = tp[:active]
        assessment.site_name = tp[:site_name]
        assessment.last_fetched_at = Time.now
        assessment.save
      end
    end

    def self.deactivate_inactive touch_points:, assessments:
      missing = assessments.keys - touch_points.keys
      missing.each do |key|
        all.where(key).update_all(active: false)
      end
    end

    def self.fetch_assessments
      all.pluck(:data_source_id, :site_id, :assessment_id, :name, :active).
        map do |data_source_id, site_id, assessment_id, name, active|
          [
            {
              data_source_id: data_source_id,
              site_id: site_id,
              assessment_id: assessment_id
            },
            {
              name: name,
              active: active,
            }
          ]
        end.to_h
    end

    def self.fetch_touch_points
      touch_points = {}
      GrdaWarehouse::EtoApiConfig.active.find_each do |config|
        data_source_id = config.data_source_id
        bo = Bo::ClientIdLookup.new(data_source_id: data_source_id)
        response = bo.fetch_site_touch_point_map
        break unless response.present?
        response.each do |row|
          next unless row[:site_unique_identifier].present?
          touch_points[
            {
              data_source_id: data_source_id,
              site_id: row[:site_unique_identifier].to_i,
              assessment_id: row[:touchpoint_unique_identifier].to_i,
            }
          ] = {
            name: row[:touchpoint_name],
            site_name: row[:site],
            active: true, # We don't have a means of pulling state currently
          }
        end
      end

      return touch_points
    end
  end
end

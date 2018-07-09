module GrdaWarehouse::HMIS
  class Assessment < Base
    dub 'assessments'

    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name, foreign_key: :data_source_id, primary_key: GrdaWarehouse::DataSource.primary_key

    has_many :hmis_forms, class_name: GrdaWarehouse::HmisForm.name, primary_key: [:assessment_id, :site_id, :data_source_id], foreign_key: [:assessment_id, :site_id, :data_source_id]

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
      touch_points = fetch_touch_points()
      assessments = fetch_assessments()
      add_missing(touch_points: touch_points, assessments: assessments)
      deactivate_inactive(touch_points: touch_points, assessments: assessments)
    end

    def self.add_missing touch_points:, assessments:
      touch_points.each do |key, tp|
        next if assessments[key] == tp
        assessment = self.where(
          data_source_id: key[:data_source_id],
          site_id: key[:site_id],
          assessment_id: key[:assessment_id]
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

    # This touch point doesn't show up in the API when a list is requested
    # but can be pulled down for each client, and contains the HUD touch point data
    def self.hud_touch_point(site_id:, data_source_id:, site_name:)
      assessment_id = if data_source_id == 1
        75
      elsif data_source_id == 3
        128
      end
      {
        {
          data_source_id: data_source_id,
          site_id: site_id,
          assessment_id: assessment_id
        } => {
          name: "HUD Assessment (Entry/Update/Annual/Exit)",
          site_name: site_name,
          active: true
        }
      }
    end

    def self.fetch_touch_points
      api_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/eto_api.yml")).result)[Rails.env]
      touch_points = {}
      api_config.each do |connection_key, config|
        data_source_id = config['data_source_id']
        api = EtoApi::Base.new(trace: false, api_connection: connection_key)
        api.connect
        api.sites.each do |site_id, name|
          touch_points.merge!(hud_touch_point(site_id: site_id, data_source_id: data_source_id, site_name: name))
          api.programs(site_id: site_id).each do |program_id, program_name|
            api.set_program(site_id: site_id, program_id: program_id)
            begin
              api.touch_points(site_id: site_id, program_id: program_id).each do |touch_point|
                touch_point = touch_point.with_indifferent_access
                # puts "#{touch_point[:TouchPointName]} at site #{name} in progam #{program_name}"
                touch_points[
                  {
                    data_source_id: data_source_id,
                    site_id: site_id,
                    assessment_id: touch_point[:TouchPointID]
                  }
                ] = {
                  name: touch_point[:TouchPointName],
                  site_name: name,
                  active: ! touch_point[:IsDisabled],
                }
              end
            rescue RestClient::ExceptionWithResponse => e
              Rails.logger.error "Failed to fetch assessments for #{connection_key} in site #{name} with error: #{e}"
            end
          end
        end
      end
      return touch_points
    end
  end
end
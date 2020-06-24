###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthEmergency
  extend ActiveSupport::Concern
  included do
    acts_as_paranoid
    has_paper_trail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :user
    belongs_to :agency

    scope :newest_first, -> do
      order(created_at: :desc)
    end
  end

  def pill_title
    title
  end

  def show_pill_in_history?
    true
  end

  def show_pill_in_search_results?
    show_pill_in_history?
  end
end

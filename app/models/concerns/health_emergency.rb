###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthEmergency
  extend ActiveSupport::Concern
  included do
    acts_as_paranoid
    has_paper_trail

    # Each including class declares its own belongs_to :client, since required-ness varies by
    # model (most require a client; GrdaWarehouse::HealthEmergency::UploadedTest allows a nil
    # one, pre-reconciliation). Redeclaring an association here and again in a subclass doesn't
    # cleanly override a presence validator the first declaration added.
    belongs_to :user, optional: true
    belongs_to :agency, optional: true

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

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class Anomaly < GrdaWarehouseBase
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user, foreign_key: :submitted_by
    has_many :notes, through: :client, source: :anomaly_notes

    scope :resolved, -> { where(status: :resolved) }
    scope :unresolved, -> { where.not(status: :resolved) }
    scope :newly_minted, -> { where(status: :new) }

    has_paper_trail

    def self.available_stati
      {
        new: 'New',
        in_process: 'In Process',
        needs_feedback: 'Needs Feedback',
        resolved: 'Resolved',
      }
    end

    def self.status_title(status)
      available_stati[status]
    end

    def current_status
      self.class.available_stati[status.to_sym]
    end

    def resolved?
      status == :resolved
    end

    def in_process?
      status == :in_process
    end

    def needs_feedback?
      status == :needs_feedback
    end

    def newly_minted?
      status == :new
    end

    def involved_user_ids
      (versions.pluck(:whodunnit).map(&:to_i) + [submitted_by]).uniq
    end
  end
end
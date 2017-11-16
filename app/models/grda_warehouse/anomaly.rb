module GrdaWarehouse
  class Anomaly < GrdaWarehouseBase
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    has_many :notes, through: :client, source: :anomaly_notes
    
    scope :resolved, -> { where(status: :resolved) }
    scope :unresolved, -> { where.not.where(status: :resolved) }
    scope :newly_minted, -> { where(status: :new) }
    
    def self.available_stati
      {
        new: 'New',
        in_process: 'In Process',
        needs_feedback: 'Needs Feedback',
        resolved: 'Resolved',
      }
    end

    def current_status
      available_stati[status]
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
  end
end
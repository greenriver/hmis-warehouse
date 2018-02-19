module GrdaWarehouse
  class AvailableFileTag < GrdaWarehouseBase
    include DefaultFileTypes

    scope :ordered, -> do 
      order(weight: :asc, group: :asc, name: :asc)
    end

    scope :consent_forms, -> do
      where(consent_form: true)
    end

    scope :document_ready, -> do
      where(document_ready: true)
    end

    scope :notification_triggers, -> do
      where(notification_trigger: true)
    end

    def self.contains_consent_form?(tag_names=[])
      consent_forms.where(name: tag_names).exists?
    end

    def self.should_send_notifications?(tag_names=[])
      notification_triggers.where(name: tag_names).exists?
    end

    def self.grouped
      groups = []

      self.ordered.group_by{|tag| tag.group}
    end
  end
end

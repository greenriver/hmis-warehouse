module Health
  class Goal::Base < HealthBase
    self.table_name = 'health_goals'
    has_paper_trail class_name: Health::HealthVersion.name
    acts_as_paranoid

    belongs_to :careplan, class_name: Health::Careplan.name
    delegate :patient, to: :careplan

    validates_presence_of :name, :number, :type

    def self.type_name
      raise 'Implement in sub-class'
    end

    def type_name
      self.class.type_name
    end


    def self.available_types
      [
        Health::Goal::Clinical,
        Health::Goal::Housing,
        Health::Goal::Social,
        Health::Goal::SelfManagement,
      ]
    end

    def self.available_numbers
      (1..4)
    end
  end
end
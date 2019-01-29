module GrdaWarehouse::YouthIntake
  class Base < GrdaWarehouseBase
    self.table_name = :youth_intakes
    has_paper_trail
    acts_as_paranoid

    def self.any_visible_by?(user)
      user.can_view_youth_intake? || user.can_edit_youth_intake?
    end

    def self.any_modifiable_by(user)
      user.can_edit_youth_intake?
    end
  end
end
module GrdaWarehouse
  class EnrollmentExtra < GrdaWarehouseBase
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', inverse_of: :enrollment_extras
  end
end
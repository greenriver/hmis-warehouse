module ArelTable
  extend ActiveSupport::Concern
  included do
    # Some shortcuts for arel tables
    def sh_t
      GrdaWarehouse::ServiceHistory.arel_table
    end
    def e_t
      GrdaWarehouse::Hud::Enrollment.arel_table
    end
    def ds_t
      GrdaWarehouse::DataSource.arel_table
    end
    def c_t
      GrdaWarehouse::Hud::Client.arel_table
    end
    def p_t
      GrdaWarehouse::Hud::Project.arel_table
    end
  end
end
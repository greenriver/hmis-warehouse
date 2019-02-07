module GrdaWarehouse::Youth
  class DirectFinancialAssistance < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    scope :ordered, -> do
      order(provided_on: :desc)
    end

    scope :visible_by?, -> (user) do
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end


    def available_types
      @available_types ||= [
        'Move-in costs',
        'Rent',
        'Rent arrears',
        'Utilities',
        'Transportation-related costs',
        'Education-related costs',
        'Legal costs',
        'Child care',
        'Work-related costs',
        'Medical costs',
        'Cell phone costs',
        'Food / Groceries (including our drop-in food pantries)',
      ].sort + ['Other']
    end
  end
end
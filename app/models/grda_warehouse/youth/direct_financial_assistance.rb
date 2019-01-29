module GrdaWarehouse::Youth
  class DirectFinancialAssistance < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    def self.available_types
      [
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
        'Other',
      ]
    end
  end
end
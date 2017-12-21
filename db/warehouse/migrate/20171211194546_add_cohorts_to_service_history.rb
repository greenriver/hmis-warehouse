class AddCohortsToServiceHistory < ActiveRecord::Migration
  def up
    any_to_add = (columns.keys.map(&:to_s) - GrdaWarehouse::ServiceHistory.column_names).any?
    return unless any_to_add
    sql = "ALTER TABLE  #{GrdaWarehouse::ServiceHistory.quoted_table_name} "
    sql << columns.select do |column, _|
      ! GrdaWarehouse::ServiceHistory.column_names.include?(column.to_s)
    end.map do |column, options|
      "ADD COLUMN \"#{column}\" #{options[:type]} DEFAULT #{options[:default]} NOT NULL"
    end.compact.join(', ')
    puts "Adding columns: #{sql}"
    GrdaWarehouseBase.connection.execute(sql)
  end
  def down
    sql = "ALTER TABLE #{GrdaWarehouse::ServiceHistory.quoted_table_name} "
    sql << columns.map do |column, options|
      "DROP COLUMN IF EXISTS \"#{column}\""
    end.join(', ')
    puts "Removing columns: #{sql}"
    GrdaWarehouseBase.connection.execute(sql)
  end

  def columns
    {
      other_clients_over_25: {
        type: :integer,
        default: 0,
        null: false,
      },
      other_clients_under_18: {
        type: :integer,
        default: 0,
        null: false,
      },
      other_clients_between_18_and_25: {
        type: :integer,
        default: 0,
        null: false,
      },
      unaccompanied_youth: {
        type: :boolean,
        default: false,
        null: false,
      },
      parenting_youth: {
        type: :boolean,
        default: false,
        null: false,
      },
      parenting_juvenile: {
        type: :boolean,
        default: false,
        null: false,
      },
      children_only: {
        type: :boolean,
        default: false,
        null: false,
      },
      individual_adult: {
        type: :boolean,
        default: false,
        null: false,
      },
      individual_elder: {
        type: :boolean,
        default: false,
        null: false,
      },
      head_of_household: {
        type: :boolean,
        default: false,
        null: false,
      },
    }.freeze
  end
end

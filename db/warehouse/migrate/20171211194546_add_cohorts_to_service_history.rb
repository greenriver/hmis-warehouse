class AddCohortsToServiceHistory < ActiveRecord::Migration
  def up
    
    sql = "ALTER TABLE #{GrdaWarehouse::ServiceHistory.quoted_table_name} "
    sql << columns.map do |column, options|
      "ADD COLUMN \"#{column}\" #{options[:type]} DEFAULT #{options[:default]} NOT NULL"
    end.join(', ')
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
      family: {
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
    }.freeze
  end
end

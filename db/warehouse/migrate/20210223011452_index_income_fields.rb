class IndexIncomeFields < ActiveRecord::Migration[5.2]
  def change
    add_index :IncomeBenefits, :InformationDate
    add_index :IncomeBenefits, [:Earned, :DataCollectionStage], name: 'idx_earned_stage'
    add_index :IncomeBenefits, [:IncomeFromAnySource, :DataCollectionStage], name: 'idx_any_stage'
  end
end

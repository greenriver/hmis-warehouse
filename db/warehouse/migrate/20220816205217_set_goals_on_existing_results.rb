class SetGoalsOnExistingResults < ActiveRecord::Migration[6.1]
  def up
    # Allow existing reports to continue to function
    CePerformance::Results::ClientsScreened.where(goal: nil).update_all(goal: 100)
    CePerformance::Results::SuccessfulDiversion.where(goal: nil).update_all(goal: 5)
    CePerformance::Results::TimeInProjectAverage.where(goal: nil).update_all(goal: 30)
    CePerformance::Results::TimeInProjectMedian.where(goal: nil).update_all(goal: 30)
    CePerformance::Results::EntryToReferralAverage.where(goal: nil).update_all(goal: 5)
    CePerformance::Results::EntryToReferralMedian.where(goal: nil).update_all(goal: 5)
    CePerformance::Results::ReferralToHousingAverage.where(goal: nil).update_all(goal: 5)
    CePerformance::Results::ReferralToHousingMedian.where(goal: nil).update_all(goal: 5)
    CePerformance::Results::TimeOnListAverage.where(goal: nil).update_all(goal: 30)
    CePerformance::Results::TimeOnListMedian.where(goal: nil).update_all(goal: 30)
  end
end

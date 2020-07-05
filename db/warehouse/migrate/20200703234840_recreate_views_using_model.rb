class RecreateViewsUsingModel < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def up
    updater = Bi::ViewMaintainer.new
    say_with_time 'Removing old BI views' do
      updater.remove_views
    end
    say_with_time 'Adding new BI views' do
      updater.create_views
    end
  end

  def down
    say_with_time 'Removing BI views' do
      Bi::ViewMaintainer.new.remove_views
    end
  end
end

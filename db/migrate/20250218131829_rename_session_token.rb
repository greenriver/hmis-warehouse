class RenameSessionToken < ActiveRecord::Migration[7.0]
  def change
    # Renaming before it ever hit production, this is safe
    safety_assured do
      rename_column :users, :session_token, :custom_session_invalidator
    end

    change_column_comment :users, :custom_session_invalidator, 'Changing the value of this column will invalidate the current session for the user.'
  end
end

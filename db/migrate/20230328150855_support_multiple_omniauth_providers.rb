class SupportMultipleOmniauthProviders < ActiveRecord::Migration[6.1]
  def change
    create_table "oauth_identities" do |t|
      t.timestamps
      t.references :user, index: false
      t.string :provider, null: false
      t.json :raw_info
      t.string :uid, null: false, index: true
      t.index [:provider, :uid], name: "idx_oauth_on_provider_and_uid", unique: true
      t.index [:user_id, :provider], unique: true
    end
    reversible do |dir|
      dir.up do
        data_migration
      end
    end

    # remove these cols once multi-providers is stable
    remove_index(:users, [:uid, :provider], unique: true)
    rename_column :users, :provider, :deprecated_provider
    rename_column :users, :provider_set_at, :deprecated_provider_set_at
    rename_column :users, :uid, :deprecated_uid
    rename_column :users, :provider_raw_info, :deprecated_provider_raw_info
  end

  protected

  def data_migration
    rows = []
    User.where.not(provider: nil).find_each do |user|
      rows.push({
        user_id: user.id,
        provider: user.provider,
        created_at: user.provider_set_at,
        updated_at: user.provider_set_at,
        uid: user.uid,
        raw_info: user.provider_raw_info,
      })
    end
    OauthIdentity.reset_column_information
    OauthIdentity.import!(rows)
  end
end

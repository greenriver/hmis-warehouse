class RemoveSlugFromRemoteCredentials < ActiveRecord::Migration[6.1]
  # see #185000178
  def change
    reversible do |dir|
      dir.up do
        data_migration
      end
    end
    rename_column :remote_credentials, :slug, :deprecated_slug
  end

  def data_migration
    scope = GrdaWarehouse::RemoteCredential.where.not(slug: nil)
    scope.order(:id).each do |rc|
      case rc.slug
      when 'mper'
        rc.type = 'HmisExternalApis::AcHmis::MperCredential'
      when 'mci'
        rc.type = 'HmisExternalApis::AcHmis::MciCredential'
      when 'clientview'
        rc.type = 'HmisExternalApis::AcHmis::ClientView'
      else
        raise "unknown slug #{rc.slug}"
      end
      rc.save!
    end
  end

end

class AdjustRemoteCredentialData < ActiveRecord::Migration[6.1]
  # use prefixed slugs for remote credentials. Set the namespace
  # on the relevant external ids
  def up
    mapping.each do |old_name, new_name, namespace|
      GrdaWarehouse::RemoteCredential.where(slug: old_name).each do |rc|
        rc.update!(slug: new_name)
        rc.external_ids.update_all(namespace: namespace) if namespace
      end
    end
  end

  def down
    mapping.each do |old_name, new_name, _|
      GrdaWarehouse::RemoteCredential.where(slug: new_name).each do |rc|
        rc.update!(slug: old_name)
      end
    end
  end

  def mapping
    [
      ['clientview', 'ac_hmis_clientview', nil],
      ['mci', 'ac_hmis_mci', 'ac_hmis_mci'],
      ['mper', 'ac_hmis_mper', 'ac_hmis_mper'],
    ]
  end
end

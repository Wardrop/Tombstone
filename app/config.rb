config = {
  search_record_limit: 250,
  base_url: nil, # Set to `nil` to have it dynamically set at runtime.
  email: {
    from: 'noreply@tombstone.msc.local',
    delivery_method: :sendmail
  },
  ldap: {
    servers: ['msc.local'], # An array of LDAP servers
    domain: 'msc.local',
    username: 'tombstone_user',
    password: '10Pippl$ah'
  },
  roles: {
    :operator => {
      :can_create => true,
      :can_edit => true,
      :can_delete => true,
      :can_approve => false,
      :can_inter => false,
      :can_complete => false,
      :can_delete_legacy => false,
      :can_delete_provisional => true,
      :can_delete_pending => true,
      :can_delete_approved => false,
      :can_delete_interred => false,
      :can_delete_completed => false,
      :can_edit_legacy => true,
      :can_edit_provisional => true,
      :can_edit_pending => true,
      :can_edit_approved => true,
      :can_edit_interred => false,
      :can_edit_completed => false,
      :can_edit_deleted => false,
      :can_delete_files => false,
      :can_manage_cemeteries => false
    },
    :coordinator => {
      :can_create => true,
      :can_edit => true,
      :can_delete => true,
      :can_approve => true,
      :can_inter => true,
      :can_complete => true,
      :can_delete_legacy => false,
      :can_delete_provisional => true,
      :can_delete_pending => true,
      :can_delete_approved => true,
      :can_delete_interred => true,
      :can_delete_completed => true,
      :can_edit_legacy => true,
      :can_edit_provisional => true,
      :can_edit_pending => true,
      :can_edit_approved => true,
      :can_edit_interred => true,
      :can_edit_completed => true,
      :can_edit_deleted => false,
      :can_delete_files => true,
      :can_manage_cemeteries => true
    },
    :default => {
      
    }
  }
}

if PADRINO_ENV == 'demo'
  config[:ldap] = {
    servers: ['localhost'],
    domain: 'tombstone.local',
    username: 'tombstone',
    password: 'Passw0rd'
  }
end

config
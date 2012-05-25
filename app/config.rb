{
  email: {
    from: 'noreply@tombstone.trc.local',
    operator_email: 'tombstone_operators@trc.local',
    coordinator_email: 'tomw@trc.qld.gov.au'
  },
  base_url: 'http://tombstone.trc.local',
  ldap: {
    servers: ['trcdc01.trc.local', 'trcdc02.trc.local'],
    domain: 'trc.local',
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
      :can_delete_approved => false,
      :can_delete_interred => false,
      :can_delete_completed => false,
      :can_edit_approved => true,
      :can_edit_interred => false,
      :can_edit_completed => false,
      :can_delete_photos => false,
      :can_manage_cemeteries => false
    },
    :coordinator => {
      :can_create => true,
      :can_edit => true,
      :can_delete => true,
      :can_approve => true,
      :can_inter => true,
      :can_complete => true,
      :can_delete_approved => true,
      :can_delete_interred => true,
      :can_delete_completed => true,
      :can_edit_approved => true,
      :can_edit_interred => true,
      :can_edit_completed => true,
      :can_delete_photos => true,
      :can_manage_cemeteries => true
    },
    :default => {
      :can_create => false,
      :can_edit => false,
      :can_delete => false
    }
  }
}
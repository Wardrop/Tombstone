{
  ldap: {
    servers: ['trcdc01.trc.local', 'trcdc02.trc.local'],
    domain: 'trc.local',
    username: 'tombstone_user',
    password: '10Pippl$ah'
  },
  roles: {
    :operator => {
      :can_approve => false,
      :can_inter => false,
      :can_complete => false,
      :can_delete_provisional => true,
      :can_delete_pending => true,
      :can_delete_approved => false,
      :can_delete_completed => false,
      :can_create_burials => true,
      :can_edit_provisional_burials => true,
      :can_edit_pending_burials => true,
      :can_edit_approved_burials => false,
      :can_edit_interred_burials => false,
      :can_create_reservation => true,
      :can_edit_reservation => true,
      :can_delete_photos => false,
      :can_manage_cemeteries => false
    },
    :supervisor => {
      :can_approve => true,
      :can_inter => true,
      :can_complete => true,
      :can_delete_provisional => true,
      :can_delete_pending => true,
      :can_delete_approved => true,
      :can_delete_completed => true,
      :can_create_burials => true,
      :can_edit_provisional_burials => true,
      :can_edit_pending_burials => true,
      :can_edit_approved_burials => true,
      :can_edit_interred_burials => true,
      :can_create_reservation => true,
      :can_edit_reservation => true,
      :can_delete_photos => true,
      :can_manage_cemeteries => true
    },
    :default => {
      
    }
  }
}
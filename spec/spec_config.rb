{
  db: {
    host: 'trcsql02.trc.local',
    user: 'trc\trcadmin',
    password: 'Tr@1nWrk',
    database: 'Tombstone_Dev'
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
    :parks => {
      :can_approve => true,
      :can_inter => true,
      :can_complete => false,
      :can_delete_provisional => false,
      :can_delete_pending => false,
      :can_delete_approved => false,
      :can_delete_completed => false,
      :can_create_burials => false,
      :can_edit_provisional_burials => false,
      :can_edit_pending_burials => false,
      :can_edit_approved_burials => false,
      :can_edit_interred_burials => false,
      :can_create_reservation => false,
      :can_edit_reservation => false,
      :can_delete_photos => false,
      :can_manage_cemeteries => false
    }
  }
}
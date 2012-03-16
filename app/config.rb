{
    general: {
        :hostname => 'localhost',
        :port => 9292
    },
    notification: {
        :enabled => false,
        :email => {
            :from => 'noreply@tombstone.trc.local',
            :cc => 'tatej@trc.qld.gov.au',
            :subject => '[#<%= interment.id %>] Notification of Burial is "<%= interment.status.capitalize %>"',
            :body =>
"A request for a new burial is '<%= interment.status.capitalize %>'.

      Deceased: <%= deceased.title %> <%= deceased.given_name %> <%= deceased.surname %>
      Cemetery: <%= place.description %>
      Type: <%= interment.interment_type.capitalize %>
      At: <%= interment.interment_date.strftime('%A %d %B %Y') %>

For more details <%= interment_site_url %>",
        },
        :status_rules => {
            :rule_1 => {:from => 'pending', :to => 'approved', :notify => 'tatej@trc.qld.gov.au'},
            :rule_2 => {:from => nil, :to => 'pending', :notify => 'tatej@trc.qld.gov.au'}
        }
    },
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
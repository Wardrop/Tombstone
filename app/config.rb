{
  general: {
    :hostname => 'localhost',
    :port => 9292
  },
  notification: {
    :enabled => true,
    :email => {
        :from => 'noreply@tombstone.trc.local',
        :cc => 'tomw@trc.qld.gov.au',
        :subject => 'Notification of Burial is "<%= interment.status.capitalize %>" [#<%= interment.id %>]',
        :body =>
        "A request for a new burial is '<%= interment.status.capitalize %>'.

    Deceased: <%= deceased.title %> <%= deceased.given_name %> <%= deceased.surname %>
    Cemetery: <%= place.description %>
    Type: <%= print { interment.interment_type.capitalize } %>
    At: <%= print { buinterment.interment_date } %>
    
    For more details <%= interment_site_url %>"
    },
    :status_rules => {
      :rule_1 => {:from_status => 'pending', :to_status => 'approved', :notify => 'tomw@trc.qld.gov.au'},
      :rule_2 => {:from_status => nil, :to_status => 'pending', :notify => 'tomw@trc.qld.gov.au'},
      :rule_3 => {:from_status => nil, :to_status => 'provisional', :notify => 'tomw@trc.qld.gov.au'}
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
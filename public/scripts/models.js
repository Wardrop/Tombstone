// JavaScript Document
Ts.Person = Backbone.Model.extend({
	defaults: {
    id: undefined,
		title: null,
		surname: null,
		given_name: null,
		middle_initials: null,
		gender: null,
		date_of_birth: null,
		date_of_death: null
	},
  urlRoot: '/person',
  initialize: function () {
    this.errors = []
  },
  validate: function () {
    this.errors.length = 0
    if(!this.get("given_name")) {
      this.errors.push("A given name must be entered.")
    }
    
    if(this.errors.length > 0) {
      return true
    }
  }
})

Ts.Address = Backbone.Model.extend({
	defaults: {
    id: undefined,
		street_address: null,
		town: null,
		state: null,
		postal_code: null,
		primary_phone: null,
		secondary_phone: null
	},
  initialize: function () {
    this.errors = []
  },
  validate: function () {
    this.errors.length = 0
    if(!this.get("street_address")) {
      this.errors.push("A street address must be entered.")
    }
    
    if(this.errors.length > 0) {
      return true
    }
  }
})

Ts.Role = Backbone.Model.extend({
	defaults: {
    id: undefined,
		type: null,
		person: null,
		residential_address: null,
		mailing_address: null,
	},
  initialize: function () {
    if(!this.get('person')) this.set({person: new Ts.Person})
    if(!this.get('residential_address')) this.set({residential_address: new Ts.Address})
    if(!this.get('mailing_address')) this.set({mailing_address: new Ts.Address})
  }
})

Ts.PlaceList = Backbone.Model.extend({
  defaults: {
    type: null,
    places: null,
    selected: null
  }
})

Ts.RoleWizard = Backbone.Model.extend({
	defaults: {
		title: 'Untitled',
    role: null,
		currentPage: null,
    pageHistory: null,
    isLoading: false
	},
  initialize: function () {
    if(!this.get('pageHistory')) this.set({pageHistory: []})
    this.bind('change:currentPage', this.currentPageChanged, this)
  },
  currentPageChanged: function () {
    if(this.previous('currentPage')) {
      this.get('pageHistory').push(this.previous('currentPage'))
    }
  }
})
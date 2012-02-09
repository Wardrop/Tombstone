// JavaScript Document
Ts = {}

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
  errors: [],
  urlRoot: '/person',
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

Ts.Contact = Backbone.Model.extend({
	defaults: {
    id: undefined,
		street_address: null,
		town: null,
		state: null,
		postal_code: null,
		primary_phone: null,
		secondary_phone: null
	},
  errors: [],
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
		person: new Ts.Person,
		residential_contact: new Ts.Contact,
		mailing_contact: new Ts.Contact,
	}
})

Ts.Wizard = Backbone.Model.extend({
	defaults: {
		title: 'Untitled',
		currentPage: null,
    pageHistory: [],
    isLoading: false
	},
  initialize: function () {
    this.bind('change:currentPage', this.currentPageChanged, this)
  },
  currentPageChanged: function () {
    if(this.previous('currentPage')) {
      this.get('pageHistory').push(this.previous('currentPage'))
    }
  }
})
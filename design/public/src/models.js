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
  urlRoot: '/person'
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
	}
})

Ts.Role = Backbone.Model.extend({
	defaults: {
    id: undefined,
		type: null,
		person: new Ts.Person,
		residential_address: new Ts.Address,
		mailing_address: new Ts.Address,
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
// JavaScript Document
Ts = {}

Ts.Person = Backbone.Model.extend({
	defaults: {
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
		type: 'residential',
		address: null,
		town: null,
		state: null,
		postal_code: null,
		primary_phone: null,
		secondary_phone: null
	}
})

Ts.Role = Backbone.Model.extend({
	defaults: {
		type: null,
		person: null,
		residential_address: null,
		mailing_address: null
	}
})

Ts.Wizard = Backbone.Model.extend({
	defaults: {
		title: 'Untitled',
		body: null
	}
})
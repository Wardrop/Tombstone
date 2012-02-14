window.contacts = []

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
	errors: {},
  urlRoot: '/person',
  initialize: function () {
    this.errors = {}
  },
  serverValidate: function (callbacks) {
    Object.keys(this.errors).length = 0
    $.ajax(this.urlRoot+'/validate', {
      type: 'GET',
      dataType: 'json',
      data: this.toJSON(),
      success: _.bind( function (data, textStatus, jqXHR) {
        if(data.valid == true) {
          callbacks.valid()
        } else {
          this.errors = data.errors
          callbacks.invalid(data.errors)
        }
      }, this),
      error: callbacks.error,
      complete: callbacks.complete
    })
  }
})

Ts.Contact = Backbone.Model.extend({
	defaults: {
    id: undefined,
		street_address: null,
		town: null,
		state: null,
		postal_code: null,
    email: null,
		primary_phone: null,
		secondary_phone: null
	},
	errors: {},
	urlRoot: '/contact',
  initialize: function () {
    window.contacts.push(this)
    this.errors = []
  },
	// serverValidate: function () {
	//   this.errors.length = 0
	// 	$.ajax(this.urlRoot+'/validate', {
	// 		async: false,
	// 		type: 'GET',
	// 		dataType: 'json',
	// 		data: this.toJSON(),
	// 		success: _.bind( function (data, textStatus, jqXHR) {
	// 			this.errors = data.errors
	// 		}, this)
	// 	})
	// 	return this.errors.length == 0
	// }
  serverValidate: function (callbacks) {
    this.errors.length = 0
    $.ajax(this.urlRoot+'/validate', {
      type: 'GET',
      dataType: 'json',
      data: this.toJSON(),
      success: _.bind( function (data, textStatus, jqXHR) {
        if(data.valid == true) {
          callbacks.valid()
        } else {
          this.errors = data.errors
          callbacks.invalid(data.errors)
        }
      }, this),
      error: callbacks.error,
      complete: callbacks.complete
    })
  }
})

Ts.Role = Backbone.Model.extend({
	defaults: {
    id: undefined,
		type: null,
		person: null,
		residential_contact: null,
		mailing_contact: null,
	},
  initialize: function () {
    if(!this.get('person')) this.set({person: new Ts.Person})
    if(!this.get('residential_contact')) this.set({residential_contact: new Ts.Contact})
    if(!this.get('mailing_contact')) this.set({mailing_contact: new Ts.Contact})
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
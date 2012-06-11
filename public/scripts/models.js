Ts.Model = Backbone.Model.extend({
  initialize: function () {
    this.errors = {}
    this._valid = false
    this.on('change', function () { this.valid(false) })
  },
  serverValidate: function (callbacks) {
    this.errors = {}
    Backbone.sync('read', this, {
      url: this.urlRoot+'/validate',
      success: _.bind( function (data, textStatus, jqXHR) {
        if(data.valid) {
          this.valid(true)
          callbacks.valid()
        } else {
          this.valid(false)
          callbacks.invalid()
        }
      }, this),
      error: _.bind( function (jqXHR, textStatus, errorThrown) {
        this.valid(false)
        callbacks.invalid()
      }, this)
    })
  },
  hasRequired: function () {
    var hasRequired = true
    if(this.required) {
      this.required.forEach( function (field) {
        if (!this.get(field)) hasRequired = false
      }, this)
    }
    return hasRequired
  },
  sync: function(method, model, options) {
    options = options || {}
    if (method != 'create') {
      options.url = model.url + '/' + model.get('id')
    }
    Backbone.sync(method, model, options);
  },
  valid: function (value) {
    if (value == undefined) {
      return this._valid
    } else {
      this._valid = !!value
      this.trigger('validityChange', this)
      return this._valid
    }
  },
  // Consider an object with all falsey values as empty.
  isEmpty: function () {
    var hasTrue = false 
    _.each(this.attributes, function (value, key) {
      if(!hasTrue) hasTrue = !!value
    })
    return !hasTrue
  }
})

Ts.Person = Ts.Model.extend({
	defaults: {
    id: undefined,
		title: null,
		surname: null,
		given_name: null,
		middle_name: null,
		gender: null,
		date_of_birth: null,
		date_of_death: null
	},
  required: ['title', 'surname', 'given_name', 'gender', 'date_of_birth'],
  urlRoot: '/person'
})

Ts.Contact = Ts.Model.extend({
	defaults: {
    id: undefined,
		street_address: null,
		town: null,
		state: null,
    country: null,
		postal_code: null,
    email: null,
		primary_phone: null,
		secondary_phone: null
	},
  required: ['street_address', 'town', 'state', 'country', 'postal_code'],
	urlRoot: '/contact'
})

Ts.Role = Ts.Model.extend({
	defaults: {
    id: undefined,
		type: null,
		person: null,
		residential_contact: null,
		mailing_contact: null
	},
  initialize: function () {
    if(!this.get('person')) this.set({person: new Ts.Person})
    if(this.get('residential_contact') && this.get('residential_contact').isEmpty()) this.set('residential_contact', null)
    if(this.get('mailing_contact') && this.get('mailing_contact').isEmpty()) this.set('mailing_contact', null)
  },
  valid: function () {
    window.tester = this
    return !!(
      this.get('person').valid() &&
      (
        (this.get('residential_contact') && this.get('residential_contact').valid()) ||
        (this.get('mailing_contact') && this.get('mailing_contact').valid())
      )
    )
  }
})

Ts.Place = Ts.Model.extend({
  url: '/place',
  defaults: {
		id: undefined,
  	parent_id: null,
  	name: null,
  	type: null,
  	status: null,
  	max_interments: null
	}
})

Ts.Wizard = Ts.Model.extend({
	defaults: {
		title: 'Untitled',
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

Ts.RoleWizard = Ts.Wizard.extend({

})

Ts.PlaceWizard = Ts.Wizard.extend({

})

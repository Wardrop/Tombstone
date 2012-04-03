Ts.Model = Backbone.Model.extend({
  initialize: function () {
    this.errors = {}
  },
  serverValidate: function (callbacks) {
    this.errors = {}
    Backbone.sync('read', this, {
      url: this.urlRoot+'/validate',
      success: _.bind( function (data, textStatus, jqXHR) {
        if(data.valid) {
          callbacks.valid()
        } else {
          this.errors = data.errors
          callbacks.invalid(data.errors)
        }
      }, this)
    })
    
    // $.ajax(this.urlRoot+'/validate', {
    //   type: 'GET',
    //   dataType: 'json',
    //   data: this.toJSON(),
    //   success: _.bind( function (data, textStatus, jqXHR) {
    //     if(data.valid == true) {
    //       callbacks.valid()
    //     } else {
    //       this.errors = data.errors
    //       callbacks.invalid(data.errors)
    //     }
    //   }, this),
    //   error: callbacks.error,
    //   complete: callbacks.complete
    // })
  },
  sync: function(method, model, options) {
    options = options || {}
    if (method != 'create') {
      options.url = model.url + '/' + model.get('id')
    }
    Backbone.sync(method, model, options);
  }
})

Ts.Person = Ts.Model.extend({
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

Ts.Contact = Ts.Model.extend({
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
    if(!this.get('residential_contact')) this.set({residential_contact: new Ts.Contact})
    if(!this.get('mailing_contact')) this.set({mailing_contact: new Ts.Contact})
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
    role: null,
		currentPage: null,
    pageHistory: null,
    isLoading: false
	},
  initialize: function () {
    if(!this.get('pageHistory')) this.set({pageHistory: []})
    this.bind('change:currentPage', function () {
      if(this.previous('currentPage')
         && this.previous('currentPage') != this.get('pageHistory')
      ) {
        this.get('pageHistory').push(this.previous('currentPage'))
      }
    }, this)
  }
})

Ts.PlaceWizard = Ts.Model.extend({
	defaults: {
		title: 'Untitled',
    place: null,
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

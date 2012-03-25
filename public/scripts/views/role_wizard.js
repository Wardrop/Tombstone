// JavaScript Document
$( function () {
  Ts.RoleWizardViews = {}
	Ts.RoleWizardViews.FindPersonForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#role_wizard\\:person_form_template').html()),
		initialize: function () {
      Ts.WizardViews.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
  
  Ts.RoleWizardViews.CreatePersonForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#role_wizard\\:person_form_template').html()),
		initialize: function () {
      Ts.WizardViews.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
	
	Ts.RoleWizardViews.ContactForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#role_wizard\\:create_contact_form_template').html()),
		initialize: function () {
     Ts.WizardViews.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
  
	Ts.RoleWizardViews.PersonResults = Ts.WizardViews.BasePage.extend({
		template: _.template($('#role_wizard\\:person_results_template').html()),
		initialize: function () {
      Ts.WizardViews.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template())
      if(this.collection.length > 0) {
        this.collection.each(function (person) {
          this.$('.blocks').append((new Ts.RoleWizardViews.PersonBlock({model: person, wizard: this.wizard})).render().el)
        }, this)
      } else {
        this.$('.blocks').append('<small class="padded">No matches found.</small>')
      }
			return this
    }
	})
  
  Ts.RoleWizardViews.ContactResults = Ts.WizardViews.BasePage.extend({
		template: _.template($('#role_wizard\\:contact_results_template').html()),
		initialize: function () {
      Ts.WizardViews.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template())
      if(this.collection.length > 0) {
        this.collection.each(function (contact) {
          this.$('.blocks').append((new Ts.RoleWizardViews.ContactBlock({model: contact, wizard: this.wizard})).render().el)
        }, this)
      } else {
        this.$('.blocks').append('<small class="padded">No matches found.</small>')
      }
			return this
    }
	})
  
  Ts.RoleWizardViews.PersonBlock = Ts.View.extend({
    className: 'row_block clickable',
    template: _.template($('#role_wizard\\:person_block_template').html()),
    events: {
      'click' : 'doAction'
    },
    initialize: function (opts) {
      this.wizard = opts.wizard
      _.bindAll(this, 'doAction')
    },
    render: function () {
      $(this.el).html(this.template({person: this.model.toJSON()}))
			return this
    },
    doAction: function (e) {
      var action = $(e.target).data('action')
      this.wizard.savePerson(this.model)
      return false
    }
  })
  
  Ts.RoleWizardViews.ContactBlock = Ts.View.extend({
    className: 'row_block clickable',
    template: _.template($('#role_wizard\\:contact_block_template').html()),
    events: {
      'click' : 'doAction'
    },
    initialize: function (opts) {
      this.wizard = opts.wizard
      _.bindAll(this, 'doAction')
    },
    render: function () {
      $(this.el).html(this.template({contact: this.model.toJSON()}))
			return this
    },
    doAction: function (e) {
      var action = $(e.target).data('action')
      this.wizard.saveContact(this.model)
      return false
    }
  })
  
	Ts.RoleWizardViews.RoleReview = Ts.WizardViews.BasePage.extend({
		template: _.template($('#role_wizard\\:role_review_template').html()),
		initialize: function (opts) {
      Ts.WizardViews.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template(this.model.recursiveToJSON()))
			return this
    }
	})
  
	Ts.RoleWizardViews.WizardView = Ts.WizardViews.Wizard.extend({
    initialize: function () {
      Ts.WizardViews.Wizard.prototype.initialize.apply(this, arguments)
      this.showFindPersonForm()
    },
    showFindPersonForm: function () {
      this.findPersonModel = new Ts.Person
      var findPersonForm = new Ts.RoleWizardViews.FindPersonForm({model: this.findPersonModel, wizard: this, action: 'findPeople'})
      this.model.set({currentPage: findPersonForm})
    },
    showCreatePersonForm: function () {
      var createPersonForm = new Ts.RoleWizardViews.CreatePersonForm({model: this.findPersonModel, wizard: this, action: 'savePerson'}, 'savePerson')
      this.model.set({currentPage: createPersonForm})
    },
    showCreateContactForm: function () {
      var contactForm = new Ts.RoleWizardViews.ContactForm({model: this.model.get('role').get('residential_contact'), wizard: this})
      this.model.set({currentPage: contactForm})
    },
    showRoleReview: function () {
      var roleReview = new Ts.RoleWizardViews.RoleReview({model: this.model.get('role'), wizard: this})
      this.model.set({currentPage: roleReview})
    },
    findPeople: function (person) {
      var matches = new Ts.People()
      var self = this
      this.model.set({isLoading: true})
      matches.fetch({
        success: _.bind( function (collection, response) {
          var resultsView = new Ts.RoleWizardViews.PersonResults({collection: collection, wizard: this})
          this.model.set({currentPage: resultsView, isLoading: false})
        }, this),
        error: this.ajaxErrorHandler(this),
        data: person.toJSON()
      })
    },
    findContacts: function (person) {
      var contacts = new Ts.Contacts()
      var self = this
      this.model.set({isLoading: true})
      contacts.fetch({
        success: function (results) {
          var resultsView = new Ts.RoleWizardViews.ContactResults({collection: results, wizard: self})
          self.model.set({currentPage: resultsView, isLoading: false})
        },
        error: this.ajaxErrorHandler(this),
        data: {person_id: person.get('id')}
      })
    },
    savePerson: function (person) {
      this.model.get('role').set({person: person})
      if(person.get('id')) {
        this.findContacts(person)
      } else {
        this.model.set({isLoading: true})
				person.serverValidate({
					valid: _.bind( function () { this.showCreateContactForm() }, this),
					invalid: _.bind( function (errors) { this.showCreatePersonForm() }, this),
					error: this.ajaxErrorHandler(this, 'jQuery'),
          complete: _.bind(function () { this.model.set({isLoading: false}) }, this)
				})
      }
    },
    saveContact: function (contact) {
      if(contact.get('id')) {
        this.model.get('role').set({residential_contact: contact})
        this.showRoleReview()
      } else {
        this.model.set({isLoading: true})
				contact.serverValidate({
					valid: _.bind( function () { this.showRoleReview() }, this),
					invalid: _.bind( function (errors) { this.showCreateContactForm() }, this),
					error: this.ajaxErrorHandler(this, 'jQuery'),
          complete: _.bind(function () { this.model.set({isLoading: false}) }, this)
				})
      }
    },
    saveRole: function () {
      this.close()
      this.onComplete(this.model.get('role'))
    }
	})
})

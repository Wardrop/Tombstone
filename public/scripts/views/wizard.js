$( function () {
  Ts.WizardViews = {}
  Ts.WizardViews.BasePage = Ts.View.extend({
    events: {
      'click input[type=button]': 'doAction',
      'keyup': function (e) { if(e.keyCode == 13) this.doAction() }
    },
  	initialize: function () {
  	  this._super('initialize', arguments)
      this.wizard = this.options.wizard
      _.bindAll(this, 'doAction')
      this.options.scrollToErrors = false
  	},
    doAction: function (e) {
      var action = null
      if (e && e.target) {
  		  action = $(e.target).data('action')
      } else {
        action = this.$('input[data-action]').data('action')
      }
      this.wizard[action](this.model)
      return false
  	}
  })

  Ts.WizardViews.GenericForm = Ts.WizardViews.BasePage.extend({
    tagName: 'form',
  	className: 'rowed',
    events: _.extend({}, Ts.WizardViews.BasePage.prototype.events, {
      'change' : 'formChanged'
    }),
  	initialize: function () {
  	  this._super('initialize', arguments)
      this.model.on('change', this.modelChanged, this)
  		_.bindAll(this, 'formChanged');
  	},
  	render: function () {
  		$(this.el).html(this.template({data: this.model.toJSON(), wizard: this.wizard, action: this.options.action}));
      this.populateForm(this.model.toJSON())
  		return this
  	},
    formChanged: function (e) {
      var target = $(e.target)
      var name = target.attr("name")
      var hash = {}
      if(target.is('[type=checkbox]')) {
        hash[name] = target.is(':checked') ? target.val() : null
      } else {
        hash[name] = target.val()
      }
      this.model.set(hash, {silent: true})
    },
    modelChanged: function () {
      this.populateForm(this.model.changedAttributes())
    },
    populateForm: function (hash) {
      _.each(hash, function (value, key) {
        var field = this.$('[name='+key+']')
        if(field.attr('type') == 'date' && value) {
          value = Date.parse(value).toString('dd/MM/yyyy') // We need to reverse the date format due to JavaScript americanised parser.
        }
        field.fieldValue(value)
      }, this)
    }
  })
  
  Ts.WizardViews.Wizard = Ts.View.extend({
    className: 'overlay_background',
		templateId: 'wizard:wizard_template',
		events: {
			'click .close' : 'close',
      'click .back' : 'goBack',
			'click' : 'closeOnBlur'
		},
		initialize: function () {
		  this._super('initialize', arguments)
			_.bindAll(this, 'close', 'goBack', 'closeOnBlur')
			this.model.bind('change:currentPage', this.renderPage, this)
      //this.model.bind('change:isLoading', this.renderLoader, this)
      this.onComplete = this.options.onComplete || new Function
      this.options.scrollToErrors = false
      $('body').prepend(this.$el.css({display: 'none'}))
		},
		render: function () {
			this.$el.css({display: ''})
			this.$el.children().detach()
      this.$el.append(this.template({data: this.model.toJSON()}))
      this.$('.body').prepend(this.indicator)
      this.$('.body').prepend(this.errorBlock)
			this.renderPage()
      //this.renderLoader()
			return this
		},
    renderPage: function () {
      this.hideErrors()
      this.$('.body > .page').children().detach()
      model = this.model.get('currentPage') && this.model.get('currentPage').model
      if (model && model.errors && Object.keys(model.errors).length > 0) {
        this.showErrors(model.errors)
      } else {
        this.hideErrors()
      }
      if(this.model.get('currentPage')) {
        this.$('.body > .page').html(this.model.get('currentPage').render().el)
      }
    },
    renderLoader: function () {
      if(this.model.get('isLoading')) {
        this.indicator.addClass('loading').css('display', '')
      } else {
        this.indicator.removeClass('loading').css('display', 'none')
      }
    },
		close: function () {
			this.remove()
		},
    closeOnBlur: function  (e) {
			if(e.target == this.el) {
				this.close()
      }
		},
    goBack: function () {
      var backDestination = this.model.get('pageHistory').pop()
      if(backDestination) {
        if (backDestination.model) Object.keys(backDestination.model.errors).length = 0
        this.model.set({currentPage: backDestination}, {silent: true})
        this.renderPage()
      }
    }
  })
  
  
  /*** Place Wizard Views ***/

  Ts.WizardViews.PlaceWizard = Ts.WizardViews.Wizard.extend({
    showPlaceForm: function () {
      placeForm = new Ts.WizardViews.PlaceForm({
        model: this.model.get('place'),
        wizard: this,
        indicator: this.indicator,
        errorBlock: this.errorBlock
      })
      this.model.set({currentPage: placeForm})
    },
    savePlace: function (place) {
      place.save({}, {
        success: _.bind( function (model, x, y) {
				  this.close()
          this.onComplete(this.model.get('place'))
				}, this)
      })
    }
  })
  
  Ts.WizardViews.PlaceForm = Ts.WizardViews.GenericForm.extend({
    templateId: 'wizard:place_form_template'
  })
  
  
  /*** Role Wizard Views ***/
  
  Ts.WizardViews.RoleWizard = Ts.WizardViews.Wizard.extend({
    initialize: function () {
      this._super('initialize', arguments)
      this.showFindPersonForm()
      this.bindToSync(this.model.get('role').get('residential_contact'))
      this.bindToSync(this.model.get('role').get('mailing_contact'))
    },
    showFindPersonForm: function () {
      this.bindToSync(this.findPersonModel = new Ts.Person)
      var findPersonForm = new Ts.WizardViews.FindPersonForm({
        model: this.findPersonModel,
        wizard: this,
        action: 'findPeople'
      })
      this.model.set({currentPage: findPersonForm})
    },
    showCreatePersonForm: function () {
      var createPersonForm = new Ts.WizardViews.CreatePersonForm({
        model: this.findPersonModel,
        wizard: this,
        action: 'savePerson'
      })
      this.model.set({currentPage: createPersonForm})
    },
    showCreateContactForm: function () {
      var contactForm = new Ts.WizardViews.ContactForm({model: this.model.get('role').get('residential_contact'), wizard: this})
      this.model.set({currentPage: contactForm})
    },
    showRoleReview: function () {
      var roleReview = new Ts.WizardViews.RoleReview({model: this.model.get('role'), wizard: this})
      this.model.set({currentPage: roleReview})
    },
    findPeople: function (person) {
      this.bindToSync(people = new Ts.People)
      // this.model.set({isLoading: true})
      people.fetch({
        success: _.bind( function (collection, response) {
          var resultsView = new Ts.WizardViews.PersonResults({
            collection: collection,
            wizard: this
          })
          this.model.set({currentPage: resultsView/*, isLoading: false*/})
        }, this),
        data: person.toJSON()
      })
    },
    findContacts: function (person) {
      this.bindToSync(contacts = new Ts.Contacts)
      // this.model.set({isLoading: true})
      contacts.fetch({
        success: _.bind( function (results) {
          var resultsView = new Ts.WizardViews.ContactResults({collection: results, wizard: this})
          this.model.set({currentPage: resultsView/*, isLoading: false*/})
        }, this),
        data: {person_id: person.get('id')}
      })
    },
    savePerson: function (person) {
      this.model.get('role').set({person: person})
      if(person.get('id')) {
        this.findContacts(person)
      } else {
        // this.model.set({isLoading: true})
				person.serverValidate({
					valid: _.bind( function () { this.showCreateContactForm() }, this),
					invalid: _.bind( function () { this.renderPage() }, this)
				})
      }
    },
    saveContact: function (contact) {
      if(contact.get('id')) {
        this.model.get('role').set({residential_contact: contact})
        this.showRoleReview()
      } else {
        // this.model.set({isLoading: true})
				contact.serverValidate({
					valid: _.bind( function () { this.showRoleReview() }, this),
					invalid: _.bind( function () { this.showCreateContactForm() }, this)
				})
      }
    },
    saveRole: function () {
      this.close()
      this.onComplete(this.model.get('role'))
    }
	})
  
  Ts.WizardViews.FindPersonForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#wizard\\:person_form_template').html())
	})
  
  Ts.WizardViews.CreatePersonForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#wizard\\:person_form_template').html())
	})
	
	Ts.WizardViews.ContactForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#wizard\\:create_contact_form_template').html())
	})
  
	Ts.WizardViews.PersonResults = Ts.WizardViews.BasePage.extend({
		template: _.template($('#wizard\\:person_results_template').html()),
    render: function () {
      $(this.el).html(this.template())
      if(this.collection.length > 0) {
        this.collection.each(function (person) {
          this.$('.blocks').append((new Ts.WizardViews.PersonBlock({model: person, wizard: this.wizard})).render().el)
        }, this)
      } else {
        this.$('.blocks').append('<small class="padded">No matches found.</small>')
      }
			return this
    }
	})
  
  Ts.WizardViews.ContactResults = Ts.WizardViews.BasePage.extend({
		template: _.template($('#wizard\\:contact_results_template').html()),
    render: function () {
      $(this.el).html(this.template())
      if(this.collection.length > 0) {
        this.collection.each(function (contact) {
          this.$('.blocks').append((new Ts.WizardViews.ContactBlock({model: contact, wizard: this.wizard})).render().el)
        }, this)
      } else {
        this.$('.blocks').append('<small class="padded">No matches found.</small>')
      }
			return this
    }
	})
  
  Ts.WizardViews.PersonBlock = Ts.View.extend({
    className: 'row_block clickable',
    template: _.template($('#wizard\\:person_block_template').html()),
    events: {
      'click' : 'doAction'
    },
    initialize: function () {
      this._super('initialize', arguments)
      this.wizard = this.options.wizard
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
  
  Ts.WizardViews.ContactBlock = Ts.View.extend({
    className: 'row_block clickable',
    template: _.template($('#wizard\\:contact_block_template').html()),
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
  
	Ts.WizardViews.RoleReview = Ts.WizardViews.BasePage.extend({
		template: _.template($('#wizard\\:role_review_template').html()),
    render: function () {
      $(this.el).html(this.template(this.model.recursiveToJSON()))
			return this
    }
	})
	
})
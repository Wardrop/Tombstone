$( function () {
  Ts.WizardViews = {}
  Ts.WizardViews.BasePage = Ts.View.extend({
    events: {
      'click input[type=button][data-action]': 'doAction'
    },
  	initialize: function () {
  	  this._super('initialize', arguments)
      this.wizard = this.options.wizard
      _.bindAll(this, 'doAction')
      this.options.scrollToErrors = false
  	},
    doAction: function (e) {
      var self = this
      // Wrapped in a setTimeout because of some of the timing of events in vendor libraries. It's annoying as hell, but this is the easiest fix.
      setTimeout( function () {
        var action = null
        if (e && e.target) {
    		  action = $(e.target).data('action')
        } else {
          action = self.$('input[data-action]').data('action')
        }
        self.wizard[action](self.model)
      }, 80)
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
    // Broken out of render() method to allow adding or overriding behaviour before delegating events and populating form values.
    renderTemplate: function () {
      this.$el.html(this.template({data: this.model.toJSON(), wizard: this.wizard, action: this.options.action, view: this})).prepend(this.errorBlock);
      this.$el.append(this.indicator)
    },
  	render: function () {
      this.$el.empty()
      this.renderTemplate()
      this.delegateEvents()
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
        hash[name] = target.val().constructor == Array ? target.val()[0] : target.val()
      }
      this.model.set(hash)
    },
    modelChanged: function () {
      window.test = this
      this.populateForm(this.model.changedAttributes())
    },
    populateForm: function (hash) {
      var match;
      var self = this;
      _.each(hash, function (value, key) {
        var field = this.$('[name='+key+']')
        if(field.attr('type') == 'date' && value) {
          if (match = value.match(/([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2,4})/)) {
            value = moment(new Date(match[3], match[2]-1, match[1]))
          } else {
            value = moment(value)
          }
          value = (Ts.supportsDateInput) ? value.format('YYYY-MM-DD') : value.format('DD/MM/YYYY')
        }
        if(field.attr('type') == 'datetime' && value) {
          if (match = value.match(/([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{2,4}) ([0-9]{2}):([0-9]{2})([a-zA-Z]{2})/)) {
            value = moment(new Date(match[3], match[2]-1, match[1], (match[6].toUpperCase() == "PM" ? 12 + match[4] : match[4]), match[5]))
          } else {
            value = moment(value)
          }
          value = (Ts.supportsDateTimeInput) ? value.format('YYYY-MM-DDTHH-mm-ss') : value.format('DD/MM/YYYY hh:mma')
        }
        if(field.attr('type') == 'radio') {
          var item = field.filter('[value='+(value && value.toLowerCase())+']')
          if (!item.is(':checked')) {
            item.click()
          }
        } else {
          if (value != field.val()) {
            field.fieldValue(value)
          }
        }
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
      this.options.showCloseButton = true
      this.options.showBackButton = false
      this.options.scrollToErrors = false
			_.bindAll(this, 'close', 'goBack', 'closeOnBlur')
			this.model.bind('change:currentPage', this.renderPage, this)
      this.onComplete = this.options.onComplete || new Function
      $('body').prepend(this.$el.css({display: 'none'}))
		},
		render: function () {
			this.$el.css({display: '', 'margin-right': $('body').css('marginRight')})
			this.$el.children().detach()
      this.$el.append(this.template({data: this.model.toJSON()}))
      if (this.options.showCloseButton) $('<a class="close" href="javascript:void(0)" title="Close"></a>').appendTo(this.$('.heading > .inner'))
      if (this.options.showBackButton) $('<a class="back" href="javascript:void(0)" title="Go Back"></a>').appendTo(this.$('.heading > .inner'))
      this.$('.body').prepend(this.indicator)
      this.$('.body').prepend(this.errorBlock)
			this.renderPage()
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
        this.$('.body > .page').append(this.model.get('currentPage').render().el)
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
  
  Ts.WizardViews.WarningOverlay = Ts.WizardViews.Wizard.extend({
    events: _.extend({}, Ts.WizardViews.Wizard.prototype.events, {
      'click [name=ok]:not(.disabled)': 'confirm'
		}),
    initialize: function () {
      this._super('initialize', arguments)
      this.options.showCloseButton = false
      this.options.className = 'warning'
    },
    showWarnings: function (warnings) {
      this.model.set({
        currentPage: new Ts.WizardViews.WarningConfirmation({wizard: this, warnings: warnings})
      })
    },
    confirm: function () {
      if (this.options.onConfirm) this.options.onConfirm()
      this.close()
    },
    closeOnBlur: function () { }
  })
  
  Ts.WizardViews.WarningConfirmation = Ts.WizardViews.BasePage.extend({
		templateId: 'wizard:warning_confirmation_template',
    className: 'padded',
    render: function () {
      $(this.el).html(this.template({warnings: this.options.warnings}))
			return this
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
    templateId: 'wizard:place_form_template',
    initialize: function () {
      this._super('initialize', arguments)
      this.placeTypes = $('#json\\:place_types').parseJSON() || {}
    },
    renderTemplate: function () {
      this._super('renderTemplate', arguments)
      this.$("[name=type]").combobox()
    }
  })
  
  
  /*** Role Wizard Views ***/
  
  Ts.WizardViews.RoleWizard = Ts.WizardViews.Wizard.extend({
    templateId: 'wizard:role_wizard_template',
    events: _.extend({}, Ts.WizardViews.Wizard.prototype.events, {
			'click ul.menu > li:not(.disabled)' : function (e) { this.selectMenuItem(e.currentTarget)},
      'click ul.menu > li:not(.disabled) .delete' : function (e) {
        e.stopPropagation()
        this.deleteModel($(e.target).parents('li:first').data('model'))
      },
      'click [name=ok]:not(.disabled)': 'saveRole'
		}),
    initialize: function () {
      this._super('initialize', arguments)
      this.options.showBackButton = false
      this.options.className = 'role_wizard'
      this.pages = {}
      var role = this.model.get('role').clone()
      role.set({
        person: this.model.get('role').get('person').clone(),
        residential_contact: this.model.get('role').get('residential_contact') && this.model.get('role').get('residential_contact').clone(),
        mailing_contact: this.model.get('role').get('mailing_contact') && this.model.get('role').get('mailing_contact').clone()
      })
      role.get('person').valid(this.model.get('role').get('person').valid())
      role.get('residential_contact') && role.get('residential_contact').valid(this.model.get('role').get('residential_contact').valid())
      role.get('mailing_contact') && role.get('mailing_contact').valid(this.model.get('role').get('mailing_contact').valid())
      this.model.set({role: role})
      this.model.get('role').on('change', this.roleChanged, this)
      this.showPersonPage()
      this.roleChanged()
      window.r = this.model
    },
    render: function () {
      this._super('render', arguments)
      this.selectMenuItem(this.$('li').first())
      this.updateUI()
      return this
    },
    roleChanged: function () {
      this.updateUI()
      var role = this.model.get('role')
      role.off('change:person', this.personChanged, this).on('change:person', this.personChanged, this)
      role.get('person').off('validityChange', this.updateUI).on('validityChange', this.updateUI, this)
      if (role.get('residential_contact')) {
        role.get('residential_contact').off('validityChange', this.updateUI).on('validityChange', this.updateUI, this)
      }
      if (role.get('mailing_contact')) {
        role.get('mailing_contact').off('validityChange', this.updateUI).on('validityChange', this.updateUI, this)
      }
      if(role.get('residential_contact') && role.get('residential_contact').get('id') &&
         role.get('mailing_contact') && role.get('mailing_contact').get('id') &&
         role.get('residential_contact').get('id') == role.get('mailing_contact').get('id')
      ) {
        role.set('mailing_contact', role.get('residential_contact'))
      }
    },
    updateUI: function () {
      var role = this.model.get('role')
      var lastValid = true
      this.$('ul.menu > li').each( function () {
        var modelName = $(this).data('model')
        var model = role.get(modelName)
        
        if(modelName != 'person') {
          role.get('person').valid() ? $(this).removeClass('disabled') : $(this).addClass('disabled')
        }
        // if (lastValid) {
        //   $(this).removeClass('disabled')
        //   lastValid = (model) ? model.valid() : false
        // } else {
        //   $(this).addClass('disabled')
        // }
        if (model && !model.isEmpty()) {
          $('.delete', this).css('display', '')
        } else {
          $('.delete', this).css('display', 'none')
        }
      })
      if (role.valid()) {
        this.$('[name=ok]').removeClass('disabled')
      } else {
        this.$('[name=ok]').addClass('disabled')
      }
    },
    personChanged: function () {
      var target = this.$('ul.menu > li[data-model=person]')
      var self = this
      target.nextAll().each( function () {
        self.model.get('role').set($(this).data('model'), null)
      })
      this.updateUI()
      this.$('.role_wizard').animate({scrollTop: 0}, 150)
    },
    deleteModel: function (key) {
      var target = this.$('ul.menu > li[data-model='+key+']')
      var self = this
      this.selectMenuItem(target.is(':first-child') ? target : target.prev())
      target.add(target.nextAll()).each( function () {
        self.model.get('role').set($(this).data('model'), null)
      })
      this.updateUI()
    },
    selectMenuItem: function (el) {
      this.$('ul.menu li').removeClass('selected')
      this.$(el).addClass('selected')
      this[$(el).data('action')]()
    },
    showPersonPage: function () {
      this.pages['person'] = new Ts.WizardViews.PersonPage({wizard: this})
      this.model.set({currentPage: this.pages['person']})
    },
    showResidentialContactPage: function () {
      this.pages['residential_contact'] = new Ts.WizardViews.ContactPage({wizard: this, contact_type: 'residential'})
      this.model.set({currentPage: this.pages['residential_contact']})
    },
    showMailingContactPage: function () {
      this.pages['mailing_contact'] = new Ts.WizardViews.ContactPage({wizard: this, contact_type: 'mailing'})
      this.model.set({currentPage: this.pages['mailing_contact']})
    },
    saveRole: function () {
      setTimeout(_.bind(function () {
        _.each(['residential_contact', 'mailing_contact'], function (contact_type) {
          if (this.model.get('role').get(contact_type) && this.model.get('role').get(contact_type).isEmpty()) {
            this.model.get('role').set(contact_type, null, {silent: true})
          }
        }, this)
        this.close()
        this.options.onComplete(this.model.get('role'))    
      }, this), 100)
    }
	})
  
  Ts.WizardViews.PersonPage = Ts.WizardViews.BasePage.extend({
    initialize: function () {
      this._super('initialize', arguments)
      this.indicator = this.options.wizard.indicator
      this.wizard.model.get('role').on('change:person', this.renderForm, this)
      this.people = new Ts.People
      this.formPane = $('<div style="width: 50%" class="pane padded" />')
      this.resultsPane = $('<div style="width: 50%" class="pane padded" />')
      this.findPeople()
    },
    render: function () {
      this.$el.empty()
      this.$el.append(this.formPane, this.resultsPane)
      this.renderForm()
      this.renderResults()
      return this
    },
    renderForm: function () {
      if (!this.wizard.model.get('role').get('person')) {
        this.wizard.model.get('role').set('person', new Ts.Person)
      }
      var personForm = new Ts.WizardViews.PersonForm({model: this.wizard.model.get('role').get('person'), wizard: this.wizard})
      personForm.$el.on('change', _.bind(this.findPeople, this))
      this.formPane.html(personForm.render().el)
    },
    renderResults: function () {
      var personResults = new Ts.WizardViews.PersonResults({collection: this.people, wizard: this.wizard})
      this.resultsPane.html(personResults.render().el)
    },
    findPeople: function () {
      var formValues = {}
      _(this.$('form').serializeJSON()).each( function (v,k) {
        if (v) formValues[k] = v
      })
      if (formValues.given_name || formValues.middle_name || formValues.surname || formValues.date_of_birth || formValues.date_of_death) {
        this.people.fetch({
          url: '/person/search',
          data: formValues,
          success: _.bind(function (collection) {
            this.renderResults()
          }, this)
        })
      }
    }
	})
  
  Ts.WizardViews.PersonForm = Ts.WizardViews.GenericForm.extend({
		templateId: 'wizard:person_form_template',
    initialize: function () {
      this._super('initialize', arguments)
      this.model.off('change', this.checkValidity).on('change', this.checkValidity, this)
    },
    checkValidity: function () {
      if (this.model.hasRequired()) {
        this.model.serverValidate({
					valid: _.bind( function () { this.model.valid(true) }, this),
					invalid: _.bind( function () { this.model.valid(false) }, this)
				})
      }
    }
	})
    
	Ts.WizardViews.PersonResults = Ts.WizardViews.BasePage.extend({
		template: _.template($('#wizard\\:person_results_template').html()),
    render: function () {
      $(this.el).html(this.template()).append(this.indicator)
      if(this.collection.length > 0) {
        this.collection.each(function (person) {
          var personBlock = new Ts.WizardViews.PersonBlock({model: person})
          personBlock.$el.on('click', _.bind( function () {
            person.valid(true)
            this.wizard.model.get('role').set('person', person)
          }, this))
          this.$('.blocks').append(personBlock.render().el)
        }, this)
      } else {
        this.$('.blocks').append('<small class="padded">No matches found.</small>')
      }
			return this
    }
	})
  
  Ts.WizardViews.PersonBlock = Ts.View.extend({
    className: 'row_block clickable',
    templateId: 'wizard:person_block_template',
    render: function () {
      $(this.el).html(this.template({person: this.model.toJSON()}))
			return this
    }
  })
  
  Ts.WizardViews.ContactPage = Ts.WizardViews.BasePage.extend({
    initialize: function () {
      this._super('initialize', arguments)
      this.indicator = this.options.wizard.indicator
      this.wizard.model.get('role').on('change:'+this.options.contact_type+'_contact', function () {
        if (this.$el.inDOM()) this.renderForm()
      }, this)
      this.bindToSync(this.contacts = new Ts.Contacts)
      this.formPane = $('<div style="width: 50%" class="pane padded" />')
      this.resultsPane = $('<div style="width: 50%" class="pane padded" />')
      this.contacts.fetch({
        success: _.bind(function () {
          this.renderResults()
        }, this),
        data: {person_id: this.wizard.model.get('role').get('person').get('id')}
      })
    },
		render: function () {
      this.$el.children().detach()
      this.$el.append(this.formPane, this.resultsPane)
      this.renderForm()
      this.renderResults()
      return this
    },
    renderForm: function () {
      if (!this.wizard.model.get('role').get(this.options.contact_type+'_contact')) {
        this.wizard.model.get('role').set(this.options.contact_type+'_contact', new Ts.Contact)
      }
      var contactForm = new Ts.WizardViews.ContactForm({
        model: this.wizard.model.get('role').get(this.options.contact_type+'_contact'),
        wizard: this.wizard
      })
      this.formPane.html(contactForm.render().el)
    },
    renderResults: function () {
      var contactResults = new Ts.WizardViews.ContactResults({
        collection: this.contacts,
        wizard: this.wizard,
        contact_type: this.options.contact_type
      })
      this.resultsPane.html(contactResults.render().el)
    }
	})
  
  Ts.WizardViews.ContactForm = Ts.WizardViews.GenericForm.extend({
		templateId: 'wizard:create_contact_form_template',
    initialize: function () {
      this._super('initialize', arguments)
      this.model.on('change', this.checkValidity, this)
    },
    renderTemplate: function () {
      this._super('renderTemplate', arguments)
      this.$("[name=state]").combobox()
    },
    checkValidity: function () {
      if (this.model.hasRequired()) {
        this.model.serverValidate({
					valid: _.bind( function () { this.model.valid(true) }, this),
					invalid: _.bind( function () { this.model.valid(false) /*this.renderPage()*/ }, this)
				})
      }
    }
	})
  
  Ts.WizardViews.ContactResults = Ts.WizardViews.BasePage.extend({
		templateId: 'wizard:contact_results_template',
    render: function () {
      $(this.el).html(this.template()).append(this.indicator)
      if(this.collection.length > 0) {
        this.collection.each(function (contact) {
          var contactBlock = new Ts.WizardViews.ContactBlock({model: contact})
          contactBlock.$el.on('click', _.bind( function () {
            contact.valid(true)
            this.wizard.model.get('role').set(this.options.contact_type+'_contact', contact)
          }, this))
          this.$('.blocks').append(contactBlock.render().el)
        }, this)
      } else {
        this.$('.blocks').append('<small class="padded">No matches found.</small>')
      }
			return this
    }
	})
  
  Ts.WizardViews.ContactBlock = Ts.View.extend({
    className: 'row_block clickable',
    templateId: 'wizard:contact_block_template',
    render: function () {
      $(this.el).html(this.template({contact: this.model.toJSON()}))
			return this
    }
  })
  
  Ts.WizardViews.FindPersonForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#wizard\\:person_form_template').html())
	})
  
  Ts.WizardViews.CreatePersonForm = Ts.WizardViews.GenericForm.extend({
		template: _.template($('#wizard\\:person_form_template').html())
	})
  
	Ts.WizardViews.RoleReview = Ts.WizardViews.BasePage.extend({
		template: _.template($('#wizard\\:role_review_template').html()),
    render: function () {
      $(this.el).html(this.template(this.model.recursiveToJSON()))
			return this
    }
	})
	
})
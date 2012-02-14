// JavaScript Document
$( function () {
  Ts.RoleWizardViews = {}
  Ts.RoleWizardViews.BasePage = Backbone.View.extend({
    events: {
      'click input[type=submit],input[type=button]': 'doAction'
    },
		initialize: function (opts) {
      this.wizard = opts.wizard
      _.bindAll(this, 'doAction')
		},
    doAction: function (e) {
			var action = $(e.target).attr('action')
      this.wizard[action](this.model)
      return false
		}
  })
  
  Ts.RoleWizardViews.GenericForm = Ts.RoleWizardViews.BasePage.extend({
    tagName: 'form',
		className: 'rowed',
    events: _.extend({}, Ts.RoleWizardViews.BasePage.prototype.events, {
      'change' : 'formChanged'
    }),
		initialize: function (opts) {
      Ts.RoleWizardViews.BasePage.prototype.initialize.apply(this, arguments);
      this.model.bind('change', this.modelChanged, this)
			_.bindAll(this, 'formChanged');
		},
		render: function () {
			$(this.el).html(this.template({data: this.model.toJSON()}));
      this.populateForm(this.model.toJSON())
			return this
		},
    formChanged: function (e) {
      var target = $(e.target)
      var name = target.attr("name")
      var hash = {}
      if(target.is('[type=checkbox')) {
        hash[name] = target.is(':checked') ? true : false
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
          value = $.datepicker.formatDate('dd/mm/yy', new Date(value))
        }
        field.fieldValue(value)
      }, this)
    }
  })
  
	Ts.RoleWizardViews.FindPersonForm = Ts.RoleWizardViews.GenericForm.extend({
		template: _.template($('#role_wizard\\:find_person_form_template').html()),
		initialize: function (opts) {
      Ts.RoleWizardViews.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
  
  Ts.RoleWizardViews.CreatePersonForm = Ts.RoleWizardViews.GenericForm.extend({
		template: _.template($('#role_wizard\\:create_person_form_template').html()),
		initialize: function (opts) {
      Ts.RoleWizardViews.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
	
	Ts.RoleWizardViews.ContactForm = Ts.RoleWizardViews.GenericForm.extend({
		template: _.template($('#role_wizard\\:create_contact_form_template').html()),
		initialize: function (opts) {
      Ts.RoleWizardViews.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
  
	Ts.RoleWizardViews.PersonResults = Ts.RoleWizardViews.BasePage.extend({
		template: _.template($('#role_wizard\\:person_results_template').html()),
		initialize: function () {
      Ts.RoleWizardViews.BasePage.prototype.initialize.apply(this, arguments)
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
  
  Ts.RoleWizardViews.ContactResults = Ts.RoleWizardViews.BasePage.extend({
		template: _.template($('#role_wizard\\:contact_results_template').html()),
		initialize: function () {
      Ts.RoleWizardViews.BasePage.prototype.initialize.apply(this, arguments)
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
  
  Ts.RoleWizardViews.PersonBlock = Backbone.View.extend({
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
      var action = $(e.target).attr('action')
      this.wizard.savePerson(this.model)
      return false
    }
  })
  
  Ts.RoleWizardViews.ContactBlock = Backbone.View.extend({
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
      var action = $(e.target).attr('action')
      this.wizard.saveContact(this.model)
      return false
    }
  })
  
	Ts.RoleWizardViews.RoleReview = Ts.RoleWizardViews.BasePage.extend({
		template: _.template($('#role_wizard\\:role_review_template').html()),
		initialize: function (opts) {
      Ts.RoleWizardViews.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template(this.model.recursiveToJSON()))
			return this
    }
	})
	
	Ts.RoleWizardViews.WizardView = Backbone.View.extend({
		className: 'overlay_background',
		template: _.template($('#role_wizard\\:wizard_template').html()),
		events: {
			'click .close' : 'close',
      'click .back' : 'goBack',
			'click' : 'closeOnBlur'
		},
		initialize: function (opts) {
			_.bindAll(this, 'close', 'goBack', 'closeOnBlur')
			this.model.bind('change:currentPage', this.renderPage, this)
      this.model.bind('change:isLoading', this.renderLoader, this)
      this.onComplete = opts.onComplete
      this.showFindPersonForm()
		},
		render: function () {
			$(this.el).css({display: ''})
			$(this.el).children().detach()
      $(this.el).append(this.template({data: this.model.toJSON()}))
			this.renderPage()
      this.renderLoader()
			return this
		},
    renderPage: function () {
      this.$('.body').children(':not(.loading)').detach()
      model = this.model.get('currentPage').model
      if(model && model.errors && Object.keys(model.errors).length > 0) {
        this.showErrors(model.errors)
      } else {
        this.hideErrors()
      }
      this.$('.body').append(this.model.get('currentPage').render().el)
    },
    renderLoader: function () {
      if(this.model.get('isLoading')) {
        this.$('.loading').css('display', '')
      } else {
        this.$('.loading').css('display', 'none')
      }
    },
    showFindPersonForm: function () {
      this.findPersonModel = new Ts.Person
      var findPersonForm = new Ts.RoleWizardViews.FindPersonForm({model: this.findPersonModel, wizard: this})
      this.model.set({currentPage: findPersonForm})
    },
    showCreatePersonForm: function () {
      var createPersonForm = new Ts.RoleWizardViews.CreatePersonForm({model: this.findPersonModel, wizard: this}, 'savePerson')
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
        // if(contact.serverValidate()) {
				// 	this.showRoleReview()
				// } else {
				// 	this.showCreateContactForm()
				// }
      }
    },
    saveRole: function () {
      this.close()
      if(this.onComplete) {
        this.onComplete(this.model.get("role"))
      }
    },
    goBack: function () {
      var backDestination = this.model.get('pageHistory').pop()
      if(backDestination) {
        this.model.set({currentPage: backDestination}, {silent: true})
        this.renderPage()
      }
    },
    showErrors: function (errors) {
			var errorContainer = this.$('.form_errors').empty()
			if(errors.constructor == Object) {
				if(Object.keys(errors).length > 0) {
	        _.each(errors, function (errors, field) {
						var errors = (errors instanceof Array) ? errors : [errors]
						_.each(errors, function (error) {
							errorContainer.append('<li>'+field.split('_').join(' ').toTitleCase()+' '+error+'</li>')
						})
	        }, this)
	        errorContainer.css({display: ''})
	      }
			} else {
				var errors = (errors instanceof Array) ? errors : [errors]
				if(errors.length > 0) {
	        _.each(errors, function (error) {
	          errorContainer.append('<li>'+error+'</li>')
	        }, this)
	        errorContainer.css({display: ''})
	      }
			}
      
      
    },
    hideErrors: function () {
      this.$('.form_errors').empty().css({display: 'none'})
    },
		close: function () {
			this.remove()
		},
    closeOnBlur: function  (e) {
			if(e.target == this.el) {
				this.close()
      }
		},
    ajaxErrorHandler: function (binding, context) {
			context = (context) ? context : 'backbone'
			if(context == 'jQuery') {
				return _.bind( function (jqXHR, textStatus, errorThrown) {
	        this.showErrors($.parseJSON(jqXHR.responseText).exception)
	        this.model.set({isLoading: false})
	      }, binding)
			} else if (context == 'backbone') {
				return _.bind( function (collection, jqXHR) {
	        this.showErrors($.parseJSON(jqXHR.responseText).exception)
	        this.model.set({isLoading: false})
	      }, binding)
			}
    }
	})
})

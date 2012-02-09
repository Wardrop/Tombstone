// JavaScript Document
$( function () {
  Ts.BasePage = Backbone.View.extend({
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
  
  Ts.GenericForm = Ts.BasePage.extend({
    tagName: 'form',
		className: 'rowed',
    events: _.extend({}, Ts.BasePage.prototype.events, {
      'change' : 'formChanged'
    }),
		initialize: function (opts) {
      Ts.BasePage.prototype.initialize.apply(this, arguments);
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
        field.fieldValue(value)
      }, this)
    }
  })
  
	Ts.FindPersonForm = Ts.GenericForm.extend({
		template: _.template($('#find_person_form_template').html()),
		initialize: function (opts) {
      Ts.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
  
  Ts.CreatePersonForm = Ts.GenericForm.extend({
		template: _.template($('#create_person_form_template').html()),
		initialize: function (opts) {
      Ts.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
	
	Ts.ContactForm = Ts.GenericForm.extend({
		template: _.template($('#contact_form_template').html()),
		initialize: function (opts) {
      Ts.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
	
  Ts.GenericResults = Ts.BasePage.extend({
    blockView: null,
		initialize: function (opts) {
      Ts.BasePage.prototype.initialize.apply(this, arguments);
		},
    render: function () {
      $(this.el).html(this.template())
      this.collection.each(function (person) {
        this.$('.blocks').append((new this.blockView({model: person, wizard: this.wizard})).render().el)
      }, this)
			return this
    }
	})
  
	Ts.PersonResults = Ts.BasePage.extend({
		template: _.template($('#person_results_template').html()),
		initialize: function () {
      Ts.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template())
      this.collection.each(function (person) {
        this.$('.blocks').append((new Ts.PersonBlock({model: person, wizard: this.wizard})).render().el)
      }, this)
			return this
    }
	})
  
  Ts.ContactResults = Ts.BasePage.extend({
		template: _.template($('#contact_results_template').html()),
		initialize: function () {
      Ts.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template())
      this.collection.each(function (contact) {
        this.$('.blocks').append((new Ts.ContactBlock({model: contact, wizard: this.wizard})).render().el)
      }, this)
			return this
    }
	})
  
  Ts.PersonBlock = Backbone.View.extend({
    className: 'row_block clickable',
    template: _.template($('#person_block_template').html()),
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
  
  Ts.ContactBlock = Backbone.View.extend({
    className: 'row_block clickable',
    template: _.template($('#contact_block_template').html()),
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
	
	Ts.RoleReview = Ts.BasePage.extend({
		template: _.template($('#role_review_template').html()),
		initialize: function (opts) {
      Ts.BasePage.prototype.initialize.apply(this, arguments)
		},
    render: function () {
      $(this.el).html(this.template())
      this.$('.blocks').append((new Ts.PersonBlock({model: this.model.get('person'), wizard: this.wizard})).render().el)
      this.$('.blocks').append((new Ts.ContactBlock({model: this.model.get('residential_contact'), wizard: this.wizard})).render().el)
			return this
    }
	})
	
	Ts.WizardView = Backbone.View.extend({
		className: 'overlay_background',
		template: _.template($('#wizard_template').html()),
		events: {
			'click .close' : 'hide',
      'click .back' : 'goBack',
			'click' : 'hideOnBlur'
		},
		initialize: function () {
			_.bindAll(this, 'hide', 'goBack', 'hideOnBlur')
			this.model.bind('change:currentPage', this.renderPage, this)
      this.model.bind('change:isLoading', this.renderLoader, this)
      this.role = new Ts.Role()
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
      this.$('.body').children().detach()
      model = this.model.get('currentPage').model
      if(model && model.errors.length > 0) {
        errorContainer = this.$('.validation_errors').empty().css({display: ''})
        _.each(model.errors, function (error) {
          errorContainer.append('<li>'+error+'</li>')
        }, this)
      } else {
        this.$('.validation_errors').empty().css({display: 'none'})
      }
      this.$('.body').append(this.model.get('currentPage').render().el)
    },
    renderLoader: function () {
      if(this.model.get('isLoading')) {
        this.$('.body').css('display', 'none')
        this.$('.loading').css('display', '')
      } else {
        this.$('.body').css('display', '')
        this.$('.loading').css('display', 'none')
      }
    },
    showFindPersonForm: function () {
      var findPersonForm = new Ts.FindPersonForm({model: this.role.get('person'), wizard: this})
      this.model.set({currentPage: findPersonForm})
    },
    showCreatePersonForm: function () {
      var createPersonForm = new Ts.CreatePersonForm({model: this.role.get('person'), wizard: this}, 'savePerson')
      this.model.set({currentPage: createPersonForm})
    },
    showCreateContactForm: function () {
      var contactForm = new Ts.ContactForm({model: this.role.get('residential_contact'), wizard: this})
      this.model.set({currentPage: contactForm})
    },
    findPeople: function (person) {
      var matches = new Ts.People()
      var self = this
      this.model.set({isLoading: true})
      matches.fetch({
        success: function (results) {
          var resultsView = new Ts.PersonResults({collection: results, wizard: self})
          self.model.set({currentPage: resultsView, isLoading: false})
        },
        error: function () {
          self.model.set({isLoading: false})
        },
        data: person.toJSON()
      })
    },
    findContacts: function (person) {
      var matches = new Ts.Contacts()
      var self = this
      this.model.set({isLoading: true})
      matches.fetch({
        success: function (results) {
          var resultsView = new Ts.ContactResults({collection: results, wizard: self})
          self.model.set({currentPage: resultsView, isLoading: false})
        },
        error: function () {
          self.model.set({isLoading: false})
        }
      },{
        data: person.toJSON()
      })
    },
    savePerson: function (person) {
      if(person.get('id')) {
        this.role.set({person: person})
        this.findContacts(person)
      } else {
        hasErrors = person.validate()
        if(hasErrors) {
          this.showCreatePersonForm()
        } else {
          this.showCreateContactForm()
        }
      }
    },
    saveAddress: function (address) {
      this.role.set({residential_address: address})
      var roleReview = new Ts.RoleReview({model: this.role, wizard: this})
      this.model.set({currentPage: roleReview})
    },
    goBack: function () {
      this.model.set({currentPage: this.model.get('pageHistory').pop()}, {silent: true})
      this.renderPage()
    },
		hideOnBlur: function  (e) {
			if(e.target == this.el) {
				$(this.el).css({display: 'none'})
			}
		},
		hide: function () {
			$(this.el).css({display: 'none'})
		}
	})
})

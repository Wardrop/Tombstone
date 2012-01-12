// JavaScript Document
$( function () {
  Ts.GenericForm = Backbone.View.extend({
    tagName: 'form',
		className: 'rowed',
		events: {
      'change': 'formChanged',
      'click input[type=submit],input[type=button]': 'doAction'
		},
		initialize: function (opts) {
      this.wizard = opts.wizard
      this.model.bind('change', this.modelChanged, this)
			_.bindAll(this, 'doAction', 'formChanged');
		},
		render: function () {
			$(this.el).html(this.template({data: this.model.toJSON()}));
      this.populateForm(this.model.toJSON())
			return this;
		},
		doAction: function (e) {
			var action = $(e.target).attr('action')
      this.wizard[action](this.model)
      return false
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
  
	Ts.PersonForm = Ts.GenericForm.extend({
		template: _.template($('#person_form_template').html()),
		initialize: function (opts) {
      Ts.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
	
	Ts.AddressForm = Ts.GenericForm.extend({
		template: _.template($('#address_form_template').html()),
		initialize: function (opts) {
      Ts.GenericForm.prototype.initialize.apply(this, arguments);
		}
	})
	
  Ts.GenericResults = Backbone.View.extend({
		tagName: 'div',
    events: {
      'click input[type=submit]': 'doAction'
    },
    blockView: null,
		initialize: function (opts) {
      this.wizard = opts.wizard
      _.bindAll(this, 'doAction')
		},
    render: function () {
      $(this.el).html(this.template())
      console.log(this.collection)
      this.collection.each(function (person) {
        this.$('.results').append((new this.blockView({model: person, wizard: this.wizard})).render().el)
      }, this)
			return this
    },
    doAction: function (e) {
			var action = $(e.target).attr('action')
      this.wizard[action]()
      return false
		}
	})
  
	Ts.PersonResults = Ts.GenericResults.extend({
		template: _.template($('#person_results_template').html()),
		initialize: function (opts) {
      Ts.GenericResults.prototype.initialize.apply(this, arguments)
      this.blockView = Ts.PersonResultBlock
		}
	})
  
  Ts.PersonResultBlock = Backbone.View.extend({
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
      this.wizard.findAddresses(this.model)
      return false
    }
  })
	
	Ts.AddressResults = Ts.GenericResults.extend({
		template: _.template($('#address_results_template').html()),
		initialize: function (opts) {
      Ts.GenericResults.prototype.initialize.apply(this, arguments)
      this.blockView = Ts.AddressResultBlock
		}
	})
  
  Ts.AddressResultBlock = Backbone.View.extend({
    className: 'row_block clickable',
    template: _.template($('#address_block_template').html()),
    events: {
      'click' : 'doAction'
    },
    initialize: function (opts) {
      this.wizard = opts.wizard
      _.bindAll(this, 'doAction')
    },
    render: function () {
      $(this.el).html(this.template({address: this.model.toJSON()}))
			return this
    },
    doAction: function (e) {
      var action = $(e.target).attr('action')
      this.wizard[action]()
      return false
    }
  })
	
	Ts.RoleReview = Backbone.View.extend({
		
	})
	
	Ts.WizardView = Backbone.View.extend({
		tagName: 'div',
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
      this.personForm = new Ts.PersonForm({model: new Ts.Person({}), wizard: this})
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
      this.model.set({currentPage: this.personForm})
    },
    showCreatePersonForm: function () {
      this.model.set({currentPage: this.personForm})
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
    findAddresses: function (address) {
      var matches = new Ts.Addresses()
      var self = this
      this.model.set({isLoading: true})
      matches.fetch({
        success: function (results) {
          var resultsView = new Ts.AddressResults({collection: results, wizard: self})
          self.model.set({currentPage: resultsView, isLoading: false})
        },
        error: function () {
          self.model.set({isLoading: false})
        }
      },{
        data: address.toJSON()
      })
    },
    savePerson: function () {
      
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

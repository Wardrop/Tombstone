// JavaScript Document

$( function () {
	Ts.PersonForm = Backbone.View.extend({
		tagName: 'form',
		className: 'rowed',
		template: _.template($('#person_form_template').html()),
		events: {
			'click input[type=button][action]': 'action'
		},
		initialize: function (opts) {
      this.overlay = opts.overlay
			_.bindAll(this, 'action');
		},
		render: function () {
			$(this.el).html(this.template({data: this.model.toJSON()}));
			return this;
		},
		action: function (e) {
			var action = $(e.target).attr('action')
			if(action == 'find') {
				var matches = new Ts.People()
        var self = this
        this.overlay.set({isLoading: true})
        matches.fetch({
          success: function (results) {
            var resultsView = new Ts.PersonResults({collection: results, overlay: self.overlay, data: $(self.el).serializeJSON(), personForm: self})
            self.overlay.set({body: resultsView.render().el, isLoading: false})
          },
          error: function () {
            self.overlay.set({isLoading: false})
          }
        })
			} else if (action == 'create') {
				
			}
		}
	})
	
	Ts.AddressForm = Backbone.View.extend({
		
	})
	
	Ts.PersonResults = Backbone.View.extend({
		tagName: 'div',
		template: _.template($('#person_results_template').html()),
    events: {
      'click input[type=button][action]': 'action'
    },
		initialize: function (opts) {
      this.overlay = opts.overlay
      _.bindAll(this, 'action')
		},
    render: function () {
      $(this.el).append(this.template({collection: this.collection.toJSON()}))
			return this
    },
    action: function (e) {
			var action = $(e.target).attr('action')
			if(action == 'create_new_person') {
        var personForm = this.options.personForm
        console.log(personForm)
        if(!personForm) {
          personForm = new Ts.PersonForm({model: new Ts.Person()})
          personForm.render()
        }
        this.overlay.set({body: personForm.el})
			}
		}
	})
	
	Ts.AddressResults = Backbone.View.extend({
		
	})
	
	Ts.RoleReview = Backbone.View.extend({
		
	})
	
	Ts.WizardView = Backbone.View.extend({
		tagName: 'div',
		className: 'overlay_background',
		template: _.template($('#wizard_template').html()),
		events: {
			'click .close': 'hide',
			'click': 'hideOnBlur'
		},
		initialize: function () {
			_.bindAll(this, 'hide')
			this.model.bind('change:body', this.renderBody, this)
      this.model.bind('change:isLoading', this.render, this)
		},
		render: function () {
			$(this.el).css({display: ''})
			$(this.el).children().detach()
      $(this.el).append(this.template({data: this.model.toJSON()}))
			this.renderBody()
      this.renderLoader()
			return this
		},
    renderBody: function () {
      this.$('.body').children().detach()
      this.$('.body').append(this.model.get('body'))
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

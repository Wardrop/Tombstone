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
      this.model.bind('change:isLoading', this.renderLoader, this)
      this.onComplete = this.options.onComplete || new Function
      $('body').prepend(this.$el.css({display: 'none'}))
		},
		render: function () {
			this.$el.css({display: ''})
			this.$el.children().detach()
      this.$el.append(this.template({data: this.model.toJSON()}))
      this.$('.body').prepend(this.indicator)
      this.$('.body').prepend(this.errorBlock)
			this.renderPage()
      this.renderLoader()
			return this
		},
    renderPage: function () {
      this.hideErrors()
      this.$('.body > .page').children().detach()
      model = this.model.get('currentPage').model
      if(model && model.errors && Object.keys(model.errors).length > 0) {
        this.showErrors(model.errors)
      } else {
        this.hideErrors()
      }
      this.$('.body > .page').html(this.model.get('currentPage').render().el)
    },
    renderLoader: function () {
      if(this.model.get('isLoading')) {
        this.$('.indicator').addClass('loading').css('display', '')
      } else {
        this.$('.indicator').removeClass('loading').css('display', 'none')
      }
    },
    // showErrors: function (errors) {
    //      var errorContainer = this.$('.error_block').empty()
    //      if(errors.constructor == Object) {
    //        if(Object.keys(errors).length > 0) {
    //          _.each(errors, function (errors, field) {
    //            var errors = (errors instanceof Array) ? errors : [errors]
    //            _.each(errors, function (error) {
    //              errorContainer.append('<li>'+field.split('_').join(' ').titleize()+' '+error+'</li>')
    //            })
    //          }, this)
    //          errorContainer.css({display: ''})
    //        }
    //      } else {
    //        var errors = (errors instanceof Array) ? errors : [errors]
    //        if(errors.length > 0) {
    //          _.each(errors, function (error) {
    //            errorContainer.append('<li>'+error+'</li>')
    //          }, this)
    //          errorContainer.css({display: ''})
    //        }
    //      }
    //     },
    //     hideErrors: function () {
    //       this.$('.error_block').empty().css({display: 'none'})
    //     },
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
    },
    goBack: function () {
      var backDestination = this.model.get('pageHistory').pop()
      if(backDestination) {
        this.model.set({currentPage: backDestination}, {silent: true})
        this.renderPage()
      }
    }
  })
})
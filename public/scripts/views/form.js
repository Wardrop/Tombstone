$( function () {
  Ts.FormViews = {}
  Ts.FormViews.RoleBlock = Backbone.View.extend({
    className: 'row_block clickable',
    template: _.template($('#form\\:role_block_template').html()),
    events: {
      'click div.row_block' : 'changeRole',
      'click a.add' : 'addRole',
      'click .actions a.delete' : 'removeRole'
    },
    initialize: function (opts) {
      this.role_name = opts.role_name
      this.role_type = opts.role_type
      _.bindAll(this, 'render', 'addRole', 'changeRole', 'onCompleteCallback')
    },
    render: function () {
      $(this.el).html(this.template({model: (this.model) ? this.model.recursiveToJSON() : null}))
  		return this
    },
    addRole: function () {
      wizard = new Ts.RoleWizard({title: "Add "+this.role_name, role: new Ts.Role({type: this.role_type})})
			wizardView = new Ts.RoleWizardViews.WizardView({
        model: wizard,
        onComplete: this.onCompleteCallback
      })
      $('body').prepend(wizardView.render().el)
    },
    changeRole: function () {
      clonedModel = new Ts.Role({
        type: this.role_type,
        person: this.model.get("person").clone(),
        residential_contact: this.model.get("residential_contact").clone(),
        mailing_contact: this.model.get("mailing_contact").clone()
      })
      clonedModel.get("person").set({id: null})
      wizard = new Ts.RoleWizard({title: "Change "+this.role_name, role: clonedModel})
			wizardView = new Ts.RoleWizardViews.WizardView({
        model: wizard,
        onComplete: this.render
      })
      $('body').prepend(wizardView.render().el)
    },
    removeRole: function () {
      if(confirm('Are you sure you want to remove this object?')) {
        this.model = null
        this.render()
      }
      return false
    },
    onCompleteCallback: function (role) {
      this.model = role
      this.render()
    }
  })
  
  Ts.FormViews.Multibutton = Backbone.View.extend({
    tagName: 'span',
    className: 'multibutton',
    template: _.template($('#form\\:multibutton_template').html()),
    events: {
      'click span.dropdown_button' : 'toggleList',
      'click ul input' : 'onSelectListItem'
    },
    initialize: function (opts) {
      this.opts = opts
      _.bindAll(this, 'hideList', 'showList', 'keydownHideEvent')
    },
    render: function () {
      $(this.el).html(this.template({name: this.opts.name, options: this.opts.options}))
      var list = this.$('ul')
      list.css('display', 'none')
      this.selectButton(list.find('input:first'))
      this.hideList()
  		return this
    },
    toggleList: function () {
      var hidden = this.$('ul').css('display') == 'none'
			hidden ? this.showList() : this.hideList()
    },
    showList: function () {
      var list = this.$('ul')
      list.css('min-width', $(this.el).outerWidth());
      list.css('display', '')
      var viewport_bottom = $(window).scrollTop() + $(window).height();
			var list_bottom = list.offset().top + list.outerHeight();
			if((list_bottom + 10) > viewport_bottom) {
			  $(this.el).addClass('top');
			} else {
			  $(this.el).addClass('bottom');
			}
			// If we don't wrap this binding in a delay, it'll fire directly after this event which is not what we want.
			_.delay(function (self) { $(document).click(self.hideList); }, 1, this);
			$(window).blur(this.hideList)
			$(document).keydown(this.keydownHideEvent)
    },
    hideList: function () {
      this.$('ul').css('display', 'none')
			$(this.el).removeClass('top bottom')
      $(document).unbind('click', this.hideList)
			$(window).unbind('blur', this.hideList)
			$(document).unbind('keydown', this.keydownHideEvent)
    },
    selectButton: function(selected) {
      $(this.el).children('input').remove()
			$(this.el).prepend($(selected).clone(true))
		  this.$('ul > li').removeClass('selected').find(selected).parent().addClass('selected')
		},
    onSelectListItem: function (e) {
      this.selectButton(e.currentTarget)
    },
    keydownHideEvent: function (e) {
      if (e.keyCode == 27) this.hideList();
    }
  })
  
  Ts.FormViews.PlacesView = Backbone.View.extend({
    tagName: 'label',
    template: _.template($('#form\\:place_list_template').html()),
    events: {
      'change': 'selectPlace'
    },
    initialize: function (opts) {
      this.selected = opts.selected
      _.bindAll(this, 'selectPlace')
    },
    render: function () {
      $(this.el).html(this.template({type: this.collection.first().get('type'), places: this.collection.toJSON(), selected: this.selected}))
      return this
    },
    renderPlaces: function (places, selected) {
      var view = (new Ts.FormViews.PlacesView({collection: places, selected: selected}))
      $(this.el).parent().append(view.render().el)
    },
    selectPlace: function (e) {
      var target = $(e.target)
      var placeId = target.children(':selected').attr('value')
      if(placeId) {
        $(this.el).nextAll().remove()
        this.$('.loading').remove()
        if(target.data('placeType') == 'section') {
          this.nextAvailable(placeId)
        } else {
          this.loadPlaceList(placeId)
        }
      } else {
        $(this.el).nextAll().remove()
      }
    },
    loadPlaceList: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="loading" />')
      this.lastRequest = $.ajax('/place/children/'+parent_id, {
				type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          var places = new Ts.Places(data)
          if(places.length > 0) {
            var childPlacesView = new Ts.FormViews.PlacesView({collection: places})
            $(this.el).parent().append(childPlacesView.render().el)
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert('Some went wrong!')
        },
        complete: _.bind(function () {
          this.$('.loading').remove()
        }, this)
      })
    },
    nextAvailable: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      $(this.el).append('<div class="loading" />')
      this.lastRequest = $.ajax('/place/next_available/'+parent_id, {
        type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          _.each(data, function (place) {
            this.renderPlaces(new Ts.Places(place.siblings), place.id)
          }, this)
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert('Some went wrong!')
        },
        complete: _.bind(function () {
          this.$('.loading').remove()
        }, this)
      })
    }
  })
  
  // $('[name='+field+']').addClass('field_error')
  
  // Ts.FormViews.Multibutton = Backbone.View.extend({
  //   tagName: 'ul',
  //   className: 'validation_errors',
  //   initialize: function (errors) {
  //     this.errors = errors
  //     
  //     var errorsList = $('<ul class="validation_errors" />')
  //     _.each(response.form_errors, function (value, field) {
  //       $('[name='+field+']').addClass('field_error')
  //       if(value instanceof Array == false) value = [value]
  //       _.each(value, function (v) {
  //         errorsList.append('<li>'+Ts.toTitleCase(field.split('_').join(' '))+' '+v+'.</li>')
  //       })
  //     })
  //   },
  //   render: function () {
  //     
  //     if(value instanceof Array == false) value = [value]
  //     _.each( function (field, errors) {
  //       _.each(errors, function (error) {
  //         errorsList.append('<li>'+Ts.toTitleCase(field.split('_').join(' '))+' '+error+'.</li>')
  //       })
  //       $(this.el)
  //     })
  //     
  //   }
  // })
})
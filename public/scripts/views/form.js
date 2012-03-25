$( function () {
  Ts.FormViews.Section = Ts.View.extend({
    tagName: 'section',
    templateId: 'form:section_template',
    initialize: function () {
      this.body = []
      if (body = this.options.body) {
        this.body = (body.constructor == Array) ? body : [body]
      }
    },
    render: function () {
      this.$el.html(this.template(this.options))
      _.each(this.body, function (element) {
        this.$('div').append(element)
      }, this)
      return this
    }
  })
  Ts.FormViews.RoleBlock = Ts.View.extend({
    templateId: 'form:role_block_template',
    events: {
      'click div.row_block' : 'changeRole',
      'click a.add' : 'addRole',
      'click a.delete' : 'removeRole'
    },
    initialize: function () {
      this.group = this.options.group || {}
      this.role_type = this.options.role_type
			this.role_name = this.options.role_name || this.role_type.split('_').join(' ').titleize()
      _.bindAll(this, 'render', 'addRole', 'changeRole', 'onCompleteCallback')
    },
    render: function () {
      this.$el.empty()
      if (this.model) {
        this.$el.html(this.template({model: (this.model) ? this.model.recursiveToJSON() : null}))
      } else {
        values = {add: 'Add'}
        actions = {add: this.addRole}
        _.each(this.group, function (roleBlock) {
          if(roleBlock != this) {
            values['use_'+roleBlock.role_type] = 'Use '+roleBlock.role_name.demodulize().titleize()
            actions['use_'+roleBlock.role_type] = _.bind( function () {
              this.useRole(roleBlock)
            }, this)
          }
        }, this)
        var multibutton = new Ts.FormViews.Multibutton({
          name: this.role_type + '_action',
          values: values,
          actions: actions
        })
        this.$el.append(multibutton.render().el)
      }
  		return this
    },
    getJSON: function () {
      return (this.model && this.model.recursiveToJSON()) || (this.use && {type: this.role_type, use: this.use}) || null
    },
    addRole: function () {
      this.use = null
      wizard = new Ts.Wizard({title: "Add "+this.role_name, role: new Ts.Role({type: this.role_type})})
			wizardView = new Ts.RoleWizardViews.WizardView({
        model: wizard,
        onComplete: this.onCompleteCallback
      })
      $('body').prepend(wizardView.render().el)
    },
    useRole: function (roleBlock) {
      this.use = roleBlock.role_type
    },
    changeRole: function () {
      // clonedModel = new Ts.Role({
      //   type: this.role_type,
      //   person: this.model.get("person").clone(),
      //   residential_contact: this.model.get("residential_contact").clone(),
      //   mailing_contact: this.model.get("mailing_contact").clone()
      // })
      // clonedModel.get("person").set({id: null})
      wizard = new Ts.Wizard({title: "Change "+this.role_name, role: this.model})
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
  
  Ts.FormViews.Multibutton = Ts.View.extend({
    tagName: 'span',
    className: 'multibutton',
    templateId: 'form:multibutton_template',
    events: {
      'click span.dropdown_button' : 'toggleList',
      'click li' : 'onSelectButton'
    },
    initialize: function () {
      _.bindAll(this, 'hideList', 'showList', 'keydownHideEvent')
    },
    render: function () {
      this.$el.html(this.template({name: this.options.name, options: this.options.values}))
      var viewport = this.$('.viewport')
      var height = viewport.find('li').outerHeight() || 34
      viewport.css({height: height});
      if (Object.keys(this.options.values).length <= 1)
        this.$el.addClass('no_dropdown')
      else
        this.$el.removeClass('no_dropdown')
      this.selectButton(this.options.selected || this.$('input:first')[0].name)
      this.hideList()
      
  		return this
    },
    toggleList: function () {
      var viewport = this.$('.viewport')
      viewport.hasClass('show') ? this.hideList() : this.showList()
    },
    showList: function () {
      this.autoAdjustHeight()
      this.$('.viewport').addClass('show')
      var list = this.$('.viewport ul')
      var window_bottom = $(window).scrollTop() + $(window).height();
			var list_bottom = list.offset().top + list.outerHeight();
			if((list_bottom + 10) > window_bottom) {
			  list.css({top: -(list.outerHeight() - list.find('li').outerHeight())})
			} else {
			  list.css({top: -list.children('li.selected').position().top})
			}
			// If we don't wrap this binding in a delay, it'll fire directly after this event which is not what we want.
			_.delay(function (self) { $(document).click(self.hideList); }, 1, this);
			$(window).blur(this.hideList)
			$(document).keydown(this.keydownHideEvent)
    },
    hideList: function () {
      var list = this.$('.viewport ul')
      list.css({top: -list.children('li.selected').position().top})
      this.$('.viewport').removeClass('show')
      $(document).unbind('click', this.hideList)
			$(window).unbind('blur', this.hideList)
			$(document).unbind('keydown', this.keydownHideEvent)
    },
    autoAdjustHeight: function () {
      var viewport = this.$('.viewport')
      var height = viewport.find('li').outerHeight()
      if (height > 0) viewport.css({height: height})
    },
    selectButton: function(selectedName) {
      var list = this.$('.viewport > ul')
      selected = list.find('li > input[name='+selectedName+']').parent()
      list.css({top: -selected.position().top})
		  list.children('li').removeClass('selected')
		  selected.addClass('selected')
		},
    onSelectButton: function (e) {
			var target = e.currentTarget
      var button = $(target).children('input')
			var selectedName = button.attr('name')
      this.selectButton(selectedName)
			if (this.options.actions && this.options.actions[selectedName]) {
				var result = this.options.actions[selectedName](button)
			} else if (this.options.actions && this.options.actions['default']) {
				var result = this.options.actions['default'](button)
			}
      this.hideList()
			return (result == true) ? true : false
    },
    keydownHideEvent: function (e) {
      if (e.keyCode == 27) this.hideList();
    }
  })
  
  Ts.FormViews.PlacePicker = Ts.View.extend({
    tagName: 'label',
    className: 'placepicker',
    templateId: 'form:place_picker_template',
    events: {
      'change': 'selectPlace'
    },
    initialize: function () {
      _.bindAll(this, 'selectPlace')
      this.options.insertFunction = this.options.insertFunction || 'append'
    },
    render: function () {
      this.$el.html(this.template({
        type: this.collection.first().get('type'),
        places: this.collection.toJSON(),
        selected: this.options.selected,
        disabled: this.options.disabled
			}))
			setTimeout("this.$('select').focus()")
      return this
    },
    renderPlaces: function (places, options) {
      options = options || {}
      var view = new Ts.FormViews.PlacePicker($.extend({}, this.options, options, {collection: places}))
      this.$el.parent()[this.options.insertFunction](view.render().el)
      return this
    },
    selectPlace: function (e) {
      var target = $(e.target)
      var placeId = target.children(':selected').attr('value')
      this.$el.nextAll().remove()
      if(placeId) {
        if(target.data('placeType') == 'section') {
          this.nextAvailable(placeId)
        } else {
          this.load(placeId)
        }
      }
      return this
    },
    load: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      this.$el.append('<div class="indicator loading" />')
      this.lastRequest = $.ajax('/place/children/'+parent_id, {
				type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          var places = new Ts.Places(data) 
          if(places.length > 0) {
            this.renderPlaces(places)
            this.$('.indicator').remove()
          } else if (this.collection.get(parent_id).get('child_count') > 0) {
            this.$('.indicator').attr({
              class: 'indicator warning',
              title: this.collection.get(parent_id).get('type').demodulize().titleize() + ' is not available.'
            })
          } else {
            this.$('.indicator').remove()
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          this.$('.indicator').remove()
          if(textStatus != 'abort') alert('Some went wrong!')
        }
      })
      return this
    },
    nextAvailable: function (parent_id) {
      this.lastRequest && this.lastRequest.abort()
      this.$('.indicator').remove()
      this.$el.append('<div class="indicator loading" />')
      this.lastRequest = $.ajax('/place/next_available/'+parent_id, {
        type: 'GET',
				dataType: 'json',
        success: _.bind(function (data, textStatus, jqXHR) {
          if (data && Object.keys(data).length > 0) {
            _.each(data, function (places, selected_id) {
              this.renderPlaces(new Ts.Places(places), {selected: selected_id})
            }, this)
            this.$('.indicator').remove()
          } else {
            this.$('.indicator').attr({
              class: 'indicator warning',
              title: this.collection.get(parent_id).get('type').demodulize().titleize() +
                ' does not contain any available places.'
            })
          }
        }, this),
        error: function (jqXHR, textStatus, errorThrown) {
          // TODO
          if(textStatus != 'abort') alert(jqXHR.responseText)
          this.$('.indicator').remove()
        }
      })
      return this
    }
    // loadWithAncestors: function (id) {
    //   this.lastRequest && this.lastRequest.abort()
    //   this.$el.append('<div class="indicator loading" />')
    //   this.lastRequest = $.ajax('/place/ancestors/'+id, {
    //     type: 'GET',
		//     dataType: 'json',
    //     data: {include_self: true},
    //     success: _.bind(function (data, textStatus, jqXHR) {
    //       var lastParent = id
    //       _.each(data, function (placeList) {
    //         this.renderPlaces(new Ts.Places(placeList), {selected: lastParent, insertFunction: 'prepend'})
    //         lastParent = placeList[0].parent_id
    //       }, this)
    //     }, this),
    //     error: function (jqXHR, textStatus, errorThrown) {
    //       // TODO
    //       if(textStatus != 'abort') alert('Some went wrong!')
    //     },
    //     complete: _.bind(function () {
    //       this.$('.indicator').remove()
    //     }, this)
    //   })
    //   return this
    // }
  })
})
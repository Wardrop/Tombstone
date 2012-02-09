// JavaScript Document

Ts.Roles = Backbone.Collection.extend({
	model: Ts.Role
})

Ts.Contacts = Backbone.Collection.extend({
	model: Ts.Contact,
  url: '/contacts'
})

Ts.People = Backbone.Collection.extend({
	model: Ts.Person,
  url: '/people'
})

Ts.Places = Backbone.Collection.extend({
  url: '/places'
})
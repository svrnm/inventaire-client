module.exports = Marionette.ItemView.extend
  template: require './templates/icon_nav'
  className: 'innerIconNav'
  initialize: ->
    @lazyRender = _.LazyRender @
    @once 'render', @initListeners.bind(@)

  initListeners: ->
    @listenTo app.vent, 'route:change', @selectButtonFromRoute.bind(@)
    @listenTo app.vent, 'transactions:unread:change', @lazyRender
    @listenTo app.vent, 'i18n:reset', @lazyRender
    @listenTo app.vent, 'network:requests:udpate', @lazyRender

  events:
    'click .add': 'showAddLayout'
    'click .network': 'showNetwork'
    'click .browse': 'showInventory'
    'click .exchanges': 'showTransactions'

  ui:
    all: 'a.iconButton'
    add: '.add'
    network: '.network'
    browse: '.browse'
    exchanges: '.exchanges'

  serializeData: ->
    networkUpdates: @networkUpdates()
    exchangesUpdates: @exchangesUpdates()

  onRender: ->
    @selectButtonFromRoute _.currentSection()

  selectButtonFromRoute: (section)->
    @unselectAll()
    switch section
      when 'add', 'search' then @selectButton 'add'
      when 'network' then @selectButton 'network'
      when 'inventory', 'groups' then @selectButton 'browse'
      when 'transactions' then @selectButton 'exchanges'

    # sections without an associated icon nav button:
    # entity, settings

  unselectAll: ->
    @ui.all.removeClass 'selected'

  selectButton: (uiName)->
    @ui[uiName].addClass 'selected'

  showAddLayout: ->
    @selectButton 'add'
    app.execute 'show:add:layout'

  showNetwork: ->
    @selectButton 'network'
    app.execute 'show:network'

  showInventory: ->
    @selectButton 'browse'
    app.execute 'show:inventory:general'

  showTransactions: ->
    @selectButton 'exchanges'
    app.execute 'show:transactions'

  networkUpdates: ->
    app.request('get:network:counters').total

  exchangesUpdates: ->
    app.request 'transactions:unread:count'

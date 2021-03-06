ItemComments = require './item_comments'
ItemTransactions = require './item_transactions'
EntityData = require 'modules/entities/views/entity_data'
itemActions = require '../plugins/item_actions'
itemUpdaters = require '../plugins/item_updaters'

module.exports = Marionette.LayoutView.extend
  id: 'itemShowLayout'
  template: require './templates/item_show'
  serializeData: ->
    attrs = @model.serializeData()
    _.extend attrs,
      nextPictures: @nextPicturesData(attrs)

  nextPicturesData: (attrs)->
    if attrs.pictures?.length > 1
      return attrs.pictures.slice(1)

  regions:
    entityRegion: '#entity'
    pictureRegion: '#picture'
    transactionsRegion: '#transactions'
    commentsRegion: '#comments'

  behaviors:
    PreventDefault: {}
    ConfirmationModal: {}
    ElasticTextarea: {}

  initialize: ->
    @initPlugins()
    @uniqueSelector = '#'+@id
    @listenTo @model, 'change:details', @render
    @listenTo @model, 'change:notes', @render
    @listenTo @model, 'add:pictures', @render
    app.execute 'metadata:update:needed'

  initPlugins: ->
    itemActions.call(@)
    itemUpdaters.call(@)

  onRender: ->
    @showEntityData()
    @showPicture()
    app.execute('foundation:reload')
    @showComments()

  onShow: ->
    @showTransactions()

    @model.updateMetadata()
    .finally app.execute.bind(app, 'metadata:update:done')

  showEntityData: ->
    { entity } = @model
    if entity? then @showEntity entity
    else @listenTo @model, 'grab:entity', @showEntity.bind(@)

  showEntity: (entity)->
    @entityRegion.show new EntityData
      model: entity
      hidePicture: true

  showPicture: ->
    picture = new app.View.Behaviors.ChangePicture {model: @model}
    @pictureRegion.show picture

  events:
    'click a#destroy': 'itemDestroy'
    'click a#changePicture': 'changePicture'
    'click a#editDetails, a#cancelDetailsEdition': 'toggleDetailsEditor'
    'click a#validateDetails': 'validateDetails'
    'click a#editNotes, a#cancelNotesEdition': 'toggleNotesEditor'
    'click a#validateNotes': 'validateNotes'
    'click a.requestItem': -> app.execute 'show:item:request', @model

  itemEdit: -> app.execute 'show:item:form:edition', @model

  changePicture: ->
    picturePicker = new app.View.Behaviors.PicturePicker
      pictures: @model.get('pictures')
      # limit: 3
      limit: 1
      save: @savePicture.bind(@)
    app.layout.modal.show picturePicker

  savePicture: (value)->
    app.request 'item:update',
      item: @model
      attribute: 'pictures'
      value: value

  itemDestroy: ->
    app.request 'item:destroy',
      model: @model
      selector: @uniqueSelector
      next: -> app.execute 'show:home'


  toggleDetailsEditor: -> @toggleEditor('details')
  toggleNotesEditor: -> @toggleEditor('notes')

  validateDetails: -> @validateEdit('details')
  validateNotes: -> @validateEdit('notes')

  toggleEditor: (nameBase)->
    $("##{nameBase}").toggle()
    $("##{nameBase}Editor").toggle()

  validateEdit: (nameBase)->
    @toggleEditor(nameBase)
    edited = $("##{nameBase}Editor textarea").val()
    if edited isnt @model.get(nameBase)
      app.request 'item:update',
        item: @model
        attribute: nameBase
        value: edited
        selector: "##{nameBase}Editor"

  showComments:->
    @commentsRegion.show new ItemComments { model: @model }

  showTransactions: ->
    transactions = app.request 'get:transactions:ongoing:byItemId', @model.id
    @transactionsRegion.show new ItemTransactions { collection: transactions }

  afterDestroy: ->
    app.execute 'show:inventory:main:user'

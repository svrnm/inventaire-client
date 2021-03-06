Imgs = require 'modules/general/collections/imgs'
images_ = require 'lib/images'
forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'
behaviorsPlugin = require 'modules/general/plugins/behaviors'

module.exports = Marionette.CompositeView.extend
  className: ->
    { limit } = @options
    "picture-picker limit-#{limit}"

  template: require './templates/picture_picker'
  childViewContainer: '#availablePictures'
  childView: require './picture'

  behaviors:
    AlertBox: {}
    SuccessCheck: {}
    Loading: {}
    PreventDefault: {}

  initialize: ->
    @limit = @options.limit or 1
    pictures = _.forceArray @options.pictures
    collectionData = pictures.map getImgData.bind(null, @options.crop)
    @collection = new Imgs collectionData

  serializeData: ->
    urlInput: @urlInputData()

  urlInputData: ->
    nameBase: 'url'
    field:
      type: 'url'
      placeholder: _.i18n 'enter an image url'
    button:
      text: _.i18n 'go get it!'
    allowMultiple: @limit > 1

  onShow: ->
    app.execute 'modal:open', 'large'
    @selectFirst()
    @ui.urlInput.focus()

  ui:
    urlInput: '#urlField'

  events:
    'click #validate': 'validate'
    'click #cancel': 'close'
    'change input[type=file]': 'getFilesPictures'
    'click #urlButton': 'fetchUrlPicture'

  selectFirst: ->
    @collection.models[0]?.select()

  validate: ->
    behaviorsPlugin.startLoading.call @, '#validate'
    @getFinalUrls()
    .catch error_.Complete('.alertBox')
    .then _.Log('final urls')
    .then @_saveAndClose.bind(@)
    .catch forms_.catchAlert.bind(null, @)

  getFinalUrls: ->
    selectedModels = @collection.models.filter isSelectedModel
    _.log selectedModels, 'selected models'
    selectedModels = selectedModels.slice 0, @limit
    _.log selectedModels, 'sliced models'
    Promise.all _.invoke(selectedModels, 'getFinalUrl')

  _saveAndClose: (urls)->
    @options.save urls
    @close()

  fetchUrlPicture: (e)->
    url = @ui.urlInput.val()

    _.preq.start()
    .then validateUrlInput.bind(null, url)
    .then images_.getUrlDataUrl.bind(null, url)
    .then @_addToPictures.bind(@)
    .catch forms_.catchAlert.bind(null, @)

  getFilesPictures: (e)->
    files = _.toArray e.target.files
    _.log files, 'files'
    files.forEach @_addFileToPictures.bind(@)

  _addFileToPictures: (file)->
    unless _.isObject file then return _.warn file, 'couldnt _addFileToPictures'
    images_.getFileDataUrl file
    .then @_addToPictures.bind(@)
    .catch _.Error('_addFileToPictures')

  _addToPictures: (dataUrl)->
    if @limit is 1 then @_unselectAll()
    @_addDataUrlToCollection dataUrl

  _unselectAll: (dataUrl)->
    @collection.invoke 'set', 'selected', false

  _addDataUrlToCollection: (dataUrl)->
    @collection.add
      dataUrl: dataUrl
      selected: true
      crop: @options.crop

  close: -> app.execute 'modal:close'

isSelectedModel = (model)-> model.get('selected')

validateUrlInput = (url)->
  unless _.isUrl url
    forms_.throwError 'invalid url', '#urlField', arguments

getImgData = (crop, url)->
  url: url
  crop: crop

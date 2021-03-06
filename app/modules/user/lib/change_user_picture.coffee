regex_ = sharedLib 'regex'

module.exports = ->
  app.layout.modal.show new app.View.Behaviors.PicturePicker
    pictures: app.user.get 'picture'
    save: savePicture
    crop: true
    limit: 1

savePicture = (pictures)->
  picture = pictures[0]
  _.log picture, 'picture'
  unless _.isLocalImg picture
    throw new Error 'couldnt save picture: requires a local image url'

  app.request 'user:update',
    attribute: 'picture'
    value: picture
    selector: '#changePicture'

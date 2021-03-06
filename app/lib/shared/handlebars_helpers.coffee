module.exports = (_, appApi)->
  onePictureOnly = (arg)->
    if _.isArray(arg) then return arg[0] else arg

  getImgDimension = (dimension, defaultValue)->
    if _.isNumber dimension then return dimension
    else defaultValue

  return helpers_ =
    src: (path, width, height, extend)->
      if _.isDataUrl path then return path

      width = getImgDimension width, 1600
      width = _.bestImageWidth width
      height = getImgDimension height, width
      path = onePictureOnly path

      return ''  unless path?

      if _.isLocalImg path then path = path.replace '/img/', ''
      return appApi.img path, width, height

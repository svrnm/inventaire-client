books_ = sharedLib('books')(_)

books_.getImage = (data)->
  if data?
    images.push data
    lazyGetImages()
    return eventName(data)
  else _.error 'no data provided'

images = []
eventName = (data)->
  # using a hash of the data to avoid firing the event several times
  # because the eventName contains spaces
  data = _.hashCode data
  return "image:#{data}"

getImages = ->
  if images.length > 0
    _.log images, 'querying images'
    _.preq.get app.API.entities.getImages(images)
    .then spreadImages
    .catch _.Error("getImages err for images: #{images}")

lazyGetImages = _.debounce getImages, 100

spreadImages = (res)->
  # _.log res, 'data:getImages res'
  if _.isArray res
    res.forEach (el)->
      if el?.data?
        ev = eventName el.data
        app.vent.trigger ev, el.image
  # reset images
  images = []


books_.getIsbnEntities = (isbns)->
  isbns = isbns.map books_.normalizeIsbn
  _.preq.get app.API.entities.isbns(isbns)
  .catch _.Error('getIsbnEntities err')

module.exports = books_
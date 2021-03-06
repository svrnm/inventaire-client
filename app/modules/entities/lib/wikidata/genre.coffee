wd_ = require 'lib/wikidata'

module.exports = wdGenre_ = {}

wdGenre_.fetchBooksAndAuthors = (genreModel)->
  wdGenre_.fetchBooksAndAuthorsIds(genreModel)
  # forcing default argument to neutralize fetchBooksAndAuthorsIds returned value
  .then wdGenre_.fetchBooksAndAuthorsEntities.bind(null, genreModel, null, null)
  .catch _.Error('wdGenre_.fetchBooksAndAuthors')


wdGenre_.fetchBooksAndAuthorsIds = (genreModel)->
  reverseClaims = genreModel.get 'reverseClaims'
  if reverseClaims?
    { P135, P136 } = reverseClaims
    if P135? or P136? then return _.preq.resolve()

  Promise.all [
    wd_.getReverseClaims('P135', genreModel.id) #mouvement
    wd_.getReverseClaims('P136', genreModel.id) #genre
  ]
  .then _.flatten
  .then _.uniq
  .then _.Log('books and authors ids')
  .then genreModel.save.bind(genreModel, 'reverseClaims.P136')
  .catch _.Error('wdGenre_.fetchBooksAndAuthorsIds')


wdGenre_.fetchBooksAndAuthorsEntities = (genreModel, limit=30, offset=0)->
  _.types [genreModel, limit, offset], ['object', 'number', 'number']
  first = offset
  last = offset + limit
  range = genreModel.get('reverseClaims.P136')[first...last]

  unless range.length > 0
    _.warn 'no more ids: range is empty'
    return _.preq.resolve()

  return app.request 'get:entities:models', 'wd', range

# EXPECT books collection, authors collection, entities models
wdGenre_.spreadBooksAndAuthors = (books, authors, entities)->

  unless entities? then return _.warn 'no entities to spread'

  entities.forEach (entity)->
    switch wd_.type entity
      when 'book' then books.add entity
      when 'human' then authors.add entity
      else _.warn [entity, entity.get('label'), entity.get('claims.P31')], 'neither a book or a human'

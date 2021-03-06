wd_ = require 'lib/wikidata'
aliases = sharedLib 'wikidata_aliases'

module.exports =
  fetchAuthorsBooks: (authorModel)->
    fetchAuthorsBooksIds(authorModel)
    .then fetchAuthorsBooksEntities.bind(null, authorModel)
    .then keepOnlyBooks
    .catch _.Error('wdAuthors_.fetchAuthorsBooks')

fetchAuthorsBooksIds = (authorModel)->
  if authorModel.get('reverseClaims')?.P50? then return _.preq.resolve()

  # TODO: also fetch aliased Properties, not only P50
  wd_.getReverseClaims 'P50', authorModel.id
  .then _.Log('booksIds')
  .then authorModel.save.bind(authorModel, 'reverseClaims.P50')
  .catch _.Error('fetchAuthorsBooksIds err')

fetchAuthorsBooksEntities = (authorModel)->
  authorsBooks = authorModel.get 'reverseClaims.P50'
  _.log authorsBooks, 'authorsBooks?'
  unless authorsBooks?.length > 0 then return _.preq.resolve()

  # only fetching the 50 first entities to avoid querying entities
  # wikidata api won't return anyway due to API limits
  # TODO: implement pagination/continue
  authorsBooks = authorsBooks[0..49]
  return app.request 'get:entities:models', 'wd', authorsBooks

keepOnlyBooks = (entities)->
  # compaction needed in case entities are missing
  # (typically because of API limits)
  _.compact(entities).filter wd_.entityIsBook

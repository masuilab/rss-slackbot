path = require 'path'
request = require 'request'
FeedParser = require 'feedparser'
async = require 'async'
debug = require('debug')('rssbot')
Slackbot = require 'slackbot'

unless process.env.SLACK_TOKEN?
  console.error "set ENV variable  e.g. SLACK_TOKEN=a1b2cdef3456"
  process.exit 1

console.log config = require path.resolve 'config.json'

slack = new Slackbot config.slack.team, process.env.SLACK_TOKEN

notify = (msg, callback) ->
  slack.send config.slack.channel, "#{config.slack.header} #{msg}", callback

cache = {}

fetch = (feed_url, callback = ->) ->
  try
    feed = request(feed_url).pipe(new FeedParser)
  catch err
    callback err
    return
  entries = []
  feed.on 'error', (err) ->
    callback err
  feed.on 'data', (chunk) ->
    entries.push {url: chunk.link, title: chunk.title}
  feed.on 'end', ->
    callback null, entries

run = (opts = {}, callback) ->
  async.eachSeries config.feeds, (url, next) ->
    fetch url, (err, entries) ->
      if err
        debug JSON.stringify err
        next()
        return
      for entry in entries
        do (entry) ->
          debug "fetch - #{JSON.stringify entry}"
          return if cache[entry.url]?
          cache[entry.url] = entry.title
          callback entry unless opts.silent
      setTimeout ->
        next()
      , 1000

onNewEntry = (entry) ->
  debug "new entry - #{JSON.stringify entry}"
  notify "#{entry.title}\n#{entry.url}", (err, res) ->
    if err
      debug "notify error : #{err}"
      return
    debug res.body

## Run
setInterval ->
  run null, onNewEntry 
, 1000 * config.interval

run {silent: true}, onNewEntry  # 最初の1回は通知しない

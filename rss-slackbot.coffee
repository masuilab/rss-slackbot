path = require 'path'
request = require 'request'
FeedParser = require 'feedparser'
debug = require('debug')('rssbot')
Slackbot = require 'slackbot'

console.log config = require path.resolve 'config.json'

unless process.env.SLACK_TOKEN?
  console.error "set ENV variable  e.g. SLACK_TOKEN=a1b2cdef3456"
  process.exit 1

slack = new Slackbot config.slack.team, process.env.SLACK_TOKEN

notify = (msg, callback) ->
  slack.send config.slack.channel, "#{config.slack.header} #{msg}", callback

entries = {}

fetch = (feed_url, callback = ->) ->
  feed = request(feed_url).pipe(new FeedParser)
  feed.on 'error', (err) ->
    
  feed.on 'data', (chunk) ->
    callback {url: chunk.link, title: chunk.title}
  feed.on 'end', ->

  
run = (opts = {}, callback) ->
  for url in config.feeds
    fetch url, (entry) ->
      debug "fetch - #{JSON.stringify entry}"
      return if entries[entry.url]?
      entries[entry.url] = entry.title
      callback entry unless opts.silent

onNewEntry = (entry) ->
  console.log "new entry - #{JSON.stringify entry}"
  notify "#{entry.title}\n#{entry.url}", (err, res) ->
    if err
      debug "notify error : #{err}"
      return
    debug res


setInterval ->
  run null, onNewEntry 
, 1000 * config.interval

run {silent: true}, onNewEntry

# Description
#  A Netrunner info hubot
#
# Configuration:
#  None
#
# Commands:
#  hubot netrunner {query} - responds with card info from wikia and shows a url
#  hubot nrdb {card_attribute} {query} - responds with card info from netrunner db
#  hubot nrdb {card_attribute} {query} -l - responds with list of first 10 matches
#  hubot nrdb {card_attribute} {query} -n - responds with only card image, no text
#
# Author:
#  omardelarosa
#
_ = require('lodash')
util = require('util')

superscript_mappings =
  0: '\u2070'
  1: '\u00B9'
  2: '\u00B2'
  3: '\u00B3'
  4: '\u2074'
  5: '\u2075'
  6: '\u2076'
  7: '\u2077'
  8: '\u2078'
  9: '\u2079'

formatResponse = (bodyObj, url) ->
  text = "\n"
  if bodyObj["sections"]
    _.each bodyObj["sections"], (s) ->
      if s.title == "Sources"
        return
      text += s.title + "\n"
      if s.content
        _.each s.content, (c) ->
          if c.type == "paragraph"
            text += "\t" + c.text + "\n\n"
          if c.type == "list" and c.elements.length > 0
            _.each c.elements, (e) ->
              text += "\t" + e.text + "\n\n"
  text += url + "\n"
  return text

formatNRDBResponse = (msg, card, opts) ->
  text = "\n"
  text += "*Title*: #{card.title}\n"
  text += "*Faction*: #{
    if card.faction == 'Neutral'
      'Neutral'
    else ':' + (card.faction.toLowerCase().replace(/\s+/g,'_')) + ':'
  }\n"

  text += "*Type*: #{card.type} #{ if card.subtype then (' - ' + card.subtype) else '' }\n"
  if card.type == "Agenda"
    text += "*Adv/Pts*: #{card.advancementcost} \/#{card.agendapoints}\n"
  if card.type == "ICE" || card.type == "Upgrade" || card.type == "Asset"
    text += "*Rez Cost*: #{card.cost}\n"
    if card.type == "ICE"
      text += "*Strength*: #{card.strength}\n"
  
  if card.type == "Program" || card.type == "Resource" || card.type == "Hardware"
    text += "*Install Cost*: #{card.cost}\n"
    if /Icebreaker/i.test(card.subtype)
      text += "*Strength*: #{card.strength}\n"
  
  if card.type == "Operation" || card.type == "Event"
    text += "*Cost*: #{card.cost}\n"
  
  if card.factioncost != null || card.factioncost != 0
    text += "*Influence*: #{card.factioncost}\n"
  
  text += "*Set*: #{card.setname}\n"
  
  text += '*Text*: ' + card.text
    # Wrap icons in Slack-friendly colons
    .replace(/[\[|\]]/g, ':')
    # Lowercase words between colons
    .replace(
      /\:(.*)\:/g,
      (r) ->
        r.replace(/\s/g,'').toLowerCase()
    )
    # Process superscripts for traces
    .replace(
      /<sup>(\d+)<\/sup>/,
      (match, p1) ->
        superscript = superscript_mappings[p1]
        if superscript
          return superscript
        else
          return '^'+p1
    )
        # Replace ":link:" tag with Slack-friendly ":linknr:"
    .replace(/:link:/g, ":linknr:")
    # Process strong tags into Slack-friendly asterisks
    .replace(/<strong>/g, '*')
    .replace(/<\/strong>/g, '*') + '\n'

  text += "*NRDBURL*: #{card.url}\n"
  if !opts.noText
    msg.send text
  if card.imagesrc
    msg.send 'http://netrunnerdb.com' + card.imagesrc
  return text

nrdb = (msg) ->
  matchData = msg.match[0].split(' ')
  indexOfListFlag = matchData.indexOf('-l')
  indexOfNoTextFlag = matchData.indexOf('-n')
  if indexOfListFlag != -1
    listTen = true
    matchData.splice(indexOfListFlag, 1)
  else
    listTen = false
  if indexOfNoTextFlag != -1
    noText = true
    matchData.splice(indexOfNoTextFlag, 1)
  else
    noText = false
  opts = { noText: noText, listTen: listTen }
  key = matchData[2]
  query = matchData.slice(3).join(' ')
  url = 'http://netrunnerdb.com/api/cards/'
  msg.http(url)
    .get() (err, res, body) ->
      if err
        # console.log err
        msg.send "Error fetching card data."
        return
      else
        try
          cardList = JSON.parse(body)
          lowerCaseQuery = query.toLowerCase()
          results = _.filter cardList, (card) ->
            if card[key] and card[key].toLowerCase().search(lowerCaseQuery) != -1
              return true
            else
              return false
          if results.length > 0
            if opts.listTen
              results.slice(0, 10).forEach (card) ->
                formatNRDBResponse msg, card, opts
            else
              formatNRDBResponse msg, results[0], opts
          else
            msg.send 'No results matched your query "' + key + ': ' + query + '"'
        catch e
          console.log e
          console.log e.stack
          msg.send "Error parsing response from NetRunner DB"

fetchCard = (msg) ->
  query = msg.match[0].split(' ').slice(2).join('%20')
  url = "http://ancur.wikia.com/api/v1/Search/List/?query=" + query + "&limit=1&namespaces=0%2C14"
  msg.http(url)
    .get() (err, res, body) ->
      if err
        # console.log err
        msg.send "Error fetching card data."
        return
      content = JSON.parse(body)
      if content.items and content.items.length > 0 and content.items[0].id
        id = content.items[0].id
        articleUrl = content.items[0].url
        msg.http("http://ancur.wikia.com/api/v1/Articles/AsSimpleJson?id="+id)
          .get() (err, res, body) ->
            if err
              # console.log err
              msg.send "Error fetching card data."
              return
            bodyObject = JSON.parse(body)
            msg.send formatResponse(bodyObject, articleUrl)
      else
        msg.send "Nothing found for: '"+msg.match[0]+"'"

module.exports = (robot) ->
  robot.respond /netrunner (.*)\b/i, (msg) ->
    fetchCard(msg)
 
  robot.respond /nrdb (.*)\b/i, (msg) ->
    nrdb(msg)

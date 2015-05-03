# Description
#   A Netrunner info hubot
#
# Configuration:
#   None
#
# Commands:
#   hubot netrunner {query} - responds with card info from wikia and shows a url
#   hubot nrdb {card_attribute} {query} - responds with card info from netrunner db
#   hubot nrdb {card_attribute} {query} -l - responds with list of first 10 matches
#
# Author:
#   omardelarosa
#
_ = require('lodash')
util = require('util')

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
   text += 'Title: ' + card.title + '\n'
   text += 'Type: ' + card.type + ' - ' + card.subtype + '\n'
   text += 'Faction: ' + card.faction + '\n'
   text += 'Set: ' + card.setname + '\n'
   text += 'Text: ' + card.text.replace(/[\[|\]]/g, ':') + '\n'
   text += 'NRDBURL: ' + card.url + '\n'
   text
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
               msg.send "Error parsing response from NetRunner DB"

fetchCard = (msg) ->
   query = msg.match[0].split(' ').slice(2).join('%20')
   url = "http://ancur.wikia.com/api/v1/Search/List/?query=" + query + "&limit=1&namespaces=0%2C14"
   msg.http(url)
      .get() (err, res, body) ->
         if err
            console.log err
            msg.send "Error fetching card data."
            return
         content = JSON.parse(body)
         if content.items and content.items.length > 0 and content.items[0].id
            id = content.items[0].id
            articleUrl = content.items[0].url
            msg.http("http://ancur.wikia.com/api/v1/Articles/AsSimpleJson?id="+id)
               .get() (err, res, body) ->
                  if err
                     console.log err
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

   


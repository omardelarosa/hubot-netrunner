# Description
#   A Netrunner info hubot
#
# Configuration:
#   None
#
# Commands:
#   hubot netrunner {query} - displays card info from wikia and shows a url
#
# Author:
#   omardelarosa
#
_ = require('lodash')

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

fetchCard = (msg) ->
   query = msg.match[0].split(' ').slice(3).join('%20')
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
   
   robot.respond /netrunner version\b/i, (msg) ->
      msg.send require('../package').version

   


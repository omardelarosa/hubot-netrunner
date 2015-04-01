# Description
#   A Netrunner info hubot
#
# Configuration:
#   None
#
# Commands:
#   hubot netrunner card {query} - displays a card from netrunnerdb
#   hubot netrunner {query} - displays wikia article
#
# Author:
#   omardelarosa
#

module.exports = (robot) ->
  robot.respond /netrunner card\b/i, (msg) ->
     msg.send "netrunner!"
   
  robot.respond /netrunner version\b/i, (msg) ->
      msg.send require('../package').version

    fetchCard = (msg, num) ->
      query = msg.replace(' ', '%20')
      url = "http://ancur.wikia.com/api/v1/Search/List/?query=" + query + "&limit=1&namespaces=0%2C14"
      msg.http(url)
       .get() (err, res, body) ->
         content = JSON.parse(body)
         if content.data and content.data.length > 0
           msg.send (msg.random content.data).link
         else
           msg.send "No response from host."


# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
marked = require 'marked'
moment = require('moment')

TEASER = /<!--\s*more\s*-->/i
READ_SPEED = 500

docpadConfig = {
	# I'm using chinese
	detectEncoding: true

	# =================================
	# Template Data
	# These are variables that will be accessible via our templates
	# To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData:

		# Specify some site properties
		site:
			# The production url of our website
			url: "http://tchen.me"

			# Here are some old site urls that you would like to redirect from
			oldUrls: [
				'www.tchen.me'
			]

			# The default title of our website
			title: "觅珠人 | Tyr Chen的个人博客 | 创意 | 心得 | 经验"

			# The website description (for SEO)
			description: """
				本博客提供我个人的想法，创意，经验，心得。你不必认同博主观点。
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				创业, 思想, 点子, 经验, python, erlang, node, javascript, 服务器, devops, meteor
				"""

			author: "Tyr Chen"

			avatar: "/assets/images/tyr.png"

			address: "No. 1 Zhongguancun East Road, Beijing, China"

			phone: ""

			fax: ""

			social: [
				["icon-envelope", "tyr.chen{#}gmail.com"],
				["icon-weibo", "http://weibo.com/tchen82"],
				["icon-github", "http://github.com/tyrchen"],
				["icon-linkedin", "http://linkedin.com/in/tyrchen/"],
				["icon-twitter", "https://twitter.com/tyrchen"],
				["icon-facebook", "https://www.facebook.com/tyrchen"],
				["icon-google-plus", "https://plus.google.com/114684266209262341260/"]
			]

			# Styles
			styles: [
				"/assets/css/app.min.css",
			]

			themes: [
				#"/assets/css/theme.css"
			]

			# Scripts
			scripts: [
				"/assets/js/app.min.js",
			]

			# plugins

			duoshuo_name: "tyrchen"

		# -----------------------------
		# Helper Functions

		getPreparedContactInfo: ->
			contact = ""
			if @site.address
				contact += @site.address
			if @site.phone
				contact += "<br/>Phone: #{@site.phone}"
			if @site.fax
				contact += "<br/>Fax: #{@site.fax}"
			if @site.email
				contact += "<br/>Email: <a href='#'>#{@site.email}</a>"
			contact += "<br/>Leave message: <a href='/pages/about.html'>#{@site.url}/pages/about.html</a>"

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} | #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			@document.description or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')

		dpBlockList: (type) ->
			blocks = []
			blocks = blocks.concat @site[type] if @site[type] and Array.isArray @site[type]
			blocks = blocks.concat @document[type] if @document[type] and Array.isArray @document[type]
			return blocks
			
		dpBlock: (type) ->
			blocks = @dpBlockList(type)
			@getBlock(type).add(blocks).toHTML() if blocks.length > 0

		dpBlockStyleWithTheme: ->
			blocks = @dpBlockList('styles')
			# add theme style at last
			blocks = blocks.concat @site['themes'] if @site['themes'] and Array.isArray @site['themes']
			@getBlock('styles').add(blocks).toHTML() if blocks.length > 0			
			
		teaser: (content) ->
			content = marked(content.replace(/#[^\n]+\n/, ''))
			i = content.search(TEASER)
			if i > 0
				content[0..i-1]
			else
				''

		hasTeaser: (content) ->
			content.search(TEASER) >= 0

		timeToRead: (content) ->
			Math.round(content.length / READ_SPEED)

		renderMarkdown: (content) ->
			marked(content)

		formatDate: (date) -> 
			moment.lang('zh-cn')
			moment(date).fromNow()

		chunk: (items, chunkSize = 0) ->
			results = []
			if chunkSize is 0
				return items
			else if chunkSize > 0 and chunkSize != items.length
				while items.length
					results.push items.splice(0, chunkSize)
				return results
			else
				return [items]

		getRecentItems: (type, count, chunkSize = 0) ->
			items =	@getCollection(type).toJSON()[0..count-1]
			@chunk(items, chunkSize)


			
	# =================================
	# Collections
	# These are special collections that our website makes available to us

	collections:
		pages: (database) ->
			database.findAllLive({pageOrder: $exists: true}, [pageOrder:1,title:1])
			
		posts: (database) ->
			database.findAllLive({layout: 'post'}, [date:-1])

		slides: (database) ->
			database.findAllLive({layout: ['slide', 'impress']}, [date:-1])

		canvases: (database) ->
			database.findAllLive({layout: 'canvas'}, [date: -1])


	# =================================
	# Plugins

	#plugins:
	#	downloader:
	#		downloads: [
	#			{
	#				name: 'Twitter Bootstrap'
	#				path: 'src/files/vendor/twitter-bootstrap'
	#				url: 'https://codeload.github.com/twbs/bootstrap/tar.gz/master'
	#				tarExtractClean: true
	#			}
	#		]
	plugins:
		raw:
			commands:
				# rsync
				# -r recursive
				# -u skip file if the destination file is newer
				# -l copy any links over as well
				raw  : ['rsync', '-rul', 'src/raw/', 'out/' ]

		ghpages:
			deployRemote: 'ghpages'
			deployBranch: 'master'
	# =================================
	# DocPad Events

	# Here we can define handlers for events that DocPad fires
	# You can find a full listing of events on the DocPad Wiki
	events:

		# Server Extend
		# Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				if req.headers.host in oldUrls
					res.redirect(newUrl+req.url, 301)
				else
					next()
}


# Export our DocPad Configuration
module.exports = docpadConfig

# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
marked = require 'marked'

TEASER = /<!--\s*more\s*-->/i

docpadConfig = {

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

			# The website author's name
			author: "Tyr Chen"

			# The website author's email
			email: "tyr.chen{#}gmail.com"

			# The address
			address: "No. 1 Zhongguancun East Road, Beijing, China"

			# Phone
			phone: ""

			# Fax
			fax: ""

			# Styles
			styles: [
				"/assets/css/app.css",
				"/assets/css/animate.min.css",
				"http://fonts.googleapis.com/css?family=Open+Sans:300,400,700|Yanone+Kaffeesatz:200,300,400,700|Raleway:200,300,400,500,700",
				"http://netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css",
			]

			themes: [
				"/assets/css/theme.css"
			]

			# Scripts
			scripts: [
				"/assets/js/jquery.js",
				"/assets/js/bootstrap.min.js",
				"/assets/js/jquery.visible.min.js",
				"/assets/js/jquery.isotope.min.js",
				"/assets/js/jquery.knob.js",
				"/assets/js/jquery.scrollUp.min.js",
				"/assets/js/application.js"

			]

			about: """
				2012-2013
			"""
			menu: []

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

		renderMarkdown: (content) ->
			marked(content)
			
	# =================================
	# Collections
	# These are special collections that our website makes available to us

	collections:
		pages: (database) ->
			database.findAllLive({pageOrder: $exists: true}, [pageOrder:1,title:1])
			
		posts: (database) ->
			database.findAllLive({layout: 'post'}, [date:-1])
			
		newestPost: (database) ->
			documents = database.findAllLive({layout: 'post'}, [date:-1])
			if documents
				[documents[0]]
			else
				[]

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

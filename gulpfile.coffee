# Dependencies

gulp	= require "gulp"
plugins	= require("gulp-load-plugins")(lazy: false)
run		= require "run-sequence"

express	= require "express"
open 	= require "open"
path	= require "path"
lr		= require("tiny-lr")()

pkg		= require "./package.json"

# Configuration

Config =
	build: "./client/public/"
	name: pkg.name
	port: 9000
	publish: true
	src: "./client/src/"
	version: pkg.version

# Reset

gulp.task "reset", ->
	return gulp.src Config.build + "/*", read: false
		.pipe plugins.clean
			force: true

# Compile coffeescript

gulp.task "coffeescript", ->
	gulp.src Config.src + "coffeescript/**/*.coffee"
	.pipe plugins.plumber()
	.pipe plugins.coffeelint()
	.pipe plugins.coffeelint.reporter()

	gulp.src Config.src + "coffeescript/main.coffee", read: false
	.pipe plugins.plumber()
	.pipe plugins.browserify
		transform: ["coffeeify"]
		# shim:
		# 	hammerjs:
		# 		path: Config.src + "lib/hammerjs/hammer.js"
		# 		exports: "hammerjs"
	.pipe plugins.if Config.publish, plugins.uglify()
	.pipe plugins.rename "main.js"
	.pipe plugins.header "/* " + Config.name + " : " + Config.version + " : " + new Date() + " */"
	.pipe plugins.size
		showFiles: true
	.pipe gulp.dest Config.build + "scripts"

# Compile Stylus

gulp.task "stylus", ->
	gulp.src Config.src + "stylus/main.styl"
	.pipe plugins.plumber()
	.pipe plugins.stylus()
	.pipe plugins.autoprefixer "last 1 version", "> 1%"
	.pipe plugins.if Config.publish, plugins.minifyCss()
	.pipe plugins.rename "main.css"
	.pipe plugins.header "/* " + Config.name + " : " + Config.version + " : " + new Date() + " */"
	.pipe plugins.size
		showFiles: true
	.pipe gulp.dest Config.build + "styles"

# Compile Jade

gulp.task "jade", ->
	gulp.src Config.src + "jade/*.jade"
	.pipe plugins.plumber()
	.pipe plugins.jade
		pretty: true
		data:
			description: pkg.description
			keywords: pkg.keywords
	.pipe gulp.dest Config.build

# Optimise images

gulp.task "images", ->
	gulp.src Config.src + "images/**/*.{jpg,png,gif}"
		.pipe plugins.plumber()
		.pipe plugins.imagemin
			cache: false
		.pipe plugins.size
			showFiles: true
		.pipe gulp.dest Config.build + "images"

	gulp.src Config.src + "images/**/*.svg"
		.pipe plugins.plumber()
		.pipe plugins.svgmin()
		.pipe plugins.size
			showFiles: true
		.pipe gulp.dest Config.build + "images"

# Copy additional files

gulp.task "copy-files", ->
	
	gulp.src Config.src + "lib/**/*"
	.pipe gulp.dest Config.build + "lib"

	gulp.src Config.src + "images/favicons/favicion.ico"
	.pipe gulp.dest Config.build

	gulp.src Config.src + "images/favicons/browserconfig.xml"
	.pipe gulp.dest Config.build

	gulp.src Config.src + "fonts/*"
	.pipe gulp.dest Config.build + "styles"

# Watch for changes to files

gulp.task "watch", ->
	gulp.watch [
		Config.build + "**/*.js"
		Config.build + "**/*.css"
		Config.build + "**/*.html"
		Config.build + "**/*.{jpg,png,gif,svg}"
	], notifyLivereload

	gulp.watch Config.src + "coffeescript/**/*.coffee", ["coffeescript"]
	gulp.watch Config.src + "stylus/**/*.styl", ["stylus"]
	gulp.watch Config.src + "jade/**/*.jade", ["jade"]
	gulp.watch Config.src + "images/**/*.{jpg,png,gif,svg}", ["images"]
	gulp.watch Config.src + "*", ["copy-files"]
	gulp.watch Config.src + "images/favicons/*.xml", ["copy-files"]

# Run a test server

gulp.task "server", ->
	app = express()
	app.use require("connect-livereload")()
	app.use express.static Config.build
	app.listen Config.port
	lr.listen 35728
	setTimeout ->
		open "http://localhost:" + Config.port
	, 3000

# Update the livereload server

notifyLivereload = (event) ->

	fileName = "/" + path.relative Config.build, event.path
	gulp.src event.path, read: false
		.pipe require("gulp-livereload")(lr)

# Default (development) task

gulp.task "default", ->
	Config.publish = false
	run ["coffeescript", "stylus", "jade", "images", "copy-files"], "watch", "server"

gulp.task "deploy", ->
	Config.publish = true
	run "coffeescript"
	run "stylus"
	run "jade"
	run "images"
	run "copy-files"
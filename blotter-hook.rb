require 'sinatra'
require 'json'

# update with git
def update
	puts "start update"    
	if !Dir.exists?("blotter")							# start by cloning blotter repo
		`git clone --recursive https://github.com/blab/blotter.git`
	end
	Dir.chdir("blotter")								# drop into blotter dir
	`git pull origin master`							# git pull
	`git submodule foreach git pull origin master`		# `git pull origin --recurse-submodules` is better, but requires git 1.7.3
	Dir.chdir("..")										# climb back up to parent dir
	puts "finish update"    	
	return true
end

# build with jekyll
def build
	puts "start build"
	`ruby scripts/preprocess_markdown.rb`				# preprocess markdown
	Dir.chdir("blotter")								# drop into blotter dir
	`jekyll build`										# run jekyll
	Dir.chdir("..")										# climb back up to parent dir
	puts "finish build"	
	return true
end

# deploy to s3
def deploy
	puts "start deploy"    
	`s3_website push --headless --site=blotter/_site`	# run s3_website
	puts "finish deploy"  	
	return true
end

commit = ""
updated = false
built = false
deployed = false

# run
puts "Start up"
a = Thread.new {
	updated? = update
	built? = build
	deployed? = deploy
}

# serve
get '/' do
	"
	<p><em>blotter-hook</em>
	<p>Last commit: #{commit}
	<p>Updated: #{updated}
	<p>Built: #{built}
	<p>Deployed: #{deployed}
	"	
end

# listen
post '/' do

	# check if push is legitimate
  	push = JSON.parse(params[:payload])
  	owner = push["repository"]["owner"]["name"]
  	commit = push["after"]
  	if ["blab","trvrb","cykc"].include?(owner)

		Thread.kill(a)

		# run
		a = Thread.new {
			updated? = update
			built? = build
			deployed? = deploy
  		}	
  	
  	end
  	
end



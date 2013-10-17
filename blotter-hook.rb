require 'sinatra'
require 'json'

# update with git
def update

	puts "start update"    

	# start by cloning blotter repo
	if !Dir.exists?("blotter")
		`git clone --recursive https://github.com/blab/blotter.git`
	end
	
	# drop into blotter dir
	Dir.chdir("blotter")
	
	# git pull
	`git pull origin master`
	`git submodule foreach git pull origin master`	# `git pull origin --recurse-submodules` is better, but requires git 1.7.3
	
	# climb back up to parent dir
	Dir.chdir("..")
	
	updated = true
	puts "finish update"    	

end

# build with jekyll
def build

	puts "start build"
	
	# preprocess markdown
	`ruby scripts/preprocess_markdown.rb`

	# drop into blotter dir
	Dir.chdir("blotter")
		
	# run jekyll
	`jekyll build`
	
	# climb back up to parent dir
	Dir.chdir("..")	
	
	built = true
	puts "finish build"	

end

# deploy to s3
def deploy

	puts "start deploy"    
    
  	# run s3_website
	`s3_website push --headless --site=blotter/_site`
	
	deployed = true
	puts "finish deploy"  	
	
end

# all three
def run
	updated = false
	built = false
	deployed = false
	update
	build
	deploy
end

commit = ""
updated = false
built = false
deployed = false

# run
puts "Start up"
a = Thread.new {
	run
}

# serve
get '/' do
	"
	<p>Last commit #{commit}
	<p>Update: #{updated}
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
			run
  		}	
  	
  	end
  	
end



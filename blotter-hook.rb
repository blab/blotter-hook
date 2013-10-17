require 'sinatra'
require 'json'

# update with git
def run

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
	
	puts "finish build"	

end

# deploy to s3
def deploy

	puts "start deploy"    
    
  	# run s3_website
	`s3_website push --headless --site=blotter/_site`
	
	puts "finish deploy"  	
	
end

# run
puts "Start up"
a = Thread.new {
	update
	build
	deploy
}

# listen
post '/' do

	# check if push is legitimate
  	push = JSON.parse(params[:payload])
  	owner = push["repository"]["owner"]["name"]
  	if ["blab","trvrb","cykc"].include?(owner)

		Thread.kill(a)

		# run
		a = Thread.new {
			update
			build
			deploy
  		}	
  	
  	end
  	
end



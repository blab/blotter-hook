require 'sinatra'
require 'json'

# update with git
def update

	puts "updating..."    

	# start by cloning blotter repo
	if !Dir.exists?("blotter")
		`git clone --recursive https://github.com/blab/blotter.git`
	end
	
	# drop into blotter dir
	Dir.chdir("blotter")
	
	# git pull
	`git pull origin master`
	`git submodule foreach git pull origin master`	# `git pull origin --recurse-submodules` is better, but requires git 1.7.3
	`git submodule init`
	`git submodule update`
	
	# climb back up to parent dir
	Dir.chdir("..")

end

# build with jekyll
def build

	puts "building..."
	
	# preprocess markdown
	`ruby scripts/preprocess_markdown.rb`

	# drop into blotter dir
	Dir.chdir("blotter")
		
	# run jekyll
	`jekyll build`
	
	# climb back up to parent dir
	Dir.chdir("..")	

end

# deploy to s3
def deploy
    
	puts "deploying..."    
    
  	# run s3_website
	`s3_website push --headless --site=blotter/_site`

end

# serve
#get '/' do
#  	"blotter-hook is listening"
#end

# listen
post '/' do

	# check if push is legitimate
  	push = JSON.parse(params[:payload])
  	owner = push["repository"]["owner"]["name"]
  	if ["blab","trvrb","cykc"].include?(owner)

		# run
		update
		build
		deploy
  	
  	end
  	
end

# startup
#update
#build
#deploy

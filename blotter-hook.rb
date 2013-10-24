require 'sinatra'
require 'json'

# update with git
def update(is_updated)
	puts "start update"    
	if !Dir.exists?("blotter")							# start by cloning blotter repo
		`git clone --recursive https://github.com/blab/blotter.git`
	end
	Dir.chdir("blotter")								# drop into blotter dir							
	`git clean -f -d`									# remove untracked files
	`git reset --hard HEAD`								# bring back to head state
	`git pull origin master`							# git pull			
	`git submodule init`								# add modules if missed in clone	
	`git submodule update`		
	`git submodule foreach git clean -f -d`				# remove untracked files in submodules				
	`git submodule foreach git pull origin master`		# `git pull origin --recurse-submodules` is better, but requires git 1.7.3
	Dir.chdir("..")										# climb back up to parent dir
	puts "finish update"    	
	is_updated = true;
end

# build with jekyll
# don't rescue from within function
def build(is_built)
	puts "start build"
	`ruby scripts/preprocess-markdown.rb`				# preprocess markdown
	Dir.chdir("blotter")								# drop into blotter dir
	out = `jekyll build`								# run jekyll
	if out =~ /\rerror/
		raise "Build error"
	end
	Dir.chdir("..")										# climb back up to parent dir
	puts "finish build"	
	is_built = true
end

# deploy to s3
def deploy(is_deployed)
	puts "start deploy"    
	`s3_website push --headless --site=blotter/_site`	# run s3_website
	puts "finish deploy"  	
	is_deployed = true
end

commit = ""
is_updated = false
is_built = false
is_deployed = false

# run
puts "Start up"
a = Thread.new {
	begin
		update(is_updated)
		build(is_built)
		deploy(is_deployed)
	rescue
		retry
	end
}

# serve
get '/' do
	"
	<p><b>blotter-hook</b>
	<p>Last commit: #{commit}
	<p>Updated: #{is_updated}
	<p>Built: #{is_built}
	<p>Deployed: #{is_deployed}
	"	
end

# listen
post '/' do

	# check if push is legitimate
  	push = JSON.parse(params[:payload])
  	owner = push["repository"]["owner"]["name"]
  	commit = push["after"]
  	if ["blab","trvrb","cykc"].include?(owner)
  	
  		is_updated = false
		is_built = false
		is_deployed = false

		Thread.kill(a)

		# run
		a = Thread.new {
			begin
				update(is_updated)
				build(is_built)
				deploy(is_deployed)
			rescue
				retry
			end
  		}	
  	
  	end
  	
end



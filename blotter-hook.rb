require 'sinatra'
require 'yaml'
require 'json'

# global variables to store progress
$commit = ""
$is_updated = false
$is_built = false
$is_deployed = false

# starting directory
$basedir = Dir.pwd

# update main repo 
def update_site
	puts "start blotter update"    
	Dir.chdir($basedir)
	if !Dir.exists?("blotter")								# start by cloning blotter repo
		`git clone https://github.com/blab/blotter.git`
	end
	Dir.chdir($basedir + "/blotter")									
	`git clean -f`											# remove untracked files, but keep directories
	`git reset --hard HEAD`									# bring back to head state
	`git pull origin master`								# git pull				
	puts "finish blotter update"    	
end
	
# update project repos
def update_projects
	puts "start project update"    
	Dir.chdir($basedir + "/blotter")							
	config = YAML.load_file("_config.yml")
	config["projects"].each do |repo|
		name = repo.split('/').drop(1).join('')		
		Dir.chdir($basedir + "/blotter/projects")			
		if !Dir.exists?(name)								# clone project repo
			`git clone https://github.com/#{repo}.git`
		end
		Dir.chdir($basedir + "/blotter/projects/" + name)	
		`git clean -f`										# remove untracked files, but keep directories
		`git reset --hard HEAD`								# bring back to head state
		`git pull origin master`							# git pull					
	end
	$is_updated = true	
	puts "finish project update"    		
end

# build with jekyll
# don't rescue from within function
def build
	puts "start build"
	Dir.chdir($basedir)	
	`ruby scripts/preprocess-markdown.rb`				# preprocess markdown
	Dir.chdir($basedir + "/blotter")	
	out = `jekyll build`								# run jekyll
	puts "finish build"	
	$is_built = true
end

# deploy to s3
def deploy
	puts "start deploy"    
	Dir.chdir($basedir)		
	`s3_website push --headless --site=blotter/_site`	# run s3_website
	puts "finish deploy"  	
	$is_deployed = true
end

# run
puts "Start up"
a = Thread.new {
	update_site
	update_projects
	build
	deploy
}

# serve
get '/' do
	"
	<p><b>blotter-hook</b>
	<p>Last commit: #{$commit}
	<p>Updated: #{$is_updated}
	<p>Built: #{$is_built}
	<p>Deployed: #{$is_deployed}
	"	
end

# listen
post '/' do

	# check if push is legitimate
  	push = JSON.parse(params[:payload])
  	owner = push["repository"]["owner"]["name"]
  	$commit = push["after"]
  	if ["blab","trvrb","cykc"].include?(owner)
  	
  		$is_updated = false
		$is_built = false
		$is_deployed = false

		Thread.kill(a)

		# run
		a = Thread.new {
			update_site
			update_projects
			build
			deploy
  		}	
  	
  	end
  	
end



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

module Hook

	# update main repo 
	def self.update_site
		puts "start blotter update"    
		out = ""
		Dir.chdir($basedir)
		if !Dir.exists?("blotter")									# start by cloning blotter repo
			out += `git clone https://github.com/blab/blotter.git`
		end
		Dir.chdir($basedir + "/blotter")									
		out += `git clean -f`										# remove untracked files, but keep directories
		out += `git reset --hard HEAD`								# bring back to head state
		out += `git pull origin master`								# git pull				
		if out =~ /error/ || out =~ /exception/
			raise StandardError "blotter update error"
		end
		puts "finish blotter update"    	
	end
		
	# update project repos
	def self.update_projects
		puts "start project update"    
		Dir.chdir($basedir + "/blotter")							
		config = YAML.load_file("_config.yml")
		config["projects"].each do |repo|
			out = ""		
			name = repo.split('/').drop(1).join('')		
			Dir.chdir($basedir + "/blotter/projects")			
			if !Dir.exists?(name)									# clone project repo
				out += `git clone https://github.com/#{repo}.git`
			end
			Dir.chdir($basedir + "/blotter/projects/" + name)	
			out += `git clean -f`									# remove untracked files, but keep directories
			out += `git reset --hard HEAD`							# bring back to head state
			out += `git pull origin master`							# git pull					
			if out =~ /error/ || out =~ /exception/
				raise StandardError "project update error"
			end				
		end			
		$is_updated = true	
		puts "finish project update"    		
	end
	
	# build with jekyll
	# don't rescue from within function
	def self.build
		puts "start build"
		out = ""		
		Dir.chdir($basedir)	
		`ruby scripts/preprocess-markdown.rb`						# preprocess markdown
		Dir.chdir($basedir + "/blotter")	
		out += `jekyll build`										# run jekyll
		if out =~ /error/ || out =~ /exception/
			raise StandardError "build error"
		end				
		puts "finish build"	
		$is_built = true
	end
	
	# deploy to s3
	def self.deploy
		puts "start deploy"   
		out = ""			
		Dir.chdir($basedir)		
		out += `s3_website push --headless --site=blotter/_site`	# run s3_website
		if out =~ /error/ || out =~ /exception/
			raise StandardError "build error"
		end					
		puts "finish deploy"  	
		$is_deployed = true
	end
	
	# run
	def self.run
		begin
			tries ||= 5
			update_site
			update_projects
			build
			deploy	
		rescue StandardError => e
			puts e.message 
			tries -= 1
			if tries > 0
				sleep 5
				retry
			else
				puts "Abort! abort!"
			end
		end
	end
	
end	
		
# run
a = Thread.new {
	Hook.run
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
			Hook.run
		}	
	
	end
	
end


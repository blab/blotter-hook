# update with git
def update

	# start by cloning blotter repo
	if !Dir.exists?("blotter")
		`git clone --recursive https://github.com/blab/blotter.git`
	end
	
	# drop into blotter dir
	Dir.chdir("blotter")
	
	# git pull
	puts "git pull"
	`git pull origin master`
	`git submodule foreach git pull origin master`	# `git pull origin --recurse-submodules` is better, but requires git 1.7.3
	`git submodule update`
	
	# climb back up to parent dir
	Dir.chdir("..")

end

# build with jekyll
def build

	# drop into blotter dir
	Dir.chdir("blotter")
	
	# run jekyll
	puts "jekyll build"
	`jekyll build`
	
	# climb back up to parent dir
	Dir.chdir("..")	

end

# deploy to s3
def deploy
    
  	# run s3_website
	puts "s3_website push"
	`s3_website push --site=blotter/_site/`

end

# run script
update
build
deploy
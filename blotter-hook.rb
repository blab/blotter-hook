require 'rugged'

# build script
def build

	# start by cloning blotter repo
	if !Dir.exists?("blotter")
		Repository.clone_at("https://github.com/blab/blotter.git")
	end

end

build
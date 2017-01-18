#!/bin/bash
#
show_help () {
  cat << EOFhelp
    Script to build packer boxes automagically.
EOFhelp
}

# Where to find the .json files
base_dir='./json/'

# Get all the files
available_boxes=$( ls -1 $base_dir )

# Main loop
for box in $available_boxes
do
	# If headless is set to false, don't build the box
	headless=$( cat ${base_dir}${box} | grep headless | cut -d ':' -f 2 | sed 's/,$//g' )
	if $headless
	then
		# Get the free space in the home mount point via df
		# Returns the free space in Bytes
		free_space=$( df | grep '/home' | awk '{ print $4 }' )
		# Make sure that there is at least 1 GB free space before building
		# 1 GB = 1024^2 = 1048576
		if (( $free_space < 1048576 ))
		then
			echo "ENOSPACE, aborting..."
			exit 1
		else
		        echo "Building box: $box"
		        packer build ${base_dir}${box}
		        echo "Cleaning cache folder"
		        rm packer_cache/*.iso
		fi
	fi
done

#!/bin/bash
#
show_help () {
  cat << EOFhelp
    Script to build packer boxes automagically.
EOFhelp
}

# Where to find the .json files
base_dir='../../'
json_dir="${base_dir}json/"
build_dir="${base_dir}build/"
output_dir="/home/bjanssens/output/"

# Get all the files
available_boxes=$( ls -1 ${json_dir} )

# Create tree for boxes
create_tree () {
  box_dir=$1
  # Create the output directory
  if [[ ! -d "${output_dir}" ]]
  then
    mkdir -p ${output_dir}
  fi
  # Create the boxname dir
  if [[ ! -d "${output_dir}${box_dir}" ]]
  then
    mkdir ${output_dir}${box_dir}
  fi
  # Create the boxes dir
  if [[ ! -d "${output_dir}${box_dir}/boxes" ]]
  then
    mkdir ${output_dir}${box_dir}/boxes
  fi
}

# Main loop
# Version is based on days
version=$( date +%y-%m-%d )
for box in $available_boxes
do
	# If headless is set to false, don't build the box
	headless=$( cat ${json_dir}${box} | grep headless | cut -d ':' -f 2 | sed 's/,$//g' )
  # Get the name of the box
  boxname=$( echo "$box" | sed 's/.json$//g' )
	if $headless
	then
		# Get the free space in the home mount point via df
		# Returns the free space in Bytes
		free_space=$( df . | tail -n 1 | awk '{ print $4 }' )
		# Make sure that there is at least 1 GB free space before building
		# 1 GB = 1024^2 = 1048576
		if (( $free_space < 1048576 ))
		then
			echo "ENOSPACE, aborting..."
			exit 1
		else
		        echo "Building box: $box"
		        echo "packer build ${json_dir}${box}"
            touch ${build_dir}${boxname}.box
            # If the build was successfull
            # move the box to the correct dir
            create_tree $boxname
            mv ${build_dir}${boxname}.box ${output_dir}${boxname}/boxes/${boxname}-${version}.box
            ./build-json.py -b ${boxname} -d -o ${output_dir}
		        echo "Cleaning cache folder"
		        rm packer_cache/*.iso
		fi
	fi
done

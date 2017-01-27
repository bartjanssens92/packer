#!/bin/bash
#
show_help () {
  cat << EOFhelp
    Script to build packer boxes automagically.

    Options:

    -o | --outputdir: Where to build the directory structure.
    -b | --basedir:   Where the root of the packer repo is.
    -d | --debug:     Echo some more values

EOFhelp
}

# Where to find the .json files
check_params () {
  echo "checking params"
  if [[ -z $base_dir ]]; then base_dir='./'; fi
  if [[ -z $script_dir ]]; then script_dir='./scripts/boxes/'; fi
  if [[ -z $debug ]]; then debug=false; fi
  if [[ -z $output_dir ]]; then quit 'Error: Must specify output directory' '3'; fi
  if [[ "${output_dir: -1}" != '/' ]]; then output_dir=$( echo "$output_dir/" ); fi
  if [[ "${script_dir: -1}" != '/' ]]; then script_dir=$( echo "$script_dir/" ); fi
  json_dir="${base_dir}json/"
  build_dir="${base_dir}build/"
  # Check if the output_dir exists,
  # otherwise make it.
  if [[ ! -d $output_dir ]]; then mkdir -p $output_dir; fi
}

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

getcliargs () {
  while test -n "$1"
  do
    case "$1" in
      --outputdir|-o)
        shift
        output_dir=$1
        shift
        ;;
      --basedir|-b)
        shift
        base_dir=$1
        shift
        ;;
      --scriptdir|-s)
        shift
        script_dir=$1
        shift
        ;;
      --debug|-d)
        debug=true
        shift
        ;;
      *)
        show_help
        exit 1
    esac
  done
}

# Main loop
# Get the cli options
getcliargs $@
check_params

# Get all the files
available_boxes=$( ls -1 ${json_dir} )

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
		free_space=$( df ${output_dir} | tail -n 1 | awk '{ print $4 }' )
		# Make sure that there is at least 1 GB free space before building
		# 1 GB = 1024^2 = 1048576
		if (( $free_space < 1048576 ))
		then
			echo "ENOSPACE, aborting..."
			exit 1
		else
		        echo "Building box: $box"
		        packer build ${json_dir}${box}
            # If the build was successfull
            # move the box to the correct dir
            create_tree $boxname
            # Move the box to the tree
            echo "Moving box to the tree:"
            echo "mv ${build_dir}${boxname}.box ${output_dir}/${boxname}/boxes/${boxname}-${version}.box"
            mv ${build_dir}${boxname}.box ${output_dir}/${boxname}/boxes/${boxname}-${version}.box
            # Generate the metadata
            echo "Createing metadata for ${boxname} located in ${output_dir}"
            if $debug
            then
              echo "${script_dir}build-json.py -b ${boxname} -d -o ${output_dir}"
              ${script_dir}build-json.py -b ${boxname} -d -o ${output_dir}
            else
              ${script_dir}build-json.py -b ${boxname} -o ${output_dir}
            fi
		        echo "Cleaning cache folder"
		        rm packer_cache/*.iso
		fi
	fi
done

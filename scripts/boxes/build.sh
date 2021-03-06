#!/bin/bash
#
show_help () {
  cat << EOFhelp
    Script to build packer boxes automagically.

    Options:

    -o | --outputdir: Where to build the directory structure.
    -b | --basedir:   Where the root of the packer repo is.
    -d | --debug:     Echo some more values.
    -t | --test:      Don't build boxes but touch files.

EOFhelp
}

# Where to find the .json files
check_params () {
  echo "checking params"
  if [[ -z $base_dir ]]; then base_dir='./'; fi
  if [[ -z $base_url ]]; then base_url='https://boxes.bbqnetwork.be'; fi
  if [[ -z $script_dir ]]; then script_dir='./scripts/boxes/'; fi
  if [[ -z $log_dir ]]; then log_dir='./log'; fi
  if [[ -z $set_debug ]]; then set_debug=false; fi
  if [[ -z $cache_cleanup ]]; then cache_cleanup=false; fi
  if [[ -z $set_test ]]; then set_test=false; cachecleanup=false; fi
  if [[ -z $output_dir ]]; then quit 'Error: Must specify output directory' '3'; fi
  if [[ "${output_dir: -1}" != '/' ]]; then output_dir=$( echo "$output_dir/" ); fi
  if [[ "${script_dir: -1}" != '/' ]]; then script_dir=$( echo "$script_dir/" ); fi
  if [[ "${log_dir: -1}" != '/' ]]; then log_dir=$( echo "$log_dir/" ); fi
  json_dir="${base_dir}json/"
  build_dir="${base_dir}build/"
  tempfile='/tmp/buildboxes'
  date_format=$( date +%d-%m-%y )
  log_suffix="$date_format.log"
  # Check if the output_dir exists,
  # otherwise make it.
  if [[ ! -d $output_dir ]]; then echo "Creating output directory: $output_dir"; mkdir -p $output_dir; fi
  # Check the log_dir
  if [[ ! -d $log_dir ]]; then echo "Creating log directory: $log_dir"; mkdir -p $log_dir; fi
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
      --test|-t)
        set_test=true
        shift
        ;;
      --debug|-d)
        debug=true
        shift
        ;;
      --cachecleanup)
        cache_cleanup=true
        shift
        ;;
      *)
        show_help
        exit 1
    esac
  done
}

# Debug function
debug () {
  if $set_debug; then
    echo $@
  fi
}

# Quit function
quit () {
  echo "$1" && exit $2
}

# Main loop
# Get the cli options
getcliargs $@
check_params

# Get all the files
available_boxes=$( ls -1 ${json_dir} )

# Clean out the tmpfile
if [ -f $tempfile ]; then
  echo '' > $tempfile
fi

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
      # Start the box building
      echo "Building box: $box"
      if ! $set_test
      then
        if $set_debug
        then
          #echo "packer build ${json_dir}${box}" | tee -a ${log_dir}${boxname}
          packer build ${json_dir}${box} | tee -a ${log_dir}${boxname}${log_suffix}
          echo "$boxname" >> $tempfile
        else
          #echo "packer build ${json_dir}${box}" &> ${log_dir}${boxname}
          packer build ${json_dir}${box} &> ${log_dir}${boxname}${log_suffix}
          echo "$boxname" >> $tempfile
        fi
      else
        # Debuging
        echo "packer build ${json_dir}${box}" &> ${log_dir}${boxname}${log_suffix}
        touch "${build_dir}${boxname}.box"
        echo "$boxname" >> $tempfile
      fi
      # If the build was successfull
      # move the box to the correct dir
      create_tree $boxname
      # Move the box to the tree
      echo "Moving box to the tree:"
      debug "mv ${build_dir}${boxname}.box ${output_dir}/${boxname}/boxes/${boxname}-${version}.box"
      mv ${build_dir}${boxname}.box ${output_dir}/${boxname}/boxes/${boxname}-${version}.box
      # Generate the metadata
      echo "Createing metadata for ${boxname} located in ${output_dir}"
      if $set_debug
      then
        debug "${script_dir}build-json.py -b ${boxname} -d -o ${output_dir}"
        ${script_dir}build-json.py -b ${boxname} -d -o ${output_dir} | tee -a ${log_dir}${boxname}${log_suffix}
      else
        ${script_dir}build-json.py -b ${boxname} -o ${output_dir} &>> ${log_dir}${boxname}${log_suffix}
      fi
      if $cache_cleanup
      then
        debug "Cleaning cache folder"
        rm packer_cache/*.iso
      fi
    fi
  fi
done

# Build the index box list
# Clear the current indexfile
if [[ -f $output_dir/index.html ]]
then
  echo '' > ${output_dir}/index.html
fi

# Add the top to it
cat ${base_dir}/html/index-top.html > ${output_dir}/index.html

# Add the entries
preurl="${base_url}/"
posturl=" </a> </li>"
for box in $( cat $tempfile )
do
  echo "<li> <a href=\"${preurl}${box}\"> ${box}${posturl}" >> ${output_dir}/index.html
done

# Add the bottom
cat ${base_dir}/html/index-bottom.html >> ${output_dir}/index.html

# Make the logs available
# make the log dir
if [[ ! -d ${output_dir}buildlogs ]]
then
  mkdir ${output_dir}buildlogs
fi

# Move the log files to the log dir
cp ${log_dir}*.log ${output_dir}buildlogs/

# Clean up the tmpfile
rm $tempfile

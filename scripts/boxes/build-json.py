#!/usr/bin/python
# An entry looks like this:
#{
#    "name": "arch-amd64-virtualbox",
#    "description": "This box contains Archlinux 64-bit.",
#    "versions": [{
#        "version": "0.1.0",
#        "providers": [{
#                "name": "virtualbox",
#                "url": "http://boxes.bbqnetwork.be/arch-amd64-virtualbox/boxes/arch-amd64-virtualbox.box",
#                "checksum_type": "sha1",
#                "checksum": "85c9cdd316564f942ceee0d3a41cd00d8fe44c4a"
#        }]
#    }]
#}
# Import json module for reading and parsing the file
import json
# Import time module for getting the date
import time
# Import hashlib for calculating the sha1 of the box
import hashlib
# Import os for some checking an moving files
import os
# Import sys and getopts for option passing
import getopt, sys

# Functions
def usage():
    print("Script to build the json metadata file")

def debug(message):
    if ( setdebug ):
        print("DEBUG: " + message)

# Function to generate the basic metadata stucture
def createbasefile(metadatafile,boxname):
    # Create the base setup
    newmetadata = {"name": boxname, "description": "Description goes here", "versions":[]}
    # Create the json object
    newmetadatacontent = json.dumps(newmetadata, indent=2)
    # Create the file, add the content and save it.
    with open(metadatafile, 'w+') as newmetadatafile:
        newmetadatafile.write(newmetadatacontent)
    newmetadatafile.closed

# Function to generate the json needed to define a new version of a box
def addbox(boxname,urlbase,metadatacontent,metadatafile,outputdir):
    # Version is date reversed: YY.MM.DD
    version = time.strftime("%y.%m.%d")
    debug("version: " + version)
    # Build the location of the box
    location = "/" + boxname[:-4] + "/boxes/" + boxname[:-4] + "-" + version.replace(".", "-") + ".box"
    # Generate the sha1 of the box
    debug('Generating sha1 sum')
    sha1box = sha1sum(outputdir + '/' + location)
    debug("sha1: " + sha1box)
    # Build the url
    # https://boxes.bbqnetwork.be / arch-amd64-virtualbox /boxes/ arch-amd64-virtualbox - 17-01-17 .box
    url = urlbase + location
    debug("url: " + url)
    # Build the new version
    newbox = {"version": version, "providers": [{"name": "virtualbox", "url": url, "checksum_type": "sha1", "checksum": sha1box}]}
    # Append the new box the the other versions
    metadatacontent['versions'].append(newbox)
    # Write the content to the file
    with open(metadatafile, 'w+') as newmetadatafile:
        newmetadatafile.write(json.dumps(metadatacontent, indent=2))
    newmetadatafile.closed

# Function to calculate the sha1 of a file
def sha1sum(file):
    blocksize = 4096
    with open(file, 'rb') as file:
        sha1 = hashlib.sha1()
        buffer = file.read(blocksize)
        while len(buffer) > 0:
          sha1.update(buffer)
          buffer = file.read(blocksize)
    file.closed
    return sha1.hexdigest()


def main():
    # Make setdebug global
    global setdebug
    # Parse params
    try:
        opts, args = getopt.getopt(sys.argv[1:], "u:b:o:vdh", ["help", "verbose", "debug", "url=", "box=", "output="])
    except getopt.GetoptError as err:
        print(str(err))
        usage()
        sys.exit(2)
    # Defaults
    metadatafile = './empty.json'
    urlbase = "https://boxes.bbqnetwork.be"
    outputdir = "."
    setdebug = False
    # Check if options where passed
    if len(opts) == 0:
        usage()
        sys.exit(2)
    # Loop through the options
    for option, argument in opts:
        if option in ("-v", "-d", "--debug", "--verbose"):
            setdebug = True
            debug("debug: " + str(setdebug))
        elif option in ("-h", "--help"):
            usage()
        elif option in ("-u", "--url"):
            urlbase = argument
        elif option in ("-b", "--box"):
            metadatafile = argument
        elif option in ("-o", "--output"):
            outputdir = argument
        else:
            # If there are no more arguments left,
            # do the main thing
            usage()
    debug("Doing the main thing")
    createmetadata(metadatafile, urlbase,outputdir)
    sys.exit(0)

def createmetadata(metadatafile,urlbase,outputdir):
    # Build the full file path
    fullpathmetadatafile =  outputdir + '/' + metadatafile + '/' + metadatafile + '.json'
    # Derive the boxname from the metadatafile name
    boxnamefrommetadatafile = metadatafile
    # Check if the file exists
    if not (os.path.isfile(fullpathmetadatafile)):
        debug('Creating new metadatafile: ' + fullpathmetadatafile)
        createbasefile(fullpathmetadatafile,boxnamefrommetadatafile)

    debug("Loading json from: " + fullpathmetadatafile)
    # Start by opening the file
    with open(fullpathmetadatafile, 'r') as file:
        metadatacontent = json.load(file)
    file.closed

    # Assume that the name is also the name of the box
    boxname = metadatacontent['name'] + '.box'
    debug("boxname: " + boxname)

    # Check the amount of versions
    if ( len(metadatacontent['versions']) == 2 ):
        # Move the second element to the first
        toremove = metadatacontent['versions'][0]['version']
        debug('box to remove: ' + toremove)
        metadatacontent['versions'][0] = metadatacontent['versions'][1]
        # Remove the last element
        metadatacontent['versions'].pop()
        # Add a new box to the array
        addbox(boxname,urlbase,metadatacontent,fullpathmetadatafile,outputdir)
    else:
        # Add a new box to the array
        addbox(boxname,urlbase,metadatacontent,fullpathmetadatafile,outputdir)

    # Print the result pretty
    debug("Pretty print: ")
    debug(json.dumps(metadatacontent, indent=2))

if __name__ == '__main__':
  main()

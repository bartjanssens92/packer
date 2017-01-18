#!/usr/bin/python
# Script to build the json metadata file
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

# Functions
def debug(message):
    if ( setdebug ):
        print("DEBUG: " + message)

# Function to generate the basic metadata stucture
def createbasefile():
    # Create the base setup
    newmetadata = {"name": metadatafile[:-5].replace("./", ""), "description": "Description goes here", "versions":[]}
    # Create the json object
    newmetadatacontent = json.dumps(newmetadata, indent=2)
    # Create the file, add the content and save it.
    with open(metadatafile, 'w+') as newmetadatafile:
        newmetadatafile.write(newmetadatacontent)
    newmetadatafile.closed

# Function to generate the json needed to define a new version of a box
def addbox():
    # Version is date reversed: YY.MM.DD
    version = time.strftime("%y.%m.%d")
    debug("version: " + version)
    # Generate the sha1 of the box
    debug('Generating sha1 sum')
    sha1box = sha1sum(boxname)
    debug("sha1: " + sha1box)
    # Build the url
    # https://boxes.bbqnetwork.be / arch-amd64-virtualbox /boxes/ arch-amd64-virtualbox - 17-01-17 .box
    url = urlbase + "/" + boxname[:-4] + "/boxes/" + boxname[:-4] + "-" + version.replace(".", "-") + ".box"
    debug("url: " + url)
    # Build the new version
    newbox = {"version": version, "providers": [{"name": "virtualbox", "url": url, "checksum_type": "sha1", "checksum": sha1box}]}
    # Append the new box the the other versions
    metadatacontent['versions'].append(newbox)

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

# TODO: make it possilble to pass params to this script!
metadatafile = './centos-7.1-amd64-virtualbox.json'
urlbase = "https://boxes.bbqnetwork.be"

setdebug = True
debug("debug: " + str(setdebug))

# Check if the file exists
if not (os.path.isfile(metadatafile)):
    debug("file, '" + metadatafile + "' does not exist!")
    createbasefile()

# Start by opening the file
with open(metadatafile, 'r') as file:
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
    addbox()
else:
    # Add a new box to the array
    addbox()

# Print the result pretty
debug("Pretty print: ")
print(json.dumps(metadatacontent, indent=2))

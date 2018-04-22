#!/bin/sh

#  CreateImageScript.command
#  DisplayDrives
#
#  Created by Jake Fry on 4/6/18.
#  Copyright © 2018 Jake Fry. All rights reserved.
echo "*********************************"
echo "Creating encrypted disk image..."
echo "*********************************"

#let path = "/usr/bin/hdiutil"
#let arguments = ["create", "-srcfolder", "\(sourcePath)", "-encryption", "-stdinpass", "\(targetPath)/test.dmg", "-ov"]

DEVICE=$(diskutil info "${2}" | grep 'Device Node:' | cut -d ' ' -f 19)
echo "Device Node:"
echo "$DEVICE"
#/bin/echo -n "${1}" | /usr/bin/hdiutil create -encryption -stdinpass -srcfolder "${2}" "${3}" -ov -verbose
/bin/echo -n "${1}" | /usr/bin/hdiutil create -encryption -stdinpass -srcdevice "$DEVICE" "${3}" -ov -verbose

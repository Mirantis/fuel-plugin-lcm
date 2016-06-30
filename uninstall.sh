#!/bin/bash
echo "Removing LCM Plugin - $(grep ^version: metadata.yaml | grep -Eo '([0-9]+\.)*[0-9]+')"

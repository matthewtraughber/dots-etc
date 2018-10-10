#!/usr/bin/env bash

# This parses a csv and downloads all urls in the 1st column (sanitized into 2nd column)
# previously used with [Linkclump Chrome extension](https://chrome.google.com/webstore/detail/linkclump/lfpjkncokllnfokkgpkobnkbkmelfefj?hl=en)
# usage - ./csv_bulk-url_download.sh file.csv

filename="$1"
while IFS="," read -r f1
do
	f2=tr -d '\r' $f1
	wget "$f2"
done < "$filename"

[AppleScript]
tell application "Spotify"
	set theTrack to name of the current track
	set theArtist to artist of the current track
	set theAlbum to album of the current track
	set track_id to id of current track
end tell

set AppleScript's text item delimiters to ":"
set track_id to third text item of track_id
set AppleScript's text item delimiters to {""}
set realurl to ("http://open.spotify.com/track/" & track_id)

set theString to theTrack & " - " & theArtist & ": " & realurl
set the clipboard to theString
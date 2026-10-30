git clone git@github.com:AliReza99/mpv-config.git ~/.config/mpv

Persian subtitles use the Vazirmatn font:

sudo apt install fonts-vazirmatn

Subtitles from the video's folder are loaded automatically (scripts/autosub-match.lua):
episodes match by season/episode (S01E01, 1x01, 1-Title, E01, ...), movies get every sub
in the folder. Order: exact name, .edited, Persian, rest. Ctrl+O picks a subtitle file by hand.

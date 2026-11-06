# dmgbuild settings for the Quick Styles disk image. Run through
# scripts/dmg.sh, which sets APP_PATH and BACKGROUND_PATH.
import os

application = os.environ["APP_PATH"]
appname = os.path.basename(application)

format = "UDZO"
size = None
files = [application]
symlinks = {"Applications": "/Applications"}
background = os.environ["BACKGROUND_PATH"]
icon_locations = {appname: (140, 160), "Applications": (400, 160)}
window_rect = ((200, 120), (540, 340))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 0
icon_size = 112
text_size = 13
arrange_by = None
show_icon_preview = False

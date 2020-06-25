# File: ascii-esc.sh 
#
# to be sourced
# ascii escape sequences
#
# https://misc.flogisoft.com/bash/tip_colors_and_formatting


AESC_RST_ALL="\e[0m"

# not working, always became underlined
AESC_SET_BOLD="\e[1m"
# unbold not always supoorted, became double underlined in other caseasc 
#AESC_RST_BOLD="\e[21m"  
AESC_SET_D_UNDERLINED="\e[21m"  

AESC_SET_DIM="\e[2m"
AESC_SET_NORM="\e[22m"

AESC_SET_UNDERLINED="\e[4m"
AESC_RST_UNDERLINED="\e[24m"

AESC_SET_BLINK="\e[5m"
AESC_RST_BLINK="\e[25m"

AESC_SET_REVERSE="\e[7m"
AESC_RST_REVERSE="\e[27m"

# default foreground color
AESC_COLOR_RST_FG="\e[39m"
AESC_COLOR_RST_BG="\e[49m"
AESC_COLOR_DEFAULT="${AESC_COLOR_RST_FG}"

AESC_COLOR_RED="\e[31m"
AESC_COLOR_GREEN="\e[32m"
AESC_COLOR_YELLOW="\e[33m"
AESC_COLOR_BLUE="\e[34m"
AESC_COLOR_MAGENTA="\e[35m"
AESC_COLOR_CYAN="\e[36m"
AESC_COLOR_L_GREY="\e[37m"

AESC_COLOR_D_GREY="\e[90m"
AESC_COLOR_L_RED="\e[91m"
AESC_COLOR_L_GREEN="\e[92m"
AESC_COLOR_L_YELLOW="\e[93m"
AESC_COLOR_L_BLUE="\e[94m"
AESC_COLOR_L_MAGENTA="\e[95m"
AESC_COLOR_L_CYAN="\e[96m"
AESC_COLOR_WHITE="\e[97m"



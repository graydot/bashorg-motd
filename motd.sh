#!/bin/bash

# MOTD Script for Bash.org IRC Quotes
# Downloads and displays random quotes from GitLab repository

QUOTES_DIR="$HOME/.cache/bashorg-quotes"
QUOTES_TSV_FILE="$QUOTES_DIR/compiled.tsv"
LAST_USED_FILE="$QUOTES_DIR/last_used.txt"
GITLAB_TSV_URL="https://gitlab.com/dwrodri/bash_irc_quotes/-/raw/master/compiled.tsv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create cache directory if it doesn't exist
mkdir -p "$QUOTES_DIR"

# Function to draw progress bar
draw_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}["
    printf "%*s" "$completed" | tr ' ' '='
    if [ "$completed" -lt "$width" ]; then
        printf ">"
        printf "%*s" "$((remaining - 1))" | tr ' ' '-'
    fi
    printf "] %d%% (%d/%d)${NC}" "$percentage" "$current" "$total"
}

# Function to download TSV file
download_quotes_tsv() {
    echo "Downloading quotes TSV file..."
    
    curl -s "$GITLAB_TSV_URL" > "$QUOTES_TSV_FILE"
    
    if [ ! -s "$QUOTES_TSV_FILE" ]; then
        echo "Failed to download quotes TSV file."
        return 1
    fi
    
    local total_quotes=$(wc -l < "$QUOTES_TSV_FILE")
    echo -e "${GREEN}✓ Downloaded $total_quotes quotes!${NC}"
}

# Function to get total number of quotes
get_total_quotes() {
    wc -l < "$QUOTES_TSV_FILE"
}

# Function to get next quote using weighted distribution
get_next_quote_line() {
    local total_quotes=$(get_total_quotes)
    
    # Initialize or read last used index
    if [ ! -f "$LAST_USED_FILE" ]; then
        echo "0" > "$LAST_USED_FILE"
    fi
    
    local last_used=$(cat "$LAST_USED_FILE")
    local next_index=$(( (last_used + 1) % total_quotes ))
    
    # If we've cycled through all quotes, shuffle the file
    if [ "$next_index" -eq 0 ] && [ "$last_used" -gt 0 ]; then
        echo "Shuffling quotes for better distribution..."
        shuf "$QUOTES_TSV_FILE" -o "$QUOTES_TSV_FILE"
    fi
    
    echo "$next_index" > "$LAST_USED_FILE"
    
    # Get the quote line
    sed -n "$((next_index + 1))p" "$QUOTES_TSV_FILE"
}

# Function to display a quote from TSV line
display_quote() {
    local quote_line="$1"
    
    # Parse TSV line: ID, Score, Quote
    local quote_id=$(echo "$quote_line" | cut -f1)
    local quote_score=$(echo "$quote_line" | cut -f2)
    local quote_content=$(echo "$quote_line" | cut -f3 | sed 's/\\n/\n/g')
    
    # Create header with ID and score
    local quote_header="Quote #$quote_id (Score: $quote_score)"
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${YELLOW}  Quote of the Day - bash.org IRC Quotes${CYAN}                                         │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${BLUE}  $quote_header${CYAN}$(printf "%*s" $((76 - ${#quote_header})) "")   │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${NC}"
    
    # Word wrap the quote content (handle existing newlines and long lines)
    echo "$quote_content" | while IFS= read -r line; do
        if [ -z "$line" ]; then
            echo -e "${CYAN}│${GREEN}$(printf "%*s" 79 "")│${NC}"
        else
            echo "$line" | fold -s -w 74 | while IFS= read -r wrapped_line; do
                local display_width=${#wrapped_line}
                local padding=$((79 - display_width))
                echo -e "${CYAN}│${GREEN}  $wrapped_line${CYAN}$(printf "%*s" $padding "")│${NC}"
            done
        fi
    done
    
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────────────────────╯${NC}"
    
    # Show total quotes and next quote instruction
    local total_quotes=$(get_total_quotes)
    echo -e "${CYAN}Total quotes: ${YELLOW}$total_quotes${CYAN} | Use ${YELLOW}'wut'${CYAN} for next quote${NC}"
}

# Function to update quotes cache
update_quotes() {
    echo "Updating quotes cache..."
    rm -f "$QUOTES_TSV_FILE"
    download_quotes_tsv
    echo "Quotes cache updated!"
}

# Main function
main() {
    case "$1" in
        "update")
            update_quotes
            ;;
        "help")
            echo "Usage: $0 [update|help]"
            echo "  update: Update the quotes cache"
            echo "  help:   Show this help message"
            echo "  (no args): Display a random quote"
            echo "  wut:    Show next quote (alias for no args)"
            ;;
        "wut"|*)
            # Start timing
            local start_time=$(python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo $(($(date +%s) * 1000)))
            
            # Check if quotes TSV exists
            if [ ! -f "$QUOTES_TSV_FILE" ]; then
                echo "First run detected. Downloading quotes..."
                download_quotes_tsv
            fi
            
            # Get and display a quote
            quote_line=$(get_next_quote_line)
            if [ -n "$quote_line" ]; then
                display_quote "$quote_line"
                
                # Calculate and display timing
                local end_time=$(python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo $(($(date +%s) * 1000)))
                local elapsed=$((end_time - start_time))
                echo -e "${CYAN}Displayed in ${elapsed}ms${NC}"
            else
                echo "No quotes available. Try running: $0 update"
            fi
            ;;
    esac
}

main "$@"
#!/bin/bash

# MOTD Script for Bash.org IRC Quotes
# Downloads and displays random quotes from GitLab repository

QUOTES_DIR="$HOME/.cache/bashorg-quotes"
QUOTES_LIST_FILE="$QUOTES_DIR/quotes_list.txt"
LAST_USED_FILE="$QUOTES_DIR/last_used.txt"
GITLAB_API_URL="https://gitlab.com/api/v4/projects/dwrodri%2Fbash_irc_quotes/repository/tree?path=cleaned&ref=master&per_page=200"
GITLAB_RAW_URL="https://gitlab.com/dwrodri/bash_irc_quotes/-/raw/master/cleaned"

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

# Function to download quote file list
download_quotes_list() {
    echo "Downloading quotes list..."
    
    # Clear existing list
    > "$QUOTES_LIST_FILE"
    
    # Get total pages from first request
    local first_page_response=$(curl -s -I "$GITLAB_API_URL")
    local total_pages=$(echo "$first_page_response" | grep -i "x-total-pages" | sed 's/.*: //' | tr -d '\r')
    
    if [ -z "$total_pages" ]; then
        echo "Could not determine total pages, trying single page..."
        total_pages=1
    fi
    
    echo "Found $total_pages pages of quotes..."
    
    # Download all pages with progress bar
    for page in $(seq 1 "$total_pages"); do
        draw_progress_bar "$page" "$total_pages"
        curl -s "${GITLAB_API_URL}&page=${page}" | grep -o '"name":"[^"]*\.txt"' | sed 's/"name":"//g' | sed 's/"//g' >> "$QUOTES_LIST_FILE"
        
        # Shuffle after each page to ensure randomness even if interrupted
        if [ -s "$QUOTES_LIST_FILE" ]; then
            shuf "$QUOTES_LIST_FILE" -o "$QUOTES_LIST_FILE"
        fi
    done
    
    # Clear progress bar and show completion
    printf "\r%*s\r" 80 ""
    local total_quotes=$(wc -l < "$QUOTES_LIST_FILE")
    echo -e "${GREEN}✓ Downloaded $total_quotes quotes!${NC}"
    
    if [ ! -s "$QUOTES_LIST_FILE" ]; then
        echo "Failed to download quotes list. Using fallback method..."
        # Fallback: generate common quote numbers
        for i in {1..10000}; do
            echo "${i}.txt" >> "$QUOTES_LIST_FILE"
        done
    fi
}

# Function to get total number of quotes
get_total_quotes() {
    wc -l < "$QUOTES_LIST_FILE"
}

# Function to get next quote using weighted distribution
get_next_quote_file() {
    local total_quotes=$(get_total_quotes)
    
    # Initialize or read last used index
    if [ ! -f "$LAST_USED_FILE" ]; then
        echo "0" > "$LAST_USED_FILE"
    fi
    
    local last_used=$(cat "$LAST_USED_FILE")
    local next_index=$(( (last_used + 1) % total_quotes ))
    
    # If we've cycled through all quotes, shuffle the list
    if [ "$next_index" -eq 0 ] && [ "$last_used" -gt 0 ]; then
        echo "Shuffling quotes for better distribution..."
        shuf "$QUOTES_LIST_FILE" -o "$QUOTES_LIST_FILE"
    fi
    
    echo "$next_index" > "$LAST_USED_FILE"
    
    # Get the quote file name
    sed -n "$((next_index + 1))p" "$QUOTES_LIST_FILE"
}

# Function to download and display a quote
display_quote() {
    local quote_file="$1"
    local quote_path="$QUOTES_DIR/$quote_file"
    
    # Download quote if not cached or older than 1 day
    if [ ! -f "$quote_path" ] || [ "$(find "$quote_path" -mtime +1 2>/dev/null)" ]; then
        curl -s "$GITLAB_RAW_URL/$quote_file" > "$quote_path"
        
        # Check if download was successful
        if [ ! -s "$quote_path" ]; then
            echo "Failed to download quote: $quote_file"
            return 1
        fi
    fi
    
    # Parse and display the quote
    local quote_header=$(head -n 1 "$quote_path")
    local quote_content=$(tail -n +2 "$quote_path")
    
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${YELLOW}  Quote of the Day - bash.org IRC Quotes${CYAN}                                    │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${BLUE}  $quote_header${CYAN}$(printf "%*s" $((75 - ${#quote_header})) "")│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${NC}"
    
    # Word wrap the quote content
    echo "$quote_content" | fold -s -w 75 | while IFS= read -r line; do
        echo -e "${CYAN}│${GREEN}  $line${CYAN}$(printf "%*s" $((75 - ${#line})) "")│${NC}"
    done
    
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────────────────────╯${NC}"
    
    # Show total quotes and next quote instruction
    local total_quotes=$(get_total_quotes)
    echo -e "${CYAN}Total quotes: ${YELLOW}$total_quotes${CYAN} | Use ${YELLOW}'wut'${CYAN} for next quote${NC}"
}

# Function to update quotes cache
update_quotes() {
    echo "Updating quotes cache..."
    rm -f "$QUOTES_LIST_FILE"
    download_quotes_list
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
            
            # Check if quotes list exists
            if [ ! -f "$QUOTES_LIST_FILE" ]; then
                echo "First run detected. Downloading quotes..."
                download_quotes_list
            fi
            
            # Get and display a quote
            quote_file=$(get_next_quote_file)
            if [ -n "$quote_file" ]; then
                display_quote "$quote_file"
                
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
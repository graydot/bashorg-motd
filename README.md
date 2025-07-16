# Bash.org MOTD Script

This is a quick hack I put together with Claude + Cursor. If you're familiar with IRC, you know what bash.org was - this is my homage to that legendary site. 

Fair warning: this is peak 2000s "sysadmin bro" humor, so if that's not your vibe, you might want to skip this one. Consider it internet archaeology - a digital time capsule of times past.

*Disclaimer: All quote content is from the original bash.org archives - please don't get mad at me. For the uninitiated: bash.org was the internet's repository of IRC chat logs, capturing the absurd, crude, and very occasionally brilliant conversations that defined early internet culture.*

## Features

- 🎲 **10,700+ quotes** from the legendary bash.org archives
- 🎨 **Beautiful terminal formatting** with progress bars and colors  
- 🔄 **Smart distribution** - cycles through all quotes before repeating
- ⚡ **Lightning fast** - cached locally with timing display
- 🎯 **Random but fair** - shuffles after each complete cycle
- 🛠️ **Easy setup** - one command installation

## Quick Start

```bash
git clone <this-repo>
cd bashorg-motd
./setup.sh
```

That's it! Open a new terminal and you'll see a quote. Use `wut` anytime for the next quote.

## Commands

### 🎯 Main Commands
- **`wut`** - Show next quote (works from anywhere after setup)
- **`./motd.sh`** - Show next quote (local)
- **`./motd.sh update`** - Download fresh quotes from bash.org archives

### 🛠️ Setup Commands
- **`./setup.sh`** - Install everything (detects your shell automatically)
- **`./setup.sh uninstall`** - Remove from your shell startup
- **`./setup.sh status`** - Check current configuration
- **`./setup.sh test`** - Preview a quote without installing

### 📊 What You'll See
```
╭─────────────────────────────────────────────────────────────────────────────────╮
│  Quote of the Day - bash.org IRC Quotes                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│  #100798 +(1439)- [X]                                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│  <mike> HEH, THIs Is AMuSINg                                                   │
│  <mike> I Got a WiNAMP pLUgiN THAt BLInKS THE KEYboARD ledS tO THE MUSIc       │
│  <mike> BUT IT acTUALLY turNs THe CAPsLOcK On AND oFF iNSTEad OF JuST the      │
│  LIGHt                                                                         │
╰─────────────────────────────────────────────────────────────────────────────────╯
Total quotes: 10700 | Use 'wut' for next quote
Displayed in 234ms
```

### 🎭 More Classic Examples

**The Savage Comeback:**
```
#16291 +(199)- [X]
<Zimbu> i was just using common sense, sorry
<Gimik\HMWRK> Zimbu: try to use something you have next time ;)
```

**The Apartment Hunters:**
```
#102752 +(47)- [X]
<mufffin> i could live there
<mufffin> except its an apartment
<Schlurbna> That's not to say I wouldn't live there but I expect more from penthouse apartments.
<hoek_> Schlurbna - you expect penthouse models in there?
```

## How It Works

**First run**: Downloads 10,700+ quote filenames from GitLab (with a sweet progress bar!)  
**Smart cycling**: Goes through all quotes sequentially, then shuffles for the next round  
**Lightning cache**: Quotes stored in `~/.cache/bashorg-quotes/` for instant access  
**Bulletproof**: Even if you Ctrl+C during download, partial quotes are shuffled and ready  

## Manual Setup (If You're Into That)

Add this to your shell config (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
# Bash.org MOTD Quote
if [ -f "/path/to/motd.sh" ]; then
    "/path/to/motd.sh"
fi
export PATH="/path/to/bashorg-motd:$PATH"  # For global 'wut' command
```

## Requirements

- `curl` (for downloading quotes)
- `bash` (for running the script)
- Internet connection (first run only)
- A sense of humor circa 2003

## Credits

Quotes sourced from: https://gitlab.com/dwrodri/bash_irc_quotes/  
Original bash.org: RIP to a real one 🫡
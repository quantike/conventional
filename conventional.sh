#!/usr/bin/env bash

VERBOSE=false 

# Logs conventional outputs
log() {
    if [ "$VERBOSE" = true ]; then 
        echo "$@"
    fi
}

# Validates if the given commit type is conventional
_git_conventional_valid_type() {
    local type="$1"
    case "$type" in 
        build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test|wip) return 0 ;;
        *) return 1 ;;
    esac
}

# Resets all git-commit-conventional configurations 
_git_conventional_reset() {
    git config --local --remove-section git-commit-conventional 2>/dev/null || {
        echo "No git-commit-conventional configuration found to reset."
    }
    log "Configuration reset."
    echo "git-commit-conventional configurations have been reset."
}

# Constructs the commit message based on the provided type and options
_git_conventional_get_commit() {
    local type="$1"
    shift 
    local scope breaking_change body_file head body 
    
    scope=$(git config --local --get git-commit-conventional.scope)
    breaking_change=$(git config --local --get git-commit-conventional.breaking-change)
    body_file=$(git config --local --get git-commit-conventional.body-file-path)

    if ! _git_conventional_valid_type "$type"; then
        echo "Error: Invalid commit type '$type'" >&2
        exit 1
    fi

    head="$type"
    [ -n "$scope" ] && head="$head($scope)"
    [ "$breaking_change" = "true" ] && head="$head!"
    head="$head: $*"

    if [ -n "$body_file" ] && [ -f "$body_file" ]; then 
        body=$(cat "$body_file")
        head="$head\n\n$body"
    fi

    log "Conventional commit constructed: $head"
    printf "%s" "$head"
}

# Sets or unsets the breaking change flag
_git_conventional_set_breaking_change() {
    local breaking_change="${1:-false}"
    case "$breaking_change" in 
        true|on|1)
            git config --local --bool git-commit-conventional.breaking-change true 
            echo "Breaking change set to: true"
            ;;
        faslse|off|0)
            git config --local --unset git-commit-conventional.breaking-change
            echo "Breaking change set to: false"
            ;;
        *)
            echo "Usage: conventional breaking-change [true|false]"
            exit 1
            ;;
    esac
}

# Sets the file path for the commit body
_git_conventional_set_body_file() {
    local file_path="$1"
    if [ -z "$file_path" ]; then
        echo "Usage: conventional body-file [file_path]"
        exit 1
    fi
    if [ -f "$file_path" ]; then
        git config --local --path git-commit-conventional.body-file-path "$file_path" || {
            echo "Error: Failed to set body file path." >&2
            exit 1
        }
        echo "Body file path set to: $file_path"
    else
        echo "Error: File '$file_path' does not exist." >&2
        exit 1
    fi
}

# Sets or unsets the commit scope
_git_conventional_set_scope() {
    local scope="$1"
    if [ -z "$scope" ]; then
        git config --local --unset git-commit-conventional.scope
        log "Scope removed"
    else
        git config --local git-commit-conventional.scope "$scope"
        log "Scope set to $scope"
    fi
}

# Commits using the contructed commit message
_git_conventional_commits() {
    commit_message=$(_git_conventional_get_commit "$@")
    if [ $? -ne 0 ]; then
        echo "Failed to generate commit message."
        exit 1
    fi
    git commit -m "$commit_message"
}

# Checks if there are any WIP commits in the history
_git_conventional_check_for_wip() {
    local wip_count
    wip_count=$(git rev-list --grep='^wip' --count HEAD)
    if [ "$wip_count" -gt 0 ]; then 
        echo "Error: There are $wip_count 'wip' commits. Please squash them before merging." >&2
        exit 1
    else
        echo "No 'wip' commits found."
    fi
}

# Displays the help text
_help() {
    if [ -f "$help_file" ]; then
        cat "$help_file"
    else
        echo "Help file not found."
        echo "Usage: conventional [command] [options]"
        echo "Commands:"
        echo "  build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test|wip - Create a commit with the specified type."
        echo "  scope|s [scope] - Set or unset the commit scope."
        echo "  breaking-change|bc [true|false] - Set or unset the breaking change flag."
        echo "  message|m [type] [description] - Generate and display the commit message."
        echo "  reset - Reset all git-commit-conventional configurations."
        echo "  body-file [file_path] - Set the file path for the commit body."
        echo "  check-wip - Check for WIP commits in the history."
        echo "  help - Display this help message."
    fi
}

# Main function to handle commit operations
conventional() {
    case "$1" in 
        build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test|wip)
            shift 
            _git_conventional_commits "${@:2}"
            ;;
        scope|s)
            shift 
            _git_conventional_set_scope "${@:2}"
            ;;
        breaking-change|bc)
            shift 
            _git_conventional_set_breaking_change "${@:2}"
            ;;
        message|m)
            shift
            _git_conventional_get_commit "${@:2}"
            ;;
        reset)
            _git_conventional_reset
            ;;
        body-file)
            shift
            _git_conventional_set_body_file "$2"
            ;;
        check-wip)
            _git_conventional_check_for_wip
            ;;
        v|--verbose)
            VERBOSE=true
            shift 
            conventional "$@"
            ;;
        help|h|--help)
            _help
            ;;
        *)
            echo "Error: Unknown command '$1'" >&2
            echo ""
            _help
            exit 1
            ;;
    esac
}

# Entry point
conventional "$@"

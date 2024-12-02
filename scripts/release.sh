#!/bin/bash

# Pre requisites:
# - Commitizen (cz)
# - GitHub CLI (gh) (https://github.com/cli/cli)
    # $ brew install gh
# - gum (https://github.com/charmbracelet/gum)
    # $ brew install gum

MAIN_BRANCH="master"

# Check if the current branch is the main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]]; then
    # Log an error if not on the main branch and exit
    gum log --structured --level error "You are not on the '$MAIN_BRANCH' branch. Please switch to '$MAIN_BRANCH' and try again."
    exit 1
fi

# Ask whether to fetch and pull the latest changes
if gum confirm "Do you want to fetch and pull the latest changes from '$MAIN_BRANCH'?"; then
    # Display a spinner while fetching and pulling
    gum spin --spinner dot --title "Fetching and pulling the latest changes..." -- \
        git fetch origin && git pull --rebase origin "$MAIN_BRANCH"
else
    gum log --structured --level info "Skipped fetching and pulling."
fi

# Ask whether to create a new release section
if gum confirm "Do you want to create a new release section?"; then
    # Run Commitizen to bump version (with the `--files-only` flag)
    BUMP_OUTPUT=$(cz bump --files-only 2>&1)

    # Check if the bump process was successful
    if [[ $? -ne 0 ]]; then
        # Extract the second line from BUMP_OUTPUT (remove square brackets and take the second line)
        ERROR_MESSAGE=$(echo "$BUMP_OUTPUT" | sed -n '2p')

        # Log the error message and exit if the bump failed
        gum log --structured --level error "Failed to bump version: $ERROR_MESSAGE"
        exit 1
    fi

    # Get the new version
    NEW_VERSION=$(cz version -p)

    # Log the new version
    gum log --structured --level info "New version: $NEW_VERSION"

    # Ask for the release name (title)
    RELEASE_NAME=$(gum input \
        --prompt "Enter the release name: " \
        --placeholder "Release v$NEW_VERSION")

    # Check if a release name is provided
    if [[ -n "$RELEASE_NAME" ]]; then
        # Push the changes
        git push origin "$MAIN_BRANCH" --follow-tags

        # Create a GitHub release with the specified release name and changelog
        RELEASE_OUTPUT=$(gh release create "$RELEASE_NAME" -F CHANGELOG.md 2>&1)

        # Check if the release creation was successful
        if echo "$RELEASE_OUTPUT" | grep -q "Published releases must have a valid tag"; then
            # Log the error if the tag is missing
            gum log --structured --level error "Failed to create release: Published releases must have a valid tag."
        else
            # Log the success message
            gum log --structured --level info "Release '$RELEASE_NAME' created successfully."
        fi
    else
        # Log the error message if no release name is provided
        gum log --structured --level error "Failed to create release: Release name is required."
    fi
else
    # Log the cancellation message
    gum log --structured --level error "Release creation aborted."
fi

//go:build darwin

package tracker

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
)

// DarwinTracker implements the Tracker interface for macOS.
type DarwinTracker struct{}

// NewTracker creates a new tracker instance for macOS.
func NewTracker() (Tracker, error) {
	return &DarwinTracker{}, nil
}

// GetActivity fetches the current active application and window title on macOS
// using AppleScript.
func (t *DarwinTracker) GetActivity() (ActivityData, error) {
	var data ActivityData
	// This AppleScript gets the frontmost application and its front window's title.
	// It's designed to be simple and robust for v0.
	script := `
		tell application "System Events"
			set frontApp to first application process whose frontmost is true
			if frontApp is not null then
				set appName to name of frontApp
				try
					set windowTitle to name of front window of frontApp
					return appName & "|||" & windowTitle
				on error
					return appName & "|||" & ""
				end try
			else
				return "|||"
			end if
		end tell
	`
	cmd := exec.Command("osascript", "-e", script)
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return data, fmt.Errorf("failed to run applescript: %w, stderr: %s", err, stderr.String())
	}

	parts := strings.Split(strings.TrimSpace(out.String()), "|||")
	if len(parts) == 2 {
		data.AppName = parts[0]
		data.WindowTitle = parts[1]
	}

	return data, nil
}

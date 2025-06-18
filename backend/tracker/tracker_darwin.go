//go:build darwin

package tracker

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// DarwinTracker implements the Tracker interface for macOS.
type DarwinTracker struct {
	powerDetector *PowerStateDetector
	lastActivity  time.Time
}

// NewTracker creates a new tracker instance for macOS.
func NewTracker() (Tracker, error) {
	return &DarwinTracker{
		powerDetector: NewPowerStateDetector(),
		lastActivity:  time.Now(),
	}, nil
}

// GetActivity fetches the current active application and window title on macOS
// using AppleScript, but only when the system is in an active power state.
func (t *DarwinTracker) GetActivity() (ActivityData, error) {
	var data ActivityData

	// Check if we should stop tracking due to power state
	if shouldStop, reason := t.powerDetector.ShouldStopTracking(); shouldStop {
		// Update last activity time to prevent immediate tracking when system wakes
		t.lastActivity = time.Now()
		return data, fmt.Errorf("GetActivity: tracking paused: %s", reason)
	}

	// Update last activity time since we're actively tracking
	t.lastActivity = time.Now()

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

		// Update activity in power detector when we detect user activity
		if data.AppName != "" {
			t.powerDetector.UpdateActivity()
		}
	}

	return data, nil
}

// GetPowerState returns the current power state for debugging/monitoring
func (t *DarwinTracker) GetPowerState() (PowerState, error) {
	return t.powerDetector.GetPowerState()
}

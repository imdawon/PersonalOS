//go:build darwin

package tracker

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// PowerStateDetector handles power state detection on macOS
type PowerStateDetector struct {
	lastIdleCheck time.Time
	lastActivity  time.Time
	idleThreshold time.Duration
	lastUserInput time.Time
}

// NewPowerStateDetector creates a new power state detector for macOS
func NewPowerStateDetector() *PowerStateDetector {
	return &PowerStateDetector{
		lastIdleCheck: time.Now(),
		lastActivity:  time.Now(),
		idleThreshold: 5 * time.Minute, // Consider system idle after 5 minutes
		lastUserInput: time.Now(),
	}
}

// GetPowerState detects the current power state of the macOS system
func (d *PowerStateDetector) GetPowerState() (PowerState, error) {
	state := PowerState{
		LastUpdate: time.Now(),
	}

	// Check if system is sleeping using pmset
	if sleeping, err := d.isSystemSleeping(); err == nil {
		state.IsSleeping = sleeping
	}

	// Check if screen is locked using AppleScript
	if locked, err := d.isScreenLocked(); err == nil {
		state.IsLocked = locked
	}

	// Check if display is sleeping
	if displaySleep, err := d.isDisplaySleeping(); err == nil {
		state.IsDisplaySleep = displaySleep
	}

	// Check system idle time with improved detection
	if idle, err := d.isSystemIdle(); err == nil {
		state.IsIdle = idle
	}

	return state, nil
}

// isSystemSleeping checks if the system is in sleep mode
func (d *PowerStateDetector) isSystemSleeping() (bool, error) {
	// Use pmset to get power state
	cmd := exec.Command("pmset", "-g", "ps")
	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		return false, fmt.Errorf("failed to run pmset: %w", err)
	}

	output := out.String()
	// Check for various sleep indicators
	sleepIndicators := []string{"sleep", "standby", "hibernate", "suspend"}
	for _, indicator := range sleepIndicators {
		if strings.Contains(strings.ToLower(output), indicator) {
			return true, nil
		}
	}

	return false, nil
}

// isScreenLocked checks if the screen is locked using AppleScript
func (d *PowerStateDetector) isScreenLocked() (bool, error) {
	// The most reliable method we found: check if the frontmost app has 0 accessible windows
	// When screen is locked, the frontmost app will have 0 windows accessible
	// When screen is unlocked, it will have 1 or more windows
	script := `tell application "System Events" to try
		tell first process whose frontmost is true
			return count of windows
		end tell
	on error
		return -1
	end try`

	cmd := exec.Command("osascript", "-e", script)
	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		return false, fmt.Errorf("failed to check screen lock: %w", err)
	}

	result := strings.TrimSpace(out.String())

	// If we get "0", the screen is locked (no accessible windows)
	// If we get "1" or more, the screen is unlocked
	// If we get "-1" or "error", we couldn't determine the state
	if result == "0" {
		return true, nil
	}

	return false, nil
}

// isDisplaySleeping checks if the display is sleeping
func (d *PowerStateDetector) isDisplaySleeping() (bool, error) {
	// Use ioreg to check display power state
	cmd := exec.Command("ioreg", "-n", "IODisplayConnect", "-r", "-d", "1")
	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		return false, fmt.Errorf("failed to check display state: %w", err)
	}

	output := out.String()
	// Look for IODisplayIsBuiltin and IOPowerManagement
	// If IOPowerManagement shows display is off, it's sleeping
	return strings.Contains(output, "IOPowerManagement") &&
		strings.Contains(output, "CurrentPowerState = 4"), nil
}

// isSystemIdle checks if the system has been idle for too long
func (d *PowerStateDetector) isSystemIdle() (bool, error) {
	// Check for user input activity using ioreg
	cmd := exec.Command("ioreg", "-n", "IOHIDSystem", "-r", "-d", "1")
	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		// Fallback to time-based idle detection
		return d.isTimeBasedIdle(), nil
	}

	output := out.String()

	// Check for HIDIdleTime in the output
	if strings.Contains(output, "HIDIdleTime") {
		// Parse the idle time from the output
		lines := strings.Split(output, "\n")
		for _, line := range lines {
			if strings.Contains(line, "HIDIdleTime") {
				// Extract the idle time value and compare with threshold
				// For now, use time-based detection as fallback
				break
			}
		}
	}

	return d.isTimeBasedIdle(), nil
}

// isTimeBasedIdle uses time-based detection as a fallback
func (d *PowerStateDetector) isTimeBasedIdle() bool {
	now := time.Now()
	if now.Sub(d.lastActivity) > d.idleThreshold {
		return true
	}
	return false
}

// UpdateActivity should be called when user activity is detected
func (d *PowerStateDetector) UpdateActivity() {
	d.lastActivity = time.Now()
	d.lastUserInput = time.Now()
}

// ShouldStopTracking determines if we should stop tracking based on power state
func (d *PowerStateDetector) ShouldStopTracking() (bool, string) {
	state, err := d.GetPowerState()
	if err != nil {
		// If we can't determine power state, continue tracking but log the error
		return false, fmt.Sprintf("Power state detection failed: %v", err)
	}

	if state.IsSleeping {
		return true, "System is sleeping"
	}

	if state.IsLocked {
		return true, "Screen is locked"
	}

	if state.IsDisplaySleep {
		return true, "Display is sleeping"
	}

	if state.IsIdle {
		return true, "System is idle"
	}

	return false, ""
}

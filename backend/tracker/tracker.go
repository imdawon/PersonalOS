package tracker

import "time"

// ActivityData holds the information about the user's current activity.
type ActivityData struct {
	AppName     string
	WindowTitle string
}

// PowerState represents the current power state of the system
type PowerState struct {
	IsSleeping     bool
	IsLocked       bool
	IsDisplaySleep bool
	IsIdle         bool
	LastUpdate     time.Time
}

// Tracker is the interface that abstracts the platform-specific logic
// for getting the current user activity and power state.
type Tracker interface {
	GetActivity() (ActivityData, error)
	GetPowerState() (PowerState, error)
}

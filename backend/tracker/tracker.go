package tracker

// ActivityData holds the information about the user's current activity.
type ActivityData struct {
	AppName     string
	WindowTitle string
}

// Tracker is the interface that abstracts the platform-specific logic
// for getting the current user activity.
type Tracker interface {
	GetActivity() (ActivityData, error)
}

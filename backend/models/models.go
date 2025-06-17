package models

import "time"

// RawEvent is a single data point captured by the tracker.
type RawEvent struct {
	Timestamp   time.Time `json:"timestamp"`
	AppName     string    `json:"app_name"`
	WindowTitle string    `json:"window_title"`
}

// ActivitySession represents a consolidated block of time spent on a single activity.
type ActivitySession struct {
	ID               int64     `json:"id"`
	AppName          string    `json:"app_name"`
	WindowTitle      string    `json:"window_title"`
	StartTime        time.Time `json:"start_time"`
	EndTime          time.Time `json:"end_time"`
	Duration         int64     `json:"duration_seconds"` // Duration in seconds
	ClassificationID int64     `json:"classification_id,omitempty"`
}

// Classification is a user-defined label for an activity.
type Classification struct {
	ID              int64  `json:"id"`
	UserDefinedName string `json:"user_defined_name"`
	IsHelpful       bool   `json:"is_helpful"`
	GoalContext     string `json:"goal_context"` // e.g., "Work", "Relax", "Learn"
}

// ClassificationRequest is used by the API to classify a set of activities.
type ClassificationRequest struct {
	AppName         string `json:"app_name"`
	WindowTitle     string `json:"window_title"`
	UserDefinedName string `json:"user_defined_name"`
	IsHelpful       bool   `json:"is_helpful"`
	GoalContext     string `json:"goal_context"`
}

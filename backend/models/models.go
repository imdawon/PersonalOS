package models

import (
	"encoding/json"
	"time"
)

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
	StartTime        time.Time `json:"-"`
	EndTime          time.Time `json:"-"`
	Duration         int64     `json:"duration_seconds"` // Duration in seconds
	ClassificationID *int64    `json:"classification_id,omitempty"`
}

// MarshalJSON ensures StartTime and EndTime are sent as Unix timestamps (int)
func (s ActivitySession) MarshalJSON() ([]byte, error) {
	type Alias ActivitySession
	return json.Marshal(&struct {
		StartTime int64 `json:"start_time"`
		EndTime   int64 `json:"end_time"`
		*Alias
	}{
		StartTime: s.StartTime.Unix(),
		EndTime:   s.EndTime.Unix(),
		Alias:     (*Alias)(&s),
	})
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

// SessionIdentifier is used to uniquely identify a session for batch classification.
type SessionIdentifier struct {
	AppName     string `json:"app_name"`
	WindowTitle string `json:"window_title"`
}

// BatchClassificationRequest is used by the API to classify a batch of activities.
type BatchClassificationRequest struct {
	Sessions        []SessionIdentifier `json:"sessions"`
	UserDefinedName string              `json:"user_defined_name"`
	IsHelpful       bool                `json:"is_helpful"`
	GoalContext     string              `json:"goal_context"`
}

// ClassificationRule defines a rule for automatic classification.
type ClassificationRule struct {
	ID                  int64  `json:"id"`
	AppName             string `json:"app_name"`
	WindowTitleContains string `json:"window_title_contains"`
	ClassificationID    int64  `json:"classification_id"`
	Priority            int    `json:"priority"`
}

// CreateClassificationRuleRequest is the model for the API request to create a rule.
type CreateClassificationRuleRequest struct {
	AppName             string `json:"app_name"`
	WindowTitleContains string `json:"window_title_contains"`
	UserDefinedName     string `json:"user_defined_name"`
	IsHelpful           bool   `json:"is_helpful"`
	GoalContext         string `json:"goal_context"`
}

// RuleInfo is a model for returning a rule joined with its classification name.
type RuleInfo struct {
	ID                  int64  `json:"id"`
	AppName             string `json:"app_name"`
	WindowTitleContains string `json:"window_title_contains"`
	UserDefinedName     string `json:"user_defined_name"`
}

// RecentActivityInfo is a model for a recently classified session.
type RecentActivityInfo struct {
	SessionID       int64  `json:"session_id"`
	AppName         string `json:"app_name"`
	WindowTitle     string `json:"window_title"`
	UserDefinedName string `json:"user_defined_name"`
	StartTime       int64  `json:"start_time"`
	IsAuto          bool   `json:"is_auto"`
}

// ReclassifyRequest is used to update the classification of an existing session.
type ReclassifyRequest struct {
	SessionID       int64  `json:"session_id"`
	UserDefinedName string `json:"user_defined_name"`
	IsHelpful       bool   `json:"is_helpful"`
	GoalContext     string `json:"goal_context"`
}

// ExistingClassification represents an existing classification for dropdown options.
type ExistingClassification struct {
	UserDefinedName string `json:"user_defined_name"`
	GoalContext     string `json:"goal_context"`
	IsHelpful       bool   `json:"is_helpful"`
}

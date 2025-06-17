package storage

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/imdawon/personalos/models"

	_ "modernc.org/sqlite" // SQLite driver
)

// DBStore handles database operations.
type DBStore struct {
	db *sql.DB
}

// NewDBStore initializes the database connection and schema.
func NewDBStore(filepath string) (*DBStore, error) {
	db, err := sql.Open("sqlite", filepath)
	if err != nil {
		return nil, err
	}

	store := &DBStore{db: db}
	return store, store.initSchema()
}

// initSchema creates the necessary tables if they don't exist.
func (s *DBStore) initSchema() error {
	schema := `
        CREATE TABLE IF NOT EXISTS raw_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            app_name TEXT NOT NULL,
            window_title TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS activity_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            app_name TEXT NOT NULL,
            window_title TEXT NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            classification_id INTEGER,
			FOREIGN KEY(classification_id) REFERENCES classifications(id)
        );
        CREATE TABLE IF NOT EXISTS classifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_defined_name TEXT NOT NULL UNIQUE,
            is_helpful BOOLEAN NOT NULL,
            goal_context TEXT NOT NULL
        );
    `
	_, err := s.db.Exec(schema)
	return err
}

// InsertRawEvent adds a new event to the database.
func (s *DBStore) InsertRawEvent(event models.RawEvent) error {
	_, err := s.db.Exec("INSERT INTO raw_events (timestamp, app_name, window_title) VALUES (?, ?, ?)",
		event.Timestamp.Unix(), event.AppName, event.WindowTitle)
	return err
}

// GetUnclassifiedSessions fetches distinct activities that haven't been labeled.
// This is a simplified version for the API to prompt the user.
func (s *DBStore) GetUnclassifiedSessions() ([]models.ActivitySession, error) {
	rows, err := s.db.Query(`
		SELECT app_name, window_title, SUM(duration_seconds) as total_duration
		FROM activity_sessions
		WHERE classification_id IS NULL
		GROUP BY app_name, window_title
		ORDER BY total_duration DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sessions []models.ActivitySession
	for rows.Next() {
		var session models.ActivitySession
		if err := rows.Scan(&session.AppName, &session.WindowTitle, &session.Duration); err != nil {
			return nil, err
		}
		sessions = append(sessions, session)
	}
	return sessions, nil
}

// ApplyClassification assigns a classification to all matching sessions.
func (s *DBStore) ApplyClassification(req models.ClassificationRequest) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	// 1. Find or create the classification
	var classID int64
	err = tx.QueryRow("SELECT id FROM classifications WHERE user_defined_name = ?", req.UserDefinedName).Scan(&classID)
	if err == sql.ErrNoRows {
		res, err := tx.Exec("INSERT INTO classifications (user_defined_name, is_helpful, goal_context) VALUES (?, ?, ?)",
			req.UserDefinedName, req.IsHelpful, req.GoalContext)
		if err != nil {
			tx.Rollback()
			return err
		}
		classID, _ = res.LastInsertId()
	} else if err != nil {
		tx.Rollback()
		return err
	}

	// 2. Update all matching sessions
	_, err = tx.Exec(`
		UPDATE activity_sessions
		SET classification_id = ?
		WHERE app_name = ? AND window_title = ? AND classification_id IS NULL
	`, classID, req.AppName, req.WindowTitle)

	if err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit()
}

// ApplyClassificationBatch assigns a classification to a batch of sessions.
func (s *DBStore) ApplyClassificationBatch(req models.BatchClassificationRequest) error {
	if len(req.Sessions) == 0 {
		return nil
	}

	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	// 1. Find or create the classification ID.
	var classID int64
	err = tx.QueryRow("SELECT id FROM classifications WHERE user_defined_name = ?", req.UserDefinedName).Scan(&classID)
	if err == sql.ErrNoRows {
		res, err := tx.Exec("INSERT INTO classifications (user_defined_name, is_helpful, goal_context) VALUES (?, ?, ?)",
			req.UserDefinedName, req.IsHelpful, req.GoalContext)
		if err != nil {
			tx.Rollback()
			return err
		}
		classID, _ = res.LastInsertId()
	} else if err != nil {
		tx.Rollback()
		return err
	}

	// 2. Build a single UPDATE query for all sessions in the batch.
	query := "UPDATE activity_sessions SET classification_id = ? WHERE classification_id IS NULL AND ("
	args := []interface{}{classID}
	placeholders := []string{}

	for _, session := range req.Sessions {
		placeholders = append(placeholders, "(app_name = ? AND window_title = ?)")
		args = append(args, session.AppName, session.WindowTitle)
	}

	query += strings.Join(placeholders, " OR ") + ")"

	// 3. Execute the batch update.
	res, err := tx.Exec(query, args...)
	if err != nil {
		tx.Rollback()
		return err
	}

	rowsAffected, _ := res.RowsAffected()
	log.Printf("ApplyClassificationBatch updated %d rows", rowsAffected)

	return tx.Commit()
}

// ProcessRawEvents is called by the processor to aggregate events into sessions.
func (s *DBStore) ProcessRawEvents() error {
	// This is a simplified but effective v0 processor logic.
	// It groups consecutive raw events into sessions.
	rows, err := s.db.Query("SELECT id, timestamp, app_name, window_title FROM raw_events ORDER BY timestamp ASC")
	if err != nil {
		return fmt.Errorf("could not query raw events: %w", err)
	}
	defer rows.Close()

	var currentSession *models.ActivitySession
	var lastEventTime time.Time
	var idsToDelete []int64

	for rows.Next() {
		var event models.RawEvent
		var eventID int64
		var ts int64
		if err := rows.Scan(&eventID, &ts, &event.AppName, &event.WindowTitle); err != nil {
			// Log error and continue
			continue
		}
		event.Timestamp = time.Unix(ts, 0)
		idsToDelete = append(idsToDelete, eventID)

		if currentSession == nil {
			// Start the first session
			currentSession = &models.ActivitySession{
				AppName:     event.AppName,
				WindowTitle: event.WindowTitle,
				StartTime:   event.Timestamp,
			}
		} else if currentSession.AppName != event.AppName || currentSession.WindowTitle != event.WindowTitle || event.Timestamp.Sub(lastEventTime).Seconds() > 30 {
			// If activity changes or there's a >30s gap, end the current session and save it.
			currentSession.EndTime = lastEventTime
			currentSession.Duration = int64(currentSession.EndTime.Sub(currentSession.StartTime).Seconds())

			if currentSession.Duration > 5 { // Only save sessions longer than 5 seconds
				s.saveSession(currentSession)
			}

			// Start a new session
			currentSession = &models.ActivitySession{
				AppName:     event.AppName,
				WindowTitle: event.WindowTitle,
				StartTime:   event.Timestamp,
			}
		}
		lastEventTime = event.Timestamp
	}

	// Save the very last session
	if currentSession != nil {
		currentSession.EndTime = lastEventTime
		currentSession.Duration = int64(currentSession.EndTime.Sub(currentSession.StartTime).Seconds())
		if currentSession.Duration > 5 {
			s.saveSession(currentSession)
		}
	}

	// Clean up processed raw events
	if len(idsToDelete) > 0 {
		// In a real app, you might archive these instead of deleting.
		// For v0, deleting is fine.
		s.db.Exec(fmt.Sprintf("DELETE FROM raw_events WHERE id IN (%s)", intSliceToString(idsToDelete)))
	}

	return nil
}

func (s *DBStore) saveSession(session *models.ActivitySession) error {
	_, err := s.db.Exec(`
		INSERT INTO activity_sessions (app_name, window_title, start_time, end_time, duration_seconds)
		VALUES (?, ?, ?, ?, ?)
	`, session.AppName, session.WindowTitle, session.StartTime.Unix(), session.EndTime.Unix(), session.Duration)
	return err
}

// Helper to format integer slice for SQL IN clause
func intSliceToString(ids []int64) string {
	if len(ids) == 0 {
		return ""
	}
	var b strings.Builder
	fmt.Fprintf(&b, "%d", ids[0])
	for _, id := range ids[1:] {
		fmt.Fprintf(&b, ",%d", id)
	}
	return b.String()
}

// In storage/sqlite.go

// TodaySummaryItem represents a single aggregated activity for the dashboard.
type TodaySummaryItem struct {
	UserDefinedName string `json:"user_defined_name"`
	TotalDuration   int64  `json:"total_duration_seconds"`
}

// GetTodaySummary fetches aggregated, classified data for the current day.
func (s *DBStore) GetTodaySummary() ([]TodaySummaryItem, error) {
	// Get the Unix timestamp for the start of the current day in UTC.
	// NOTE: For more complex timezone handling, this would need adjustment.
	// For v0, UTC is fine.
	startOfDay := time.Now().UTC().Truncate(24 * time.Hour)

	rows, err := s.db.Query(`
        SELECT
            c.user_defined_name,
            SUM(s.duration_seconds) as total_duration
        FROM activity_sessions s
        JOIN classifications c ON s.classification_id = c.id
        WHERE s.start_time >= ? AND s.classification_id IS NOT NULL 
        GROUP BY c.user_defined_name
        HAVING total_duration > 0 
        ORDER BY total_duration DESC;
    `, startOfDay.Unix()) // Make sure start_time is compared correctly
	if err != nil {
		log.Printf("Error querying today summary: %v", err)
		return nil, err
	}
	defer rows.Close()

	// Initialize as an empty slice, not nil, to ensure JSON [] for no results
	summary := make([]TodaySummaryItem, 0)
	for rows.Next() {
		var item TodaySummaryItem
		if err := rows.Scan(&item.UserDefinedName, &item.TotalDuration); err != nil {
			log.Printf("Error scanning today summary item: %v", err)
			// Decide if you want to return partial results or error out
			return nil, err
		}
		summary = append(summary, item)
	}
	if err := rows.Err(); err != nil { // Check for errors during iteration
		log.Printf("Error during rows iteration for today summary: %v", err)
		return nil, err
	}
	return summary, nil
}

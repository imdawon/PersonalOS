package api

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/imdawon/personalos/models"
	"github.com/imdawon/personalos/storage"
)

// Server is the API server.
type Server struct {
	store *storage.DBStore
}

// NewServer creates a new API server.
func NewServer(store *storage.DBStore) *Server {
	return &Server{store: store}
}

// Start runs the HTTP server.
func (s *Server) Start(addr string) {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/v0/unclassified-sessions", s.handleGetUnclassified)
	mux.HandleFunc("/api/v0/classify", s.handleClassify)
	mux.HandleFunc("/api/v0/classify-batch", s.handleClassifyBatch)
	mux.HandleFunc("/api/v0/reclassify", s.handleReclassify)
	mux.HandleFunc("/api/v0/delete-session", s.handleDeleteSession)
	mux.HandleFunc("/api/v0/classifications", s.handleGetClassifications)
	mux.HandleFunc("/api/v0/today-summary", s.handleGetTodaySummary)
	mux.HandleFunc("/api/v0/rules", s.handleRules)
	mux.HandleFunc("/api/v0/recent-activity", s.handleGetRecentActivity)

	log.Printf("API server listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("API server failed: %v", err)
	}
}

func (s *Server) handleGetUnclassified(w http.ResponseWriter, r *http.Request) {
	sessions, err := s.store.GetUnclassifiedSessions()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, sessions)
}

func (s *Server) handleClassify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.ClassificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.store.ApplyClassification(req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	s.respondJSON(w, http.StatusOK, map[string]string{"status": "success"})
}

func (s *Server) handleClassifyBatch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}
	var req models.BatchClassificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.store.ApplyClassificationBatch(req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, map[string]string{"status": "success"})
}

func (s *Server) handleReclassify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.ReclassifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.store.ReclassifySession(req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	s.respondJSON(w, http.StatusOK, map[string]string{"status": "success"})
}

func (s *Server) handleDeleteSession(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Only DELETE method is allowed", http.StatusMethodNotAllowed)
		return
	}

	sessionIDStr := r.URL.Query().Get("id")
	if sessionIDStr == "" {
		http.Error(w, "Missing session ID", http.StatusBadRequest)
		return
	}
	sessionID, err := strconv.ParseInt(sessionIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid session ID", http.StatusBadRequest)
		return
	}

	if err := s.store.DeleteSession(sessionID); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	s.respondJSON(w, http.StatusOK, map[string]string{"status": "session deleted"})
}

func (s *Server) handleGetClassifications(w http.ResponseWriter, r *http.Request) {
	classifications, err := s.store.GetExistingClassifications()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, classifications)
}

func (s *Server) handleRules(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		s.handleGetRules(w, r)
	case http.MethodPost:
		s.handleCreateRule(w, r)
	case http.MethodDelete:
		s.handleDeleteRule(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (s *Server) handleGetRules(w http.ResponseWriter, r *http.Request) {
	rules, err := s.store.GetClassificationRules()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, rules)
}

func (s *Server) handleDeleteRule(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		http.Error(w, "Missing rule ID", http.StatusBadRequest)
		return
	}
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid rule ID", http.StatusBadRequest)
		return
	}

	if err := s.store.DeleteClassificationRule(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, map[string]string{"status": "rule deleted"})
}

func (s *Server) handleCreateRule(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}
	var req models.CreateClassificationRuleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.store.CreateClassificationRule(req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusCreated, map[string]string{"status": "rule created"})
}

func (s *Server) handleGetTodaySummary(w http.ResponseWriter, r *http.Request) {
	summary, err := s.store.GetTodaySummary()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, summary)
}

func (s *Server) handleGetRecentActivity(w http.ResponseWriter, r *http.Request) {
	activities, err := s.store.GetRecentClassifiedSessions()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	s.respondJSON(w, http.StatusOK, activities)
}

func (s *Server) respondJSON(w http.ResponseWriter, status int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(response)
}

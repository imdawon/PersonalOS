package api

import (
	"encoding/json"
	"log"
	"net/http"

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

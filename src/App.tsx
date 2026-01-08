import React from "react";
import { Page, PageHeader, PageHeaderTitle, Card, CardContent, Button } from "@skin-studio/react";
import { HashRouter, Routes, Route, useNavigate, useParams, useLocation, Navigate } from "react-router-dom";

// Types
type SyncStatus = "upToDate" | "syncing" | "pending" | "error";

type Run = {
  id: string;
  name: string;
  sampleId?: string;
  notes?: string;
  status: "In Progress" | "Complete";
  createdAt: number;
  pendingSync?: boolean;
};

// Local storage helpers
const RUNS_KEY = "labAssistant.runs";

function loadRuns(): Run[] {
  try {
    if (typeof localStorage === "undefined") return [];
    const raw = localStorage.getItem(RUNS_KEY);
    return raw ? (JSON.parse(raw) as Run[]) : [];
  } catch {
    return [];
  }
}

function saveRuns(runs: Run[]) {
  try {
    if (typeof localStorage === "undefined") return;
    localStorage.setItem(RUNS_KEY, JSON.stringify(runs));
  } catch {
    // no-op
  }
}

// Sync banner driven by props
function SyncBanner({
  online,
  status,
  pendingCount,
  onRetry,
}: {
  online: boolean;
  status: SyncStatus;
  pendingCount: number;
  onRetry: () => void;
}) {
  const label = !online
    ? "Offline — changes will sync later"
    : status === "upToDate"
    ? "All changes synced"
    : status === "syncing"
    ? "Syncing…"
    : status === "pending"
    ? `Pending changes (${pendingCount})`
    : "Sync failed — tap retry";

  const showRetry = (status === "error" || status === "pending") && online && pendingCount > 0;

  return (
    <Card>
      <CardContent>
        <div style={{ display: "flex", gap: 12, alignItems: "center", justifyContent: "space-between" }}>
          <span aria-live="polite">{label}</span>
          {showRetry && (
            <Button onClick={onRetry} aria-label="Retry sync">
              Retry
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

function QuickActions({ onStartNewRun }: { onStartNewRun: () => void }) {
  return (
    <Card>
      <CardContent>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          <Button onClick={onStartNewRun} aria-label="Start a new run">
            New Run
          </Button>
          <Button onClick={() => alert("Add Measurement…")} aria-label="Add measurement">
            Add Measurement
          </Button>
          <Button onClick={() => alert("Attach Sample…")} aria-label="Attach sample">
            Attach Sample
          </Button>
          <Button onClick={() => alert("Export data…")} aria-label="Export data">
            Export
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function RecentRuns({ runs, onOpenRun }: { runs: Run[]; onOpenRun: (id: string) => void }) {
  const sorted = React.useMemo(() => [...runs].sort((a, b) => b.createdAt - a.createdAt), [runs]);

  return (
    <Card>
      <CardContent>
        <h2 style={{ marginTop: 0 }}>Recent Runs</h2>
        {sorted.length === 0 ? (
          <p>No runs yet — start your first run to see it here.</p>
        ) : (
          <ul style={{ paddingLeft: 16, margin: 0 }}>
            {sorted.map((r) => (
              <li key={r.id} style={{ marginBottom: 6 }}>
                <Button onClick={() => onOpenRun(r.id)} aria-label={`Open ${r.id}`}>
                  {r.id} — {r.status}
                  {r.pendingSync ? " (pending sync)" : ""}
                </Button>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}

function NewRunModal({
  open,
  onClose,
  onCreate,
}: {
  open: boolean;
  onClose: () => void;
  onCreate: (data: { name: string; sampleId?: string; notes?: string }) => void;
}) {
  const [name, setName] = React.useState("");
  const [sampleId, setSampleId] = React.useState("");
  const [notes, setNotes] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError("Run name is required");
      return;
    }
    onCreate({ name: name.trim(), sampleId: sampleId.trim() || undefined, notes: notes.trim() || undefined });
    setName("");
    setSampleId("");
    setNotes("");
    setError(null);
    onClose();
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="new-run-title"
      aria-describedby="new-run-desc"
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0,0,0,0.4)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1000,
        padding: 16,
      }}
      onClick={onClose}
    >
      <div style={{ width: "min(560px, 90vw)" }} onClick={(e) => e.stopPropagation()}>
        <Card>
          <CardContent>
            <h2 id="new-run-title" style={{ marginTop: 0 }}>
              Start a new run
            </h2>
            <p id="new-run-desc" style={{ marginTop: 0 }}>
              Provide a name and optional details. You can edit later.
            </p>
            <form onSubmit={submit}>
              <div style={{ display: "grid", gap: 12 }}>
                <label>
                  <span>Run name</span>
                  <input
                    autoFocus
                    type="text"
                    value={name}
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) => setName(e.target.value)}
                    aria-invalid={!!error}
                    aria-describedby={error ? "new-run-error" : undefined}
                    style={{ width: "100%", padding: 8, borderRadius: 6, border: "1px solid #ccc" }}
                  />
                </label>
                <label>
                  <span>Sample ID (optional)</span>
                  <input
                    type="text"
                    value={sampleId}
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSampleId(e.target.value)}
                    style={{ width: "100%", padding: 8, borderRadius: 6, border: "1px solid #ccc" }}
                  />
                </label>
                <label>
                  <span>Notes (optional)</span>
                  <textarea
                    value={notes}
                    onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setNotes(e.target.value)}
                    rows={4}
                    style={{ width: "100%", padding: 8, borderRadius: 6, border: "1px solid #ccc", resize: "vertical" }}
                  />
                </label>
                {error && (
                  <p id="new-run-error" style={{ color: "#b00020", margin: 0 }}>{error}</p>
                )}
                <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", marginTop: 8 }}>
                  <Button type="button" onClick={onClose} aria-label="Cancel new run">
                    Cancel
                  </Button>
                  <Button type="submit" aria-label="Create new run">
                    Create
                  </Button>
                </div>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function RunDetail({
  runs,
  onUpdateRun,
}: {
  runs: Run[];
  onUpdateRun: (id: string, patch: Partial<Run>) => void;
}) {
  const navigate = useNavigate();
  const { id } = useParams();
  const run = runs.find((r) => r.id === id);

  if (!run) {
    return (
      <Card>
        <CardContent>
          <h2 style={{ marginTop: 0 }}>Run not found</h2>
          <Button onClick={() => navigate("/")} aria-label="Back to home">
            Back
          </Button>
        </CardContent>
      </Card>
    );
  }

  const markComplete = () => onUpdateRun(run.id, { status: "Complete" });
  const reopen = () => onUpdateRun(run.id, { status: "In Progress" });

  return (
    <Card>
      <CardContent>
        <h2 style={{ marginTop: 0 }}>
          {run.name} ({run.id})
        </h2>
        <p>
          Status: {run.status}
          {run.pendingSync ? " (pending sync)" : ""}
        </p>
        {run.sampleId ? <p>Sample ID: {run.sampleId}</p> : null}
        {run.notes ? <p>Notes: {run.notes}</p> : null}
        <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
          {run.status === "In Progress" ? (
            <Button onClick={markComplete} aria-label="Mark run complete">
              Mark Complete
            </Button>
          ) : (
            <Button onClick={reopen} aria-label="Reopen run">
              Reopen
            </Button>
          )}
          <Button onClick={() => navigate("/")} aria-label="Back to home">
            Back
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function Home({
  online,
  syncStatus,
  pendingCount,
  onRetry,
  runs,
  onCreateRun,
}: {
  online: boolean;
  syncStatus: SyncStatus;
  pendingCount: number;
  onRetry: () => void;
  runs: Run[];
  onCreateRun: (data: { name: string; sampleId?: string; notes?: string }) => string;
}) {
  const navigate = useNavigate();
  const location = useLocation();
  const forceNewRunOpen = location.pathname === "/run/new";

  const startNewRun = () => navigate("/run/new");
  const closeNewRun = () => navigate("/");

  const handleCreate = (data: { name: string; sampleId?: string; notes?: string }) => {
    const id = onCreateRun(data);
    navigate(`/run/${id}`);
  };

  return (
    <>
      <SyncBanner online={online} status={syncStatus} pendingCount={pendingCount} onRetry={onRetry} />

      <Card>
        <CardContent>
          <p>Welcome to Lab Assistant</p>
          <Button onClick={startNewRun} aria-label="Get started with a new run">
            Get Started
          </Button>
        </CardContent>
      </Card>

      <QuickActions onStartNewRun={startNewRun} />
      <RecentRuns runs={runs} onOpenRun={(id) => navigate(`/run/${id}`)} />

      <NewRunModal open={forceNewRunOpen} onClose={closeNewRun} onCreate={handleCreate} />
    </>
  );
}

function App() {
  // Online state
  const [online, setOnline] = React.useState<boolean>(
    typeof navigator !== "undefined" ? navigator.onLine : true
  );

  React.useEffect(() => {
    const handleOnline = () => setOnline(true);
    const handleOffline = () => setOnline(false);
    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);
    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  // Runs and sync state
  const [runs, setRuns] = React.useState<Run[]>(() => loadRuns());
  React.useEffect(() => {
    saveRuns(runs);
  }, [runs]);

  const pendingCount = React.useMemo(
    () => runs.filter((r) => r.pendingSync).length,
    [runs]
  );

  const [syncStatus, setSyncStatus] = React.useState<SyncStatus>("upToDate");

  const autoSync = React.useCallback(() => {
    if (!online) return; // wait until online
    if (pendingCount === 0) {
      setSyncStatus("upToDate");
      return;
    }
    setSyncStatus("syncing");
    // Simulate a short network sync
    setTimeout(() => {
      setRuns((prev) => prev.map((r) => (r.pendingSync ? { ...r, pendingSync: false } : r)));
      setSyncStatus("upToDate");
    }, 800);
  }, [online, pendingCount]);

  // When coming online or pending changes appear, try to sync
  React.useEffect(() => {
    if (online && pendingCount > 0) {
      setSyncStatus("pending");
      autoSync();
    } else if (!online && pendingCount > 0) {
      setSyncStatus("pending");
    } else if (online && pendingCount === 0) {
      setSyncStatus("upToDate");
    }
  }, [online, pendingCount, autoSync]);

  const createRun = (data: { name: string; sampleId?: string; notes?: string }): string => {
    const id = `R-${Date.now()}`;
    const newRun: Run = {
      id,
      name: data.name,
      sampleId: data.sampleId,
      notes: data.notes,
      status: "In Progress",
      createdAt: Date.now(),
      pendingSync: !online,
    };
    setRuns((prev) => [newRun, ...prev]);
    if (!online) {
      setSyncStatus("pending");
    } else {
      autoSync();
    }
    return id;
  };

  const updateRun = (id: string, patch: Partial<Run>) => {
    setRuns((prev) =>
      prev.map((r) =>
        r.id === id
          ? {
              ...r,
              ...patch,
              // Mark as pending if offline; otherwise preserve existing pending flag
              pendingSync: !online ? true : r.pendingSync,
            }
          : r
      )
    );
    if (!online) {
      setSyncStatus("pending");
    } else {
      autoSync();
    }
  };

  return (
    <HashRouter>
      <Page>
        <PageHeader>
          <PageHeaderTitle>Lab Assistant</PageHeaderTitle>
        </PageHeader>

        <Routes>
          <Route
            path="/"
            element={
              <Home
                online={online}
                syncStatus={syncStatus}
                pendingCount={pendingCount}
                onRetry={autoSync}
                runs={runs}
                onCreateRun={createRun}
              />
            }
          />
          <Route
            path="/run/new"
            element={
              <Home
                online={online}
                syncStatus={syncStatus}
                pendingCount={pendingCount}
                onRetry={autoSync}
                runs={runs}
                onCreateRun={createRun}
              />
            }
          />
          <Route path="/run/:id" element={<RunDetail runs={runs} onUpdateRun={updateRun} />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Page>
    </HashRouter>
  );
}

export default App;

import React from "react";
import { Page, PageHeader, PageHeaderTitle, Card, CardContent, Button } from "@skin-studio/react";

function SyncBanner() {
  const [online, setOnline] = React.useState<boolean>(typeof navigator !== "undefined" ? navigator.onLine : true);
  const [status, setStatus] = React.useState<"upToDate" | "syncing" | "pending" | "error">("upToDate");
  const [pendingCount] = React.useState<number>(0);

  React.useEffect(() => {
    if (typeof window === "undefined") return;
    const handleOnline = () => setOnline(true);
    const handleOffline = () => setOnline(false);
    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);
    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  const retry = () => {
    // TODO: Hook to your sync manager
    setStatus("syncing");
    setTimeout(() => setStatus("upToDate"), 1000);
  };

  const label = !online
    ? "Offline — changes will sync later"
    : status === "upToDate"
    ? "All changes synced"
    : status === "syncing"
    ? "Syncing…"
    : status === "pending"
    ? `Pending changes (${pendingCount})`
    : "Sync failed — tap retry";

  return (
    <Card>
      <CardContent>
        <div style={{ display: "flex", gap: 12, alignItems: "center", justifyContent: "space-between" }}>
          <span aria-live="polite">{label}</span>
          {(status === "error" || status === "pending") && (
            <Button onClick={retry} aria-label="Retry sync">Retry</Button>
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
          <Button onClick={onStartNewRun} aria-label="Start a new run">New Run</Button>
          <Button onClick={() => alert("Add Measurement…")} aria-label="Add measurement">Add Measurement</Button>
          <Button onClick={() => alert("Attach Sample…")} aria-label="Attach sample">Attach Sample</Button>
          <Button onClick={() => alert("Export data…")} aria-label="Export data">Export</Button>
        </div>
      </CardContent>
    </Card>
  );
}

function RecentRuns() {
  // TODO: Replace with real data; show empty state if none.
  const runs = [
    { id: "R-1024", status: "In Progress" },
    { id: "R-1023", status: "Complete" },
  ];
  return (
    <Card>
      <CardContent>
        <h2 style={{ marginTop: 0 }}>Recent Runs</h2>
        {runs.length === 0 ? (
          <p>No runs yet — start your first run to see it here.</p>
        ) : (
          <ul style={{ paddingLeft: 16, margin: 0 }}>
            {runs.map((r) => (
              <li key={r.id} style={{ marginBottom: 6 }}>
                <Button onClick={() => alert(`Open ${r.id}`)} aria-label={`Open ${r.id}`}>
                  {r.id} — {r.status}
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
            <h2 id="new-run-title" style={{ marginTop: 0 }}>Start a new run</h2>
            <p id="new-run-desc" style={{ marginTop: 0 }}>Provide a name and optional details. You can edit later.</p>
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
                  <Button type="button" onClick={onClose} aria-label="Cancel new run">Cancel</Button>
                  <Button type="submit" aria-label="Create new run">Create</Button>
                </div>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function App() {
  const [showNewRun, setShowNewRun] = React.useState(false);

  const startNewRun = () => setShowNewRun(true);

  const createRun = (data: { name: string; sampleId?: string; notes?: string }) => {
    // TODO: Replace with real creation + navigation
    alert(`Created run: ${data.name}`);
  };

  return (
    <Page>
      <PageHeader>
        <PageHeaderTitle>Lab Assistant</PageHeaderTitle>
      </PageHeader>

      <SyncBanner />

      <Card>
        <CardContent>
          <p>Welcome to Lab Assistant</p>
          <Button onClick={startNewRun} aria-label="Get started with a new run">Get Started</Button>
        </CardContent>
      </Card>

      <QuickActions onStartNewRun={startNewRun} />
      <RecentRuns />

      <NewRunModal open={showNewRun} onClose={() => setShowNewRun(false)} onCreate={createRun} />
    </Page>
  );
}

export default App;

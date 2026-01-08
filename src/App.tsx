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

function App() {
  // If you use a router, swap this for navigation to "/run/new".
  const startNewRun = () => {
    // Option A (router): navigate("/run/new")
    // Option B (no router): open a modal or inline form
    alert("Starting a new run… (wire this to your creation flow)");
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
    </Page>
  );
}

export default App;

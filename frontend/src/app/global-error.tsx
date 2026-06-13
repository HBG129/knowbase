"use client";

export default function GlobalError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html>
      <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif", background: "#fafafa" }}>
        <div style={{ display: "flex", minHeight: "100vh", alignItems: "center", justifyContent: "center", padding: "24px" }}>
          <div style={{ textAlign: "center", maxWidth: "400px" }}>
            <div style={{ width: "56px", height: "56px", borderRadius: "16px", background: "#f7d4d6", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px" }}>
              <span style={{ fontSize: "28px" }}>⚠</span>
            </div>
            <h1 style={{ fontSize: "24px", fontWeight: 600, color: "#0a0a0e", margin: "0 0 8px" }}>Something went wrong</h1>
            <p style={{ fontSize: "14px", color: "#888", margin: "0 0 24px" }}>A critical error occurred. Please try refreshing.</p>
            <button onClick={() => reset()} style={{ height: "40px", padding: "0 20px", borderRadius: "10px", border: "none", background: "#0a0a0e", color: "#fff", fontSize: "14px", fontWeight: 500, cursor: "pointer" }}>
              Try again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}

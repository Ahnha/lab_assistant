import React from "react";
import ReactDOM from "react-dom/client";
import { ThemeProvider } from "@skin-studio/react";
import App from "./App";
import "@skin-studio/react/styles.css";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider themeKey="studioAir">
      <App />
    </ThemeProvider>
  </React.StrictMode>
);

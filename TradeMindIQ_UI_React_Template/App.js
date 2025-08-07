import React from "react";
import "./App.css";
import Logo from "./assets/logo.png";

function App() {
  return (
    <div className="app">
      <header className="header fade-in">
        <img src={Logo} alt="TradeMindIQ Logo" className="logo" />
      </header>
      <main className="main-content">
        <div className="chart-background move-bg"></div>
        <div className="trade-ticket faded-ticket">Trade Ticket Design</div>
      </main>
    </div>
  );
}

export default App;
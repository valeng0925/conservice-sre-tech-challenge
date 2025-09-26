import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [billingData, setBillingData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchBillingData();
  }, []);

  const fetchBillingData = async () => {
    try {
      console.log('Fetching billing data from http://localhost:3000/billing');
      const response = await fetch('http://localhost:3000/billing');
      console.log('Response status:', response.status);
      console.log('Response headers:', response.headers);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Failed to fetch billing data`);
      }
      const data = await response.json();
      console.log('Received data:', data);
      setBillingData(data);
      setLoading(false);
    } catch (err) {
      console.error('Fetch error:', err);
      setError(err.message);
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'paid': return '#28a745';
      case 'pending': return '#ffc107';
      case 'overdue': return '#dc3545';
      default: return '#6c757d';
    }
  };

  if (loading) {
    return (
      <div className="App">
        <div className="container">
          <h1>Billing Dashboard</h1>
          <p>Loading billing data...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="App">
        <div className="container">
          <h1>Billing Dashboard</h1>
          <p style={{ color: 'red' }}>Error: {error}</p>
          <button onClick={fetchBillingData}>Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="App">
      <div className="container">
        <h1>Billing Dashboard</h1>
        <div className="billing-grid">
          {billingData.map((bill) => (
            <div key={bill.id} className="billing-card">
              <h3>{bill.customer}</h3>
              <p className="amount">${bill.amount.toFixed(2)}</p>
              <span 
                className="status" 
                style={{ backgroundColor: getStatusColor(bill.status) }}
              >
                {bill.status.toUpperCase()}
              </span>
            </div>
          ))}
        </div>
        <button onClick={fetchBillingData} className="refresh-btn">
          Refresh Data
        </button>
      </div>
    </div>
  );
}

export default App;

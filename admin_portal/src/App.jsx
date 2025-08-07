import './App.css';
import DoctorVerification from './components/DoctorVerification';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Admin Dashboard</h1>
      </header>
      <main>
        <section>
          <h2>Doctor Verification</h2>
          <DoctorVerification />
        </section>
      </main>
    </div>
  );
}

export default App;

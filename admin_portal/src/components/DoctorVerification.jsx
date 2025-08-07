import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, getDocs, doc, updateDoc } from 'firebase/firestore';
import './DoctorVerification.css';

const DoctorVerification = () => {
  const [doctors, setDoctors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDoctors = async () => {
      console.log('Starting to fetch doctors...');
      setLoading(true);
      try {
        const querySnapshot = await getDocs(collection(db, 'doctors'));
        console.log('Firestore query snapshot:', querySnapshot);
        if (querySnapshot.empty) {
          console.log('No documents found in the doctors collection.');
        }
        const doctorsList = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        console.log('Fetched doctors list:', doctorsList);
        setDoctors(doctorsList);
      } catch (error) {
        console.error('Error fetching doctors: ', error);
      }
      setLoading(false);
      console.log('Finished fetching doctors.');
    };

    fetchDoctors();
  }, []);

  const handleVerify = async (id) => {
    try {
      const doctorRef = doc(db, 'doctors', id);
      await updateDoc(doctorRef, {
        isVerified: true
      });
      // Update the state to reflect the change instantly
      setDoctors(doctors.map(d => d.id === id ? { ...d, isVerified: true } : d));
    } catch (error) {
      console.error("Error verifying doctor: ", error);
    }
  };

  if (loading) {
    return <p>Loading doctors...</p>;
  }

  return (
    <div className="verification-container">
      <h2>Doctor Verification Requests</h2>
      <table className="doctors-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {doctors.map(doctor => (
            <tr key={doctor.id}>
              <td>{doctor.name}</td>
              <td>{doctor.email}</td>
              <td>
                <span className={doctor.isVerified ? 'status-verified' : 'status-pending'}>
                  {doctor.isVerified ? 'Verified' : 'Pending'}
                </span>
              </td>
              <td>
                {!doctor.isVerified && (
                  <button onClick={() => handleVerify(doctor.id)} className="verify-button">
                    Verify
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default DoctorVerification;

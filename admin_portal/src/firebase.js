import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

// Your web app's Firebase configuration, copied from the mobile app
const firebaseConfig = {
  apiKey: "AIzaSyBKuTg8DdHM98K_94xYE1oONEVGcZ6tJOU",
  authDomain: "d-for-doctors-app.firebaseapp.com",
  projectId: "d-for-doctors-app",
  storageBucket: "d-for-doctors-app.firebasestorage.app",
  messagingSenderId: "361698807507",
  appId: "1:361698807507:web:c1d091455ed354c4f7ce26"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { db };

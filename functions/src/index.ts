import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import fetch from "node-fetch";

admin.initializeApp();

export const sendEmergencyPing = functions.https.onCall(async (request) => {
  const { type, latitude, longitude } = request.data || {};
  console.log("sendEmergencyPing invoked with data: ", request.data);

  if (!type || !latitude || !longitude) {
    console.error("Missing required parameters in request data.", { data: request.data });
    throw new functions.https.HttpsError("invalid-argument", "Missing required parameters.");
  }

  // 1. Create the live SOS session
  const newSession = await admin.firestore().collection("sos_sessions").add({
    type,
    latitude,
    longitude,
    isActive: true,
    startedAt: FieldValue.serverTimestamp(),
  });

  console.log(`Created new SOS session with ID: ${newSession.id}`);

  const googleApiKey = process.env.GOOGLE_MAPS_API_KEY;
  let nearbyPlaces: any[] = [];

  if (googleApiKey) {
    console.log("Google Maps API key found. Searching for nearby places.");
    const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latitude},${longitude}&radius=5000&type=${type.toLowerCase()}&key=${googleApiKey}`;
    const response = await fetch(url);
    const json = (await response.json()) as { results?: any[], status: string, error_message?: string };

    if (json.status !== "OK") {
      console.error("Google Places API error:", json.error_message || json.status);
    } else {
      nearbyPlaces = json.results || [];
    }
  } else {
    console.log("Google Maps API key not found. Skipping nearby search.");
  }

  // Log the ping to Firestore (we still only log the *nearest* one to keep logs concise)
  await admin.firestore().collection("sos_logs").add({
    type,
    sessionId: newSession.id, // Link the log to the session
    latitude,
    longitude,
    timestamp: FieldValue.serverTimestamp(),
    nearest: nearbyPlaces[0] || null,
  });

  console.log(`sendEmergencyPing finished for ${type}, found ${nearbyPlaces.length} places.`);
  
  // Return the session ID to the app
  return { success: true, nearbyPlaces: nearbyPlaces, sessionId: newSession.id, message: `Ping sent for ${type}` };
});


export const pingEmergencyContacts = functions.https.onCall(async (request) => {
  console.log("pingEmergencyContacts invoked");

  const contactsSnapshot = await admin.firestore().collection("emergency_contacts").get();

  if (contactsSnapshot.empty) {
    console.log("No emergency contacts found.");
    return { success: false, message: "No emergency contacts found." };
  }

  const contacts = contactsSnapshot.docs.map(doc => doc.data());
  
  const pings = contacts.map(contact => {
    console.log(`Creating ping for contact: ${contact.name} at ${contact.phone}`);
    return admin.firestore().collection("pings").add({
        contactName: contact.name,
        contactPhone: contact.phone,
        message: "Emergency SOS triggered! Please contact immediately!",
        receivedAt: FieldValue.serverTimestamp(),
    });
  });

  await Promise.all(pings);

  console.log(`Successfully created ${pings.length} pings in Firestore.`);
  return { success: true, message: `Successfully pinged ${pings.length} contacts.` };
});

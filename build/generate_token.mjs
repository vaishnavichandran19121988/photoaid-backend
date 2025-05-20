import { GoogleAuth } from 'google-auth-library';
import { writeFileSync } from 'fs';

const auth = new GoogleAuth({
  keyFile: './secrets/service_account.json',
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
});

const accessToken = await auth.getAccessToken();

// This is a string, not an object
writeFileSync('./secrets/fcm_token.txt', accessToken);
console.log('✅ Token saved to secrets/fcm_token.txt');

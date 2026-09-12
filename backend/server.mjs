import { createHash, randomInt, randomUUID, timingSafeEqual } from 'node:crypto';
import { createServer } from 'node:http';

const port = Number(process.env.PORT || 8080);
const pepper = process.env.OTP_PEPPER;
const codeLifetimeMs = 10 * 60 * 1000;
const resendDelayMs = 60 * 1000;
const challenges = new Map();
const lastSentAt = new Map();

if (!pepper || pepper.length < 24) {
  throw new Error('OTP_PEPPER must contain at least 24 characters.');
}

function json(response, status, body) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type',
    'access-control-allow-methods': 'POST, OPTIONS',
  });
  response.end(JSON.stringify(body));
}

async function readJson(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 16_384) throw new Error('Request is too large.');
  }
  return JSON.parse(body || '{}');
}

function codeHash(challengeId, code) {
  return createHash('sha256')
    .update(`${challengeId}:${code}:${pepper}`)
    .digest();
}

function normalizeDestination(channel, value) {
  const destination = String(value || '').trim();
  if (channel === 'email' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(destination)) {
    return destination.toLowerCase();
  }
  if (channel === 'sms' && /^\+601\d{8,9}$/.test(destination)) {
    return destination;
  }
  return null;
}

function mask(channel, destination) {
  if (channel === 'email') {
    const [local, domain] = destination.split('@');
    return `${local[0]}***@${domain}`;
  }
  return `*** *** ${destination.slice(-4)}`;
}

async function sendEmail(destination, code) {
  const apiKey = process.env.SENDGRID_API_KEY;
  const from = process.env.EMAIL_FROM;
  if (!apiKey || !from) throw new Error('Email delivery is not configured.');
  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: destination }] }],
      from: { email: from, name: process.env.EMAIL_FROM_NAME || 'Sweet Studio' },
      subject: 'Your Sweet Studio verification code',
      content: [{
        type: 'text/plain',
        value: `Your Sweet Studio verification code is ${code}. It expires in 10 minutes. If you did not request it, ignore this message.`,
      }],
    }),
  });
  if (!response.ok) throw new Error(`Email provider returned ${response.status}.`);
}

async function sendSms(destination, code) {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_PHONE_NUMBER;
  if (!sid || !token || !from) throw new Error('SMS delivery is not configured.');
  const form = new URLSearchParams({
    To: destination,
    From: from,
    Body: `Sweet Studio verification code: ${code}. Expires in 10 minutes.`,
  });
  const response = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(sid)}/Messages.json`,
    {
      method: 'POST',
      headers: {
        authorization: `Basic ${Buffer.from(`${sid}:${token}`).toString('base64')}`,
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: form,
    },
  );
  if (!response.ok) throw new Error(`SMS provider returned ${response.status}.`);
}

async function sendCode(request, response) {
  const body = await readJson(request);
  const channel = body.channel === 'sms' ? 'sms' : body.channel === 'email' ? 'email' : null;
  const purpose = ['registration', 'passwordReset'].includes(body.purpose)
    ? body.purpose
    : null;
  const destination = channel ? normalizeDestination(channel, body.destination) : null;
  if (!channel || !purpose || !destination) {
    return json(response, 400, { error: 'Invalid verification request.' });
  }
  const rateKey = `${channel}:${destination}`;
  const previous = lastSentAt.get(rateKey) || 0;
  if (Date.now() - previous < resendDelayMs) {
    return json(response, 429, { error: 'Wait before requesting another code.' });
  }
  const challengeId = randomUUID();
  const code = randomInt(100000, 1000000).toString();
  if (channel === 'email') await sendEmail(destination, code);
  else await sendSms(destination, code);
  challenges.set(challengeId, {
    hash: codeHash(challengeId, code),
    expiresAt: Date.now() + codeLifetimeMs,
    attempts: 0,
  });
  lastSentAt.set(rateKey, Date.now());
  return json(response, 200, {
    challengeId,
    maskedDestination: mask(channel, destination),
  });
}

async function verifyCode(request, response) {
  const body = await readJson(request);
  const challengeId = String(body.challengeId || '');
  const code = String(body.code || '');
  const challenge = challenges.get(challengeId);
  if (!challenge || challenge.expiresAt < Date.now() || challenge.attempts >= 5) {
    challenges.delete(challengeId);
    return json(response, 200, { verified: false });
  }
  challenge.attempts += 1;
  const supplied = codeHash(challengeId, code);
  const verified = supplied.length === challenge.hash.length &&
    timingSafeEqual(supplied, challenge.hash);
  if (verified) challenges.delete(challengeId);
  return json(response, 200, { verified });
}

const server = createServer(async (request, response) => {
  if (request.method === 'OPTIONS') return json(response, 204, {});
  try {
    if (request.method === 'GET' && request.url === '/health') {
      return json(response, 200, { status: 'ok' });
    }
    if (request.method === 'POST' && request.url === '/auth/send-code') {
      return await sendCode(request, response);
    }
    if (request.method === 'POST' && request.url === '/auth/verify-code') {
      return await verifyCode(request, response);
    }
    return json(response, 404, { error: 'Not found.' });
  } catch (error) {
    console.error(error instanceof Error ? error.message : error);
    return json(response, 500, { error: 'Verification service is unavailable.' });
  }
});

setInterval(() => {
  const now = Date.now();
  for (const [id, challenge] of challenges) {
    if (challenge.expiresAt < now) challenges.delete(id);
  }
  for (const [key, sentAt] of lastSentAt) {
    if (now - sentAt > codeLifetimeMs) lastSentAt.delete(key);
  }
}, 60_000).unref();

server.listen(port, () => {
  console.log(`Verification service listening on port ${port}.`);
});
